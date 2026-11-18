{ config, ... }:
let
  dfiles = config.programs.dux-files.package;
in
{
  programs.dux-files = {
    enable = true;
    portal.enable = true;  # Registers the dfiles FileChooser backend
  };

  # Kept running hidden, so windows open instantly.
  systemd.packages = [ dfiles ];
  systemd.user.services.dfiles = {
    wantedBy = [ "graphical-session.target" ];
    enableDefaultPath = false;  # Keep the session PATH from UWSM, so apps it opens are found
  };

  # Open/save dialogs in every app go through dfiles.
  xdg.portal.config.hyprland = {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "dfiles" "gtk" ];
  };

  services.udisks2.enable = true;  # Devices sidebar: mount, unmount, eject
  services.gvfs.enable = true;  # Network shares (sftp, smb, ...) and the trash on removable drives

  # Folders from other apps open here. FileManager1 ("show in folder") it claims on its own.
  home-manager.sharedModules = [{
    xdg.mimeApps.defaultApplications."inode/directory" = "dev.duxlabs.files.desktop";
  }];
}
