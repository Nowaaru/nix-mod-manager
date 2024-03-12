{
  description = "Nix Mod Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    noire-utils.url = "path:/home/noire/Documents/nix-flakes/noire-utils";

    nixt = {
      url = "github:nix-community/nixt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    noire-utils,
    nixt,
    ...
  } @ inputs: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
  in {
    __nixt = nixt.lib.grow {
      blocks = [
        nixt.lib.block'
        ./flake.nix
        {
          "nixt"."passes this test" = true;
          "nixt"."fails this test" = false;
        }
      ];
    };

    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [nixt.packages.x86_64-linux.default];

      inputsFrom = [];

      shellHook = ''
        export DEBUG=1
      '';
    };
    nixosModules.default = import ./. {inherit pkgs;};
  };
}
