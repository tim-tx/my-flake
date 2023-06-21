{

  description = "A few packages and modules not in nixpkgs";

  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }: {
    packages."x86_64-linux" = let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in {
      notbit    = pkgs.callPackage ./pkgs/notbit    { };
      simplexmq = pkgs.callPackage ./pkgs/simplexmq { };
      strfry    = pkgs.callPackage ./pkgs/strfry    { };
    };
  };

}
