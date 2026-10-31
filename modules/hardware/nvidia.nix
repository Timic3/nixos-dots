{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
  };

  # Turn off the CPU's built-in graphics, monitor is on the 5090.
  # boot.kernelParams = [ "module_blacklist=amdgpu" ];
}
