{
  description = "Noire's Nix Mod Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    home-manager = {
      url = "github:nix-community/home-manager/master";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    mkLib = nixpkgs:
      nixpkgs.lib.extend
      (self: _:
        {
          nnmm = import ./lib {
            inherit pkgs;
            lib = self;
          };
        }
        // home-manager.lib);
  in rec {
    devShells.${system}.default = pkgs.mkShell {
      # inherit system;
      inputsFrom = [];

      shellHook = ''
        export DEBUG=1
      '';
    };

    lib = mkLib inputs.nixpkgs;

    homeManagerModules.default = args:
      import ./. (args
        // {
          inherit system pkgs lib;
        });
  };
}
