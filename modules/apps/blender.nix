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

  # Blender Lab's MCP server (https://www.blender.org/lab/mcp-server/), server and add-on from one pinned source.
  # Upstream launches it with `uv run`, which resolves dependencies from PyPI on every start.
  mcpSrc = pkgs.fetchgit {
    url = "https://projects.blender.org/lab/blender_mcp.git";
    rev = "2cea8d566dde07fbac28a61d698909d69724e853"; # v1.0.3
    hash = "sha256-pYeByO4Oi5eyynsJhGVd1vBWXHvhGn+Y5LGit6Kazlw=";
  };

  blender-mcp = pkgs.python3Packages.buildPythonApplication {
    pname = "blender-mcp";
    version = "1.0.3";
    src = mcpSrc;
    sourceRoot = "${mcpSrc.name}/mcp";
    pyproject = true;
    build-system = [ pkgs.python3Packages.setuptools ];
    # Pins mcp<2; nixpkgs' `mcp` is 2.x.
    dependencies = with pkgs.python3Packages; [ docutils pyyaml mcp_1 ] ++ mcp_1.optional-dependencies.cli;
    pythonImportsCheck = [ "blmcp" ];
  };

  # The add-on runs any Python it's sent over localhost:9876, with no auth. Leave its auto-start off.
  mcpAddon = pkgs.runCommand "blender-mcp-addon-1.0.3" { } ''
    mkdir -p $out/system
    cp -r ${mcpSrc}/addon/blender_mcp_addon $out/system/mcp
  '';
in
{
  environment.systemPackages = [
    # Shows up under Preferences → Add-ons as a System extension; enable it once there.
    (pkgs.symlinkJoin {
      name = "${blender.name}-with-mcp";
      paths = [ blender ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/blender --set BLENDER_SYSTEM_EXTENSIONS ${mcpAddon}";
    })
    blender-mcp
  ];
}
