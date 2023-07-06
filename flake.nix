{

  description = "A few packages and modules not in nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
    in {
      notbit    = pkgs.callPackage ./pkgs/notbit    { };
      simplexmq = pkgs.callPackage ./pkgs/simplexmq { };
      strfry    = pkgs.callPackage ./pkgs/strfry    { };
    });
    nixosModules = {
      default = { config, ... }: {
        imports = [
          (import ./modules/dendrite.nix self)
          (import ./modules/i2pd.nix self)
          (import ./modules/simplexmq.nix self)
          (import ./modules/strfry.nix self)
        ];
      };
    };
  };

}
