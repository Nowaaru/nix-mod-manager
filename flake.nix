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
      overlays = [
        (
          new: old: {
            lib =
              # use old here because
              # new.lib will equal try to
              # extend itself again on access
              old.lib.extend
              (_: _:
                {
                  inherit (new) fetchurl;
                  nnmm = import ./lib new;
                }
                // home-manager.lib);
          }
        )
      ];
    };
  in rec {
    inherit (pkgs) lib;

    devShells.${system}.default = pkgs.mkShell {
      # inherit system;
      inputsFrom = [];

      shellHook = ''
        export DEBUG=1
      '';
    };

    homeManagerModules.default = args:
      import ./. (args
        // {
          inherit system pkgs lib;
        });
  };
}
