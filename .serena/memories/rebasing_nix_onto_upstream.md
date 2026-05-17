# Rebasing nix onto upstream/master

The nix branch is a rebasing fork: ~27 commits on top of basecamp/omarchy master.
Each upstream release means rebasing those 27 commits over 600+ upstream commits.
This memory captures the lessons learned doing this — most painfully discovered
during a failed attempt on 2026-05-15, then completed successfully on 2026-05-17
against upstream's v3.8.1 (`82f99928`).

## The cardinal rule

**`git rebase upstream/master`, per-commit, with manual conflict resolution. No
squash, no rerere, no automated subs.**

The temptation to shortcut is strong because conflicts recur (the same file
shows up in multiple of our commits as we both edit it across versions). Resist.
Each recurrence is a *different commit's intent context*, which is exactly the
information needed to make a good per-file decision. Squashing destroys that.

## The silent-loss pattern (most important)

When upstream **renames or rewrites** a script our commits had `@placeholder@`-
substituted, git's rename detection lands our commits on the new file, but our
substitutions don't apply to upstream's new content. The downstream effect:

- The createScript declaration in `nix/modules/scripts/home.nix` says
  `inherit (exe) ffmpeg;` (we want `@ffmpeg@` substituted with a /nix/store path).
- The new file's body uses bare `ffmpeg`, no `@ffmpeg@` marker.
- `nix flake check` fails: "pattern @ffmpeg@ doesn't match anything in file".

The instinctive reaction is to **remove `ffmpeg` from the createScript args** to
silence the error. **That is wrong** — it silently drops the substitution. The
right fix is to **apply `@ffmpeg@` to upstream's bare invocation** in the new
file's body.

Caught examples from the 2026-05-17 attempt: `omarchy-capture-screenrecording`
(8 subs lost), `omarchy-system-lock` (2 subs lost). Detection happens only when
the build complains; if the file had no subs declared, the loss is silent.

After every rebase, audit by comparing sub counts:
```sh
for f in $(git show <our-commit> --name-only --pretty=""); do
  basename=$(basename "$f")
  target=...  # apply known rename mapping
  backup=$(git show "nix-backup-pre-rebase:$f" 2>/dev/null | grep -coE '@[A-Za-z_-][A-Za-z0-9_-]*@' | sort -u | wc -l)
  current=$(grep -coE '@[A-Za-z_-][A-Za-z0-9_-]*@' "$target" 2>/dev/null | sort -u | wc -l)
  [ "$backup" -gt "$current" ] && echo "REGRESSION: $basename $backup -> $current"
done
```

## False-positive substitutions (same discipline applies in reverse)

When using `derive_subs`-style automation (or even Claude pattern-matching),
substitutions get over-applied to:
- shebangs (`#!/bin/bash` → `#!/bin//nix/store/...` is bogus)
- URLs (`https://devhints.io/bash` → mangled)
- case labels (`case $x in slurp)` is a literal match, not a binary call)
- `pkill -x`/`pgrep -x` args (match against `/proc/PID/comm`, 15-char limit;
  full nix store paths don't match)
- `pkill -f`/`pgrep -f` args with `^` anchor (anchored regex won't match
  cmdlines that start with `/nix/store/...`; de-anchor or omit)
- string comparisons (`[[ $x == "satty" ]]`)
- comments

Only sub **bare command invocations**, never these contexts.

## Conflict-resolution principles

For every conflict, read three things first:

1. The commit being applied: `git show <our-commit> -- <file>` — what was our
   intent, and why?
2. Upstream's history: `git log <merge-base>..upstream/master -- <file>` — read
   the commit messages, not just titles.
3. The three stages: `git show :1:<file>` (base), `:2:<file>` (HEAD = upstream),
   `:3:<file>` (ours).

Then decide:
- Sometimes ours wins outright (waybar systemctl: confirmed)
- Sometimes upstream's rewrite is a strict improvement and we adapt our
  customization on top (e.g. extracted helpers like `omarchy-swayosd-client`)
- Sometimes the answer is a synthesis neither side anticipated
- Sometimes our commit's intent is no longer relevant (upstream already does it,
  or removed the thing we were customizing) — drop the hunk rather than
  force-fit. Confirm with the user.

`git checkout --ours <file>` during rebase = **upstream's version** (HEAD =
target). `--theirs` = our incoming commit. Easy to swap; double-check.

## Hyprland version compatibility (bites every release)

Upstream omarchy targets whatever hyprland Arch ships. When we rebase, we
inherit configs written for that hyprland version, which is often **older** than
nixpkgs-unstable. As of 2026-05-17:

- Arch ships hyprland 0.54.3 (March 27, 2026)
- nixpkgs-unstable was on 0.55.1 (May 13, 2026)
- 0.55.x **removed** `dwindle:pseudotile` and tightened the `col.border_locked_*`
  gradient parser

