# Blender Lab's MCP server (https://www.blender.org/lab/mcp-server/), and its Blender add-on as `.addon`, from one pinned source.
# Upstream launches it with `uv run`, which resolves dependencies from PyPI on every start.
{ python3Packages, fetchgit, runCommand, nix-update-script }:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "blender-mcp";
  version = "1.0.3";

  # By tag so a version bump moves the source too; the hash still pins the content, so a moved tag fails the build.
  src = fetchgit {
    url = "https://projects.blender.org/lab/blender_mcp.git";
    tag = "v${finalAttrs.version}";
    hash = "sha256-pYeByO4Oi5eyynsJhGVd1vBWXHvhGn+Y5LGit6Kazlw=";
  };
  sourceRoot = "${finalAttrs.src.name}/mcp";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];
  # Pins mcp<2; nixpkgs' `mcp` is 2.x.
  dependencies = with python3Packages; [ docutils pyyaml mcp_1 ] ++ mcp_1.optional-dependencies.cli;
  pythonImportsCheck = [ "blmcp" ];

  passthru = {
    # The add-on runs any Python it's sent over localhost:9876, with no auth. Leave its auto-start off.
    addon = runCommand "blender-mcp-addon-${finalAttrs.version}" { } ''
      mkdir -p $out/system
      cp -r ${finalAttrs.src}/addon/blender_mcp_addon $out/system/mcp
    '';

    # An old date-style tag (26.04.10) sorts above the real releases
    updateScript = nix-update-script { extraArgs = [ "--version-regex" "v(.*)" ]; };
  };
})
