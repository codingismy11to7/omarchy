{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  p = cfg._packages;

  copyUrlExtension = pkgs.runCommand "copy-url-extension" { } ''
    mkdir -p $out
    cp ${../../../default/chromium/extensions/copy-url/background.js} $out/background.js
    cp ${../../../default/chromium/extensions/copy-url/manifest.json} $out/manifest.json
    cp ${../../../icon.png} $out/icon.png
  '';

  # Edge ignores the BrowserThemeColor policy used to theme the other chromium
  # browsers ("Unknown policy"), so theme it with an unpacked theme extension
  edgeThemeExtension =
    let
      rgb = name: map lib.toInt (lib.splitString "," cfg.palette."${name}_rgb");
    in
    pkgs.writeTextDir "manifest.json" (toJSON {
      manifest_version = 3;
      name = "Omarchy Theme";
      version = "1.0";
      theme.colors = {
        frame = rgb "background";
        frame_inactive = rgb "background";
        background_tab = rgb "background";
        toolbar = rgb "color0";
        toolbar_text = rgb "foreground";
        toolbar_button_icon = rgb "foreground";
        tab_text = rgb "foreground";
        tab_background_text = rgb "color7";
        bookmark_text = rgb "foreground";
        omnibox_background = rgb "background";
        omnibox_text = rgb "foreground";
        ntp_background = rgb "background";
        ntp_text = rgb "foreground";
      };
    });

  extensionsFor =
    browser:
    [ copyUrlExtension ] ++ lib.optional (browser.pname or "" == "microsoft-edge") edgeThemeExtension;

  wrapBrowser =
    browser:
    browser.override {
      commandLineArgs = "--load-extension=${lib.concatStringsSep "," (extensionsFor browser)}";
    };
in
{
  config = lib.mkIf cfg.hyprland.enable {
    omarchy.browser = {
      inherit copyUrlExtension;
      wrapWithExtension = wrapBrowser;
      brave = wrapBrowser p.brave;
      chromium = wrapBrowser p.chromium;
      google-chrome = wrapBrowser p.google-chrome;
      microsoft-edge = wrapBrowser p.microsoft-edge;
    };
  };
}
