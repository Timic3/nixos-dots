{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  users.users.timic.extraGroups = [ "gamemode" ];  # Lets gamemode change CPU governor without a password

  environment.systemPackages = [ pkgs.mangohud ];
}
