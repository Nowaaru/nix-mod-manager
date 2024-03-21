{
  lib,
  home-manager,
  config,
  ...
}:
with lib; let
  inherit (home-manager.lib.hm) dag;
  inherit (import ./types.nix lib) mod;
  inherit (lib) options;
  cfg = config.programs.nix-mod-manager;
in {
  imports = [];

  options.programs.nix-mod-manager = with options; {
    enable = mkEnableOption "nix-mod-manager";
    clients = mkOption {
      default = {};
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
              type = home-manager.lib.hm.types.dagOf mod;
            };
          };
        };
      in
        attrsOf submodule-type;
    };
  };

  /*
  TODO: make derivation for every client that copies the mods into the modspath folder
  FIXME: my laziness
  */
  config = let
    inherit (cfg) clients;
    # clients-to-deploy =
    #   attrsets.foldlAttrs
    #   (acc: k: v: let
    #     sorted = dag.topoSort v.mods;
    #     isSorted = sorted ? "result";
    #   in
    #     acc
    #     // {
    #       ${k} =
    #         if isSorted
    #         then sorted.result
    #         else abort "mods were not sorted; possible circular dependency loop?";
    #     }) {}
    #   clients;
    # attrsets.foldlAttrs (acc: k: v: acc ++ "echo ${st k} - ${lists.foldl' (acc: v: "${acc}${v.data}\n") "" (st v)}\n") "" clients-to-deploy;
  in
    mkIf cfg.enable {
      home.activation = {
        nix-mod-manager-deploy = dag.entryAnywhere ''
          echo "Noire's Nix Mod Manager has started deploying."
          echo ${builtins.typeOf (dag.entryAnywhere "lol ok").data}
          echo ${builtins.typeOf clients.monster-hunter-world.mods}
        '';
        nix-mod-manager-cleanup = dag.entryAfter ["nix-mod-manager-deploy"] ''
          echo "Noire's Nix Mod Manager has finished deploying."
        '';
      };
    };
}
