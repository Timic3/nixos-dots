{
  description = "My NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux = {
      url = "github:duxlabs-dev/dux-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dank-pinentry = {
      url = "github:augustocdias/dank-pinentry/3316dd9de7e5423b4e3fe6d565564cfef4c5f6af";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-overview-control = {
      url = "github:bernardopg/AiOverviewControl/c78072470b04563d491b8083f45275478facbb12";  # v2.2.2
      flake = false;
    };
    dux-plugin-gpu-monitor = {
      url = "github:Timic3/dux-plugin-gpu-monitor";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/60182817ee048ac94b4c68ea76d5ef2e8aac730d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitalias = {
      url = "github:GitAlias/gitalias";
      flake = false;
    };
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
