{
  pkgs,
  config,
  home-manager,
  ...
}: let
  inherit (import ./types.nix pkgs) mods;

  inherit (pkgs) lib;
  inherit (lib) options;

  st = w: builtins.trace w w;
  cfg = config.programs.nix-mod-manager;
in
  with lib; {
    imports = [];
    options = {
      programs = {
        nix-mod-manager = with options; {
          enable = mkEnableOption "nix-mod-manager";

          clients = mkOption {
            default = [];
            type = with types; let
              submodule-type = submodule {
                options = {
                  enable = mkEnableOption "the client";

                  rootPath = mkOption {
                    type = uniq str;
                  };

                  modsPath = mkOption {
                    type = uniq str;
                  };

                  mods = mkOption {
                    type = either (home-manager.lib.hm.types.dagOf mod) (listOf mod);
                  };
                };
              }; # comment because nix stack traces are fucking abysmal
            in
              either (attrsOf submodule-type) (listOf submodule-type);
          };
        };
      };
    };

    /*
    TODO: make derivation for every client that copies the mods into the modspath folder
    FIXME: my laziness
    */
    config = let
      inherit (cfg) clients;
      clients-to-deploy =
        attrsets.foldlAttrs
        (acc: k: v: let
          sorted = home-manager.lib.hm.dag.topoSort v.mods;
          isSorted = sorted ? "result";
        in
          acc
          // {
            ${k} =
              if isSorted
              then sorted.result
              else abort "mods were not sorted; possible circular dependency loop?";
          }) {}
        clients;
      # attrsets.foldlAttrs (acc: k: v: acc ++ "echo ${st k} - ${lists.foldl' (acc: v: "${acc}${v.data}\n") "" (st v)}\n") "" clients-to-deploy;
    in
      mkIf cfg.enable {
        home.activation = {
          nix-mod-manager-deploy = home-manager.lib.hm.dag.entryAnywhere ''
            echo "Noire's Nix Mod Manager has started deploying."
            echo ${builtins.typeOf (home-manager.lib.hm.dag.entryAnywhere "lol ok").data}
            echo data: ${builtins.typeOf (clients.monster-hunter-world.mods.test-mod-1).data}
          '';
          nix-mod-manager-cleanup = home-manager.lib.hm.dag.entryAfter ["nix-mod-manager-deploy"] ''
            echo "Noire's Nix Mod Manager has finished deploying."
          '';
        };
      };
  }
