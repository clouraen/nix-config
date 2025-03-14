{ config, pkgs, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = true;
    extraConfig = ''
      # Monitor config
      monitor=,preferred,auto,1

      # Execute at launch
      exec-once = waybar
      exec-once = dunst
      exec-once = nm-applet
    '';
  };
}
