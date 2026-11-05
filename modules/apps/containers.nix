{ pkgs, ... }:
{
  # Rootless Podman only: no daemon, and nothing that turns a user-level compromise into root.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # `docker` is a symlink to podman
  };

  # GPU in containers: `docker run --device nvidia.com/gpu=all ...`
  hardware.nvidia-container-toolkit.enable = true;

  # `docker compose` runs `podman compose`, which hands off to the real Compose v2.
  environment.systemPackages = [ pkgs.docker-compose ];

  home-manager.users.timic = {
    # For tools that call the Docker API directly (Testcontainers, VS Code Dev Containers).
    home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
  };
}
