{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps on Wayland
    UWSM_SILENT_START = "1";  # No black screen after log in
  };
  environment.systemPackages = [ pkgs.kitty ];
}
