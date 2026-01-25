{
  config,
  lib,
  ...
}:
with builtins;
let
  cfg = config.omarchy;
  wcfg = cfg.webapps;
  inherit (lib) mkOption mkEnableOption types toLower mapAttrs' nameValuePair filterAttrs optionalString;

  makeDesktopFile =
    appName: appExec: iconPath: mimeTypes:
    ''
      [Desktop Entry]
      Version=1.0
      Name=${appName}
      Comment=Launch ${appName}
      Exec=${appExec}
      Terminal=false
      Type=Application
      Icon=${iconPath}
      StartupNotify=true
    ''
    + optionalString (mimeTypes != null) "MimeType=${mimeTypes}\n";

  desktopFile = appName: "${config.xdg.dataHome}/applications/${toLower appName}.desktop";

  makeLauncher = appName: appUrl: iconPath: mimeTypes:
    makeDesktopFile appName "omarchy-launch-webapp ${appUrl}" iconPath mimeTypes;

  makeSingleton = appName: appUrl: iconPath: mimeTypes:
    makeDesktopFile appName ''omarchy-launch-or-focus-webapp "${appName}" ${appUrl}'' iconPath mimeTypes;

  webappType = types.submodule {
    options = {
      url = mkOption {
        type = types.str;
        description = "URL to open for this webapp";
        example = "https://mail.google.com";
      };
      icon = mkOption {
        type = types.path;
        description = "Path to icon file (svg, png, etc.)";
      };
      singleton = mkOption {
        type = types.bool;
        default = true;
        description = "If true, reuse existing window. If false, always open new window.";
      };
      exec = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom Exec command. If null, uses standard webapp launcher.";
        example = "omarchy-webapp-handler-zoom %u";
      };
      mimeTypes = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "MIME types this webapp can handle (semicolon-separated).";
        example = "x-scheme-handler/zoommtg;x-scheme-handler/zoomus";
      };
    };
  };

  mkWebapp =
    {
      name,
      url,
      icon,
      singleton ? true,
      exec ? null,
      mimeTypes ? null,
      defaultEnabled ? true,
    }:
    {
      inherit name url singleton exec mimeTypes defaultEnabled;
      icon = path { path = ./icons/${icon}; };
    };

  builtinDefs = {
    basecamp = mkWebapp { name = "Basecamp"; url = "https://launchpad.37signals.com"; icon = "basecamp.svg"; };
    chatgpt = mkWebapp { name = "ChatGPT"; url = "https://chatgpt.com/"; icon = "chatgpt.svg"; singleton = false; };
    discord = mkWebapp { name = "Discord"; url = "https://discord.com/channels/@me"; icon = "discord.svg"; };
    figma = mkWebapp { name = "Figma"; url = "https://figma.com/"; icon = "figma.svg"; singleton = false; };
    fizzy = mkWebapp { name = "Fizzy"; url = "https://app.fizzy.do/"; icon = "fizzy.svg"; };
    github = mkWebapp { name = "GitHub"; url = "https://github.com/"; icon = "github.svg"; };
    gmail = mkWebapp {
      name = "Gmail";
      url = "https://mail.google.com";
      icon = "gmail.svg";
      exec = "omarchy-webapp-handler-gmail %u";
      mimeTypes = "x-scheme-handler/mailto";
    };
    google-calendar = mkWebapp { name = "Google Calendar"; url = "https://calendar.google.com"; icon = "google-calendar.svg"; };
    google-contacts = mkWebapp { name = "Google Contacts"; url = "https://contacts.google.com/"; icon = "google-contacts.svg"; };
    google-drive = mkWebapp { name = "Google Drive"; url = "https://drive.google.com"; icon = "google-drive.svg"; };
    google-gemini = mkWebapp { name = "Google Gemini"; url = "https://gemini.google.com/app"; icon = "google-gemini.svg"; singleton = false; };
    google-maps = mkWebapp { name = "Google Maps"; url = "https://maps.google.com"; icon = "google-maps.svg"; singleton = false; };
    google-messages = mkWebapp { name = "Google Messages"; url = "https://messages.google.com/web/conversations"; icon = "google-messages.svg"; };
    google-photos = mkWebapp { name = "Google Photos"; url = "https://photos.google.com/"; icon = "google-photos.svg"; };
    plex = mkWebapp { name = "Plex"; url = "https://app.plex.tv/desktop"; icon = "plex.svg"; defaultEnabled = false; };
    whatsapp = mkWebapp { name = "WhatsApp"; url = "https://web.whatsapp.com/"; icon = "whatsapp.svg"; };
    x = mkWebapp { name = "X"; url = "https://x.com/"; icon = "x.svg"; singleton = false; };
    youtube = mkWebapp { name = "YouTube"; url = "https://youtube.com/"; icon = "youtube.svg"; singleton = false; };
    zoom = mkWebapp {
      name = "Zoom";
      url = "https://app.zoom.us/wc/home";
      icon = "zoom.svg";
      exec = "omarchy-webapp-handler-zoom %u";
      mimeTypes = "x-scheme-handler/zoommtg;x-scheme-handler/zoomus";
    };
  };

  enabledBuiltins = filterAttrs (k: _: wcfg.${k}.enable) builtinDefs;

  builtinWebapps = mapAttrs' (
    _: def:
    nameValuePair def.name {
      url = def.url;
      icon = def.icon;
      singleton = def.singleton;
      exec = def.exec;
      mimeTypes = def.mimeTypes;
    }
  ) enabledBuiltins;

  allWebapps = builtinWebapps // wcfg.custom;

  webappFiles = mapAttrs' (
    name: webapp:
    nameValuePair (desktopFile name) {
      text =
        if webapp.exec != null then
          makeDesktopFile name webapp.exec webapp.icon webapp.mimeTypes
        else if webapp.singleton then
          makeSingleton name webapp.url webapp.icon webapp.mimeTypes
        else
          makeLauncher name webapp.url webapp.icon webapp.mimeTypes;
    }
  ) allWebapps;

  mkBuiltinOption = key: def:
    mkOption {
      type = types.submodule {
        options.enable = mkEnableOption "${def.name} webapp" // { default = def.defaultEnabled; };
      };
      default = { };
      description = "Enable the ${def.name} webapp launcher";
    };
in
{
  options.omarchy.webapps =
    (mapAttrs mkBuiltinOption builtinDefs)
    // {
      custom = mkOption {
        type = types.attrsOf webappType;
        default = { };
        description = "Custom web applications to create desktop launchers for";
        example = {
          Plex = {
            url = "https://app.plex.tv/desktop";
            icon = ./icons/plex.svg;
            singleton = true;
          };
        };
      };
    };

  config = lib.mkIf (cfg.enable && allWebapps != { }) {
    home.file = webappFiles;
  };
}
