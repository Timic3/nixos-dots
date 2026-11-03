{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./modules/hardware/nvidia.nix
    ./modules/hardware/audio.nix
    ./modules/hardware/bluetooth.nix
    ./modules/hardware/cpu.nix

    ./modules/boot/secure-boot.nix
    # ./modules/boot/splash.nix

    ./modules/desktop/hyprland.nix
    ./modules/desktop/dux-shell.nix
    ./modules/desktop/dux-greeter.nix

    ./modules/system/home-manager.nix
    ./modules/system/fonts.nix
    ./modules/system/secrets.nix
    ./modules/system/wireguard.nix

    ./modules/apps/discord.nix
    ./modules/apps/spotify.nix
    ./modules/apps/browser.nix
    ./modules/apps/ai.nix
    ./modules/apps/vscode.nix
    ./modules/apps/gaming.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  hardware.enableRedistributableFirmware = true;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Ljubljana";
  time.hardwareClockInLocalTime = true;

  console.keyMap = "slovene";

  users.users.timic = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion
  system.stateVersion = "26.05";
}