Result: our rebased `default/hypr/looknfeel.conf` triggered config errors at
runtime in hyprland 0.55.1. Fix: pin `nixpkgs-unstable` (in dotfiles, where
hyprland's package is sourced) to a commit whose hyprland matches Arch. Check
with `Hyprland --version` on an updated Arch machine, then:
```sh
nix eval --raw github:nixos/nixpkgs/<rev>#hyprland.version
```
Walk back unstable's lock until they match. Alternative: use the hyprwm/Hyprland
flake pinned to the matching tag.

## After conflict resolution: post-rebase audit

The rebase only fixes file-level conflicts. The following typically need
follow-up:

1. **`nix/modules/scripts/home.nix` createScript renames.** Upstream renames
   bin/* files; our home.nix references the old names. Common renames at v3.8.1:
   `omarchy-cmd-audio-switch` → `omarchy-audio-output-switch`,
   `omarchy-cmd-first-run` → `omarchy-first-run`,
   `omarchy-cmd-screenrecord` → `omarchy-capture-screenrecording`,
   `omarchy-cmd-screensaver` → `omarchy-screensaver`,
   `omarchy-cmd-screenshot` → `omarchy-capture-screenshot`,
   `omarchy-cmd-share` → `omarchy-menu-share`,
   `omarchy-lock-screen` → `omarchy-system-lock`.

2. **autostart.conf entries need home.nix wire-up.** Upstream's
   `default/hypr/autostart.conf` often adds `exec-once = omarchy-newscript`
   lines for new scripts. Resolving the conflict isn't enough — the script must
   be registered with `createScript` in `nix/modules/scripts/home.nix` or it
   won't be in PATH. Cross-check:
   ```sh
   for s in $(grep -oE 'omarchy-[a-z-]+' default/hypr/autostart.conf | sort -u); do
     grep -q "\"$s\"" nix/modules/scripts/home.nix || echo "MISSING: $s"
   done
   ```

3. **`config/hypr/hyprland.conf` toggles glob.** The line
   `source = ~/.local/state/omarchy/toggles/hypr/*.conf` errors at hyprland
   startup when the dir is empty. Wrap in `# hyprlang noerror true/false`
   directives. Upstream forgot this; we patch it.

4. **Deleted-upstream files.** Upstream may delete files our commits modified
   (e.g. `bin/omarchy-cmd-screenrecord` deleted in favor of the rename,
   `config/brave-flags.conf` deleted when brave stopped being default). These
   show as DU conflicts — `git rm` them and follow the rename to the new file.

5. **User-facing breaking changes to options.** Removing or renaming an
   `omarchy.*` option in this repo breaks user dotfiles that set it. Confirm
   removals with the user first. Example: `omarchy.screensaver.screenOffSeconds`
   was removed when upstream consolidated screen-off into `omarchy-system-lock`
   (hardcoded 3s after lock).

## VM smoke-testing workflow

The `nh os build/switch` cycle on a test VM is the only way to catch runtime
issues (hyprland version mismatch, missing scripts in PATH, etc).

Critical: when iterating with `path:` flake inputs and rsync, **always**
`nix flake update <input>` on the remote between rsync and rebuild. Otherwise
nix uses the cached NAR and your edits never apply. The `deploy-vm` skill
specifies this; easy to forget.

Activation needs sudo (`nh os switch` runs `switch-to-configuration`), which
can't read a password over non-interactive ssh. Either:
- User runs the switch in their own terminal (`ssh -t` allocates TTY)
- Or configure passwordless sudo on the test VM

VM disks fill up fast during iteration. If `/nix` hits 100%, even `nix-collect-
garbage` can't write its db updates ("disk I/O error"). Free a small amount of
space first (`journalctl --vacuum-size=10M`, clear `~/.cache`, `/tmp`) so GC can
make headway, then `sudo nix-collect-garbage -d`. Or grow the VM disk
(`virsh shutdown <vm>`, `qemu-img resize <disk>.qcow2 +10G`, then `parted /dev/
vda resizepart`, `cryptsetup resize`, `btrfs filesystem resize max /`).

## Disko config gotcha

The attribute name under `disko.devices.disk.<name>` becomes the GPT partition
label prefix. `disk.nixorge = { device = "/dev/vda"; ... }` produces
`disk-nixorge-ESP` and `disk-nixorge-luks`. If a VM was bootstrapped as one
host and you want to switch it to another, either:
- Rename partitions on the VM disk (`sfdisk --part-label /dev/vda 2
  disk-<name>-luks`), or
- Edit the host's disk-config.nix to use the existing partition naming

This came up testing the nix branch on a VM originally bootstrapped as
`omarchyvm` — `hosts/nixvm/disk-config.nix` had `disk.nixorge = ...` from a
copy-paste origin; update to match the actual VM's labels.

## Validation

```sh
nix flake check          # eval + small builds; catches most static errors
nh os build .#nixvm      # full VM-target build (from dotfiles, where nixvm is)
```

For UI/runtime verification: deploy to VM via the `deploy-vm` skill, then
`nh os switch` from inside the VM (sudo prompt requires TTY).

## Reference: setup

- Backup branch before rebasing: `git branch nix-backup-pre-rebase nix`
- Confirm rerere is OFF: `git config --get rerere.enabled` should be empty
- Clear stale rerere cache if any: `rm -rf .git/rr-cache`
- Use a worktree for the rebase: `EnterWorktree` or
  `git worktree add .claude/worktrees/rebase-<date>`
- After successful rebase + VM validation: update local `nix` ref via
  `git update-ref refs/heads/nix <new-tip>`, then force-push with
  `--force-with-lease`.
