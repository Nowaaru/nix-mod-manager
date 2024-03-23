{
  description = "Noire's Nix Mod Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    noire-utils.url = "path:/home/noire/Documents/nix-flakes/noire-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    rust-overlay,
    ...
  } @ inputs: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
      };
      overlays = [rust-overlay.overlays.default];
    };

    mkLib = nixpkgs:
      nixpkgs.lib.extend
      (self: _: {nnmm = import ./lib {inherit pkgs; lib = self;};} // home-manager.lib);

  in rec {
    devShells.x86_64-linux.default = pkgs.mkShell {
      inputsFrom = [];

      shellHook = ''
        export DEBUG=1
      '';
    };

    lib = mkLib inputs.nixpkgs;

    homeManagerModules.default = args: import ./. (args // {inherit pkgs lib;});
  };
}
