{ pkgs, pkgs5090, ... }:
let
  # nixpkgs' Blender has no CUDA, so Cycles can't use the GPU. Only the CUDA build has OptiX, and it isn't
  # in any binary cache, so it compiles locally after every nixpkgs bump (for the 5090 only, see nvidia.nix).
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
