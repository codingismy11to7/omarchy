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

  extensionFlags = "--load-extension=${copyUrlExtension}";

  wrapBrowser = browser: browser.override { commandLineArgs = extensionFlags; };
in
{
  config = lib.mkIf cfg.enable {
    omarchy.browser = {
      inherit copyUrlExtension;
      wrapWithExtension = wrapBrowser;
      brave = wrapBrowser p.brave;
      chromium = wrapBrowser p.chromium;
      google-chrome = wrapBrowser p.google-chrome;
    };
  };
}
