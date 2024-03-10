{
  description = "Nix Mod Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    noire-utils.url = "path:/home/noire/Documents/nix-flakes/noire-utils";
  };

  outputs = {
    self,
    nixpkgs,
    noire-utils,
  }: {
    # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    #
    # packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    nixosModules.default = import ./. { inherit nixpkgs noire-utils; };
  };
}
