{
  boot = {
    plymouth.enable = true;  # Boot splash instead of text

    # Silent boot
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
