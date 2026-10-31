{ inputs, pkgs, ... }:
{
  services.displayManager.dux-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/timic";
    package = inputs.dux-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
