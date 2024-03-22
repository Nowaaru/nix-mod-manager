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

    st = w: builtins.trace w w;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      inputsFrom = [];

      shellHook = ''
        export DEBUG=1
      '';
    };

    lib = pkgs.lib.extend (_: prev: {
      nnmm = import ./lib {inherit pkgs;};
    });

    homeManagerModules.default = args: import ./. (args // {inherit pkgs home-manager;});
  };
}
