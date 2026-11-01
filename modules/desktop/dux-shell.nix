{ config, inputs, pkgs, ... }:
let
  gpuMonitor = inputs.dux-plugin-gpu-monitor.packages.${pkgs.stdenv.hostPlatform.system};
in
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

    plugins.duxGpuMonitor.src =
      "${gpuMonitor.dux-plugin-gpu-monitor}/share/dms-plugins/duxGpuMonitor";
  };

  # jq is required by the AiOverviewControl provider scripts
  environment.systemPackages = [ pkgs.jq gpuMonitor.gpu-monitor ];

  # Per-pin readout: expose only the I2C adapter holding the GPU's monitor chip to the seated user.
  # hardware.i2c.enable would open every bus. Packaged rather than in services.udev.extraRules, which
  # sorts after 73-seat-late.rules, where the uaccess tag has to be seen.
  boot.kernelModules = [ "i2c-dev" ];
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-gpu-monitor-i2c.rules" ''
      KERNEL=="i2c-[0-9]*", SUBSYSTEM=="i2c-dev", ATTR{name}=="NVIDIA i2c adapter 1 at 1:00.0", TAG+="uaccess"
    '')
  ];

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

    # Without an icon theme, Dux falls back to letters for most app icons.
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };
  }];
}
