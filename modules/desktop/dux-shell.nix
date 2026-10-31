{ inputs, pkgs, ... }:
{
  imports = [ inputs.dux.nixosModules.dank-material-shell ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;

    plugins.dankbarPinentry.src =
      "${inputs.dank-pinentry.packages.${pkgs.stdenv.hostPlatform.system}.dank-pinentry-plugin}/share/dms-plugins/dankbarPinentry";
  };
}
