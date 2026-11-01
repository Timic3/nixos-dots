{ config, inputs, pkgs, ... }:
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

    plugins.aiOverviewControl.src = inputs.ai-overview-control;
  };

  # Required by the AiOverviewControl provider scripts
  environment.systemPackages = [ pkgs.jq ];

  sops.secrets.openrouter-api-key = { };
  sops.templates."aioc.env" = {
    content = "OPENROUTER_API_KEY=${config.sops.placeholder.openrouter-api-key}\n";
    owner = "timic";
  };

  # Drop-in so it applies to whichever dms.service is active; "-" keeps the shell starting without the secret
  home-manager.sharedModules = [{
    xdg.configFile."systemd/user/dms.service.d/secrets.conf".text = ''
      [Service]
      EnvironmentFile=-${config.sops.templates."aioc.env".path}
    '';
  }];
}
