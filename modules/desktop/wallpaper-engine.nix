{ config, inputs, ... }:
let
  home = config.users.users.timic.home;
in
{
  home-manager.sharedModules = [ inputs.wallpaper-engine.homeManagerModules.default ];

  home-manager.users.timic.services.wallpaper-engine = {
    enable = true;
    # NVIDIA only: keeps Mesa's EGL, and its 25 MB libLLVM, out of the daemon.
    environment.__EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";

    settings = {
      # DMS draws nothing with "Use external manager" on, but still takes its colours from the
      # wallpaper it is told about. Its own cycling has to stay off so the two don't disagree.
      on_change = [ "${config.programs.dank-material-shell.package}/bin/dms" "ipc" "call" "wallpaper" "set" "{path}" ];
      transition = {
        type = "fade";
        duration_ms = 1000;
      };

      wallpaper = [
        {
          fill = "span";
          playlist = {
            path = "${home}/pictures/wallpapers";
            order = "shuffle";
            interval = "5m";
          };
        }
      ];
    };
  };
}
