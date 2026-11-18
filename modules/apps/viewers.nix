{ lib, pkgs, ... }:
let
  # Canonical shared-mime-info names, the ones dfiles detects (.mkv is video/matroska, .wav is audio/vnd.wave)
  images = map (t: "image/${t}") [ "png" "jpeg" "gif" "webp" "avif" "heif" "jxl" "svg+xml" "bmp" "tiff" ];
  video = map (t: "video/${t}") [ "mp4" "matroska" "webm" "quicktime" "vnd.avi" "mpeg" "ogg" "mp2t" ];
  audio = map (t: "audio/${t}") [
    "mpeg" "flac" "ogg" "x-vorbis+ogg" "x-opus+ogg" "vnd.wave" "mp4" "aac" "matroska" "webm"
  ];
in
{
  environment.systemPackages = [
    pkgs.loupe  # Images
    pkgs.papers  # PDFs, djvu, comics
    pkgs.glycin-thumbnailer  # Thumbnails for avif, heif, jxl, svg, ... (dfiles only decodes the common formats itself)
  ];

  home-manager.sharedModules = [{
    programs.mpv = {
      enable = true;
      config.hwdec = "auto-safe";  # NVDEC; mpv decodes on the CPU by default
    };

    # Pinned rather than left to whatever claims the type: the browsers list pdf, png, jpeg, gif and webp too
    xdg.mimeApps.defaultApplications =
      lib.genAttrs images (_: "org.gnome.Loupe.desktop")
      // { "application/pdf" = "org.gnome.Papers.desktop"; }
      // lib.genAttrs (video ++ audio) (_: "mpv.desktop");
  }];
}
