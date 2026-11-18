{ pkgs, ... }:
{
  # nixpkgs whose CUDA builds target the 5090 (sm_120) only, which keeps local CUDA compiles short.
  # CUDA stays opt-in per package (`cudaSupport = true`), not on for the whole set (pkgsForCudaArch does that).
  _module.args.pkgs5090 = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config = {
      allowUnfree = true; # CUDA, OptiX
      cudaCapabilities = [ "12.0" ];
    };
  };

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
