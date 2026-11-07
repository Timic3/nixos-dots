{ pkgs, ... }:
let
  # nixpkgs' Blender has no CUDA, so Cycles can't use the GPU. Only the CUDA build has OptiX, and it isn't
  # in any binary cache, so it compiles locally after every nixpkgs bump. Building kernels for the 5090 (sm_120)
  # alone keeps that short. CUDA is turned on for Blender only, not the whole package set (pkgsForCudaArch does that).
  pkgs5090 = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config = {
      allowUnfree = true; # OptiX
      cudaCapabilities = [ "12.0" ];
    };
  };
  blender = pkgs5090.blender.override { cudaSupport = true; };
in
{
  environment.systemPackages = [
    # Shows up under Preferences → Add-ons as a System extension; enable it once there.
    (pkgs.symlinkJoin {
      name = "${blender.name}-with-mcp";
      paths = [ blender ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/blender --set BLENDER_SYSTEM_EXTENSIONS ${pkgs.blender-mcp.addon}";
    })
    pkgs.blender-mcp
  ];
}
