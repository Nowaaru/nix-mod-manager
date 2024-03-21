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

    homeManagerModules.default = args: import ./. (args // {inherit pkgs home-manager;});
  };
}
