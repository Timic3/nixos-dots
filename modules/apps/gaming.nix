{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  users.users.timic.extraGroups = [ "gamemode" ];  # Lets gamemode change CPU governor without a password

  environment.systemPackages = [
    pkgs.mangohud
    # Proton-GE outside Steam, in a bubblewrap sandbox (Steam's own FHS sandbox exposes all of $HOME)
    (pkgs.writeShellApplication {
      name = "sandbox-game";
      runtimeInputs = [ pkgs.bubblewrap ];
      runtimeEnv = {
        PROTONPATH = "${pkgs.proton-ge-bin.steamcompattool}";
        UMU_RUN = "${pkgs.umu-launcher}/bin/umu-run";
      };
      text = builtins.readFile ../../scripts/gaming/sandbox-game.sh;
    })
  ];
}
