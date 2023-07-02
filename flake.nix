{

  description = "A few packages and modules not in nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      notbit    = pkgs.callPackage ./pkgs/notbit    { };
      simplexmq = pkgs.callPackage ./pkgs/simplexmq { };
      strfry    = pkgs.callPackage ./pkgs/strfry    { };
    };
    nixosModules = {
      default = { config, ... }: {
        imports = [
          (import ./modules/i2pd.nix self)
          (import ./modules/simplexmq.nix self)
          (import ./modules/strfry.nix self)
        ];
      };
    };
  };

}
