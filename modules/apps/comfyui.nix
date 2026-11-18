{ config, lib, pkgs, pkgs5090, ... }:
let
  homeAi = "${config.users.users.timic.home}/ai";
  homeModels = "${homeAi}/comfy/models";
  folders = [
    "checkpoints" "diffusion_models" "text_encoders" "vae" "loras" "upscale_models" "controlnet" "clip_vision"
    "embeddings" "configs" "style_models" "diffusers" "vae_approx" "gligen" "latent_upscale_models" "hypernetworks"
    "photomaker" "classifiers" "model_patches" "audio_encoders" "background_removal" "frame_interpolation"
    "geometry_estimation" "optical_flow" "detection"
  ];
  extraModelPaths = (pkgs.formats.yaml { }).generate "extra_model_paths.yaml" {
    home = { base_path = homeModels; } // lib.genAttrs folders lib.id;
  };

  # nixpkgs' torch is CPU-only. torch-bin is PyTorch's own CUDA 13 wheel: it supports the 5090 and is
  # downloaded instead of compiled. comfy-kitchen's CUDA kernels (NVFP4 matmul, int8 attention) compile
  # locally for sm_120. `self = python` makes withPackages use the swapped set.
  python = pkgs5090.python3.override {
    self = python;
    packageOverrides = _: super: {
      torch = super.torch-bin;
      torchvision = super.torchvision-bin;
      comfy-kitchen = (super.comfy-kitchen.override { cudaSupport = true; }).overridePythonAttrs (old: {
        env = (old.env or { }) // { COMFY_CUDA_ARCHS = "120f"; };
      });
    };
  };
in
{
  # http://127.0.0.1:8188. Runs as its own `comfyui` user in a systemd sandbox (no access to /home).
  services.comfyui = {
    enable = true;
    package = pkgs5090.comfyui.override { python3 = python; };
    extraArgs = [ "--extra-model-paths-config=${extraModelPaths}" ];
  };

  systemd.services.comfyui.serviceConfig.BindReadOnlyPaths = [ homeModels ];
  systemd.tmpfiles.settings."10-comfyui-models" =
    let dir = mode: { d = { user = "timic"; group = "users"; inherit mode; }; };
    in {
      # Parents too, or tmpfiles creates them as root. No mode: created 0755, then left as you set them.
      ${homeAi} = dir "-";
      "${homeAi}/comfy" = dir "-";
    } // lib.genAttrs ([ homeModels ] ++ map (f: "${homeModels}/${f}") folders) (_: dir "0755");

  # Start on demand (`sudo systemctl start comfyui`).
  systemd.services.comfyui.wantedBy = lib.mkForce [ ];
}
