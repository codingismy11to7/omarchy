_: {
  services.hyprsunset = {
    enable = true;
    settings = { };
  };

  xdg.configFile."hypr/hyprsunset.conf".source = ../../../config/hypr/hyprsunset.conf;
}
