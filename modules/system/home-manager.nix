{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";  # Rename clashing files instead of failing
    extraSpecialArgs = { inherit inputs; };
    users.timic = import ../../home/timic.nix;
  };
}
