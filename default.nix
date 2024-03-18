{
  pkgs,
  config,
  home-manager,
  ...
}: let
  inherit (pkgs) lib;
  inherit (lib) options;

  st = w: builtins.trace w w;
  cfg = config.programs.nix-mod-manager;
in
  with lib; {
    imports = [];
    options = {
      programs = {
        nix-mod-manager = with lib.options; {
          enable = mkOption {
            type = with lib.types; bool;
            default = false;
          };

          clients = mkOption {
            default = [];
            type = with lib.types;
              listOf {
                enabled = bool;
                rootPath = uniq str;
                modsPath = uniq str;

                mods = with lib.hm.types; dagOf package;
              };
          };
        };
      };
    };

    config = let
      sorted_mods = attrsets.foldlAttrs (acc: k: v: acc // {${k} = (home-manager.lib.hm.dag.topoSort v.mods).result;}) {} cfg.clients;
      mod_links = attrsets.foldlAttrs (acc: k: v: acc + "ln ${v.data} ${cfg.clients [k].modsPath}\n") [] sorted_mods;
      all_deploy = attrsets.foldlAttrs (_: _: v: acc + v) [] mod_links;
    in
      mkIf cfg.enable {
        home.activation = {
          nix-mod-manager-deploy = home-manager.lib.hm.dag.entryAnywhere ''
            echo "Noire's Nix Mod Manager has started deploying."
            ${all_deploy}
          '';
          nix-mod-manager-cleanup = home-manager.lib.hm.dag.entryAfter ["nix-mod-manager-deploy"] ''
            echo "Noire's Nix Mod Manager has finished deploying."
          '';
        };
        # systemd.services.nix-mod-manager = {
        #   wantedBy = ["multi-user.target"];
        #   serviceConfig = {
        #     Type = "notify";
        #     ExecStart = ''echo "Nix Mod Manager has started deploying."'';
        #     ExecStop = ''echo "Nix Mod Manager has finished running.'';
        #   };
        # };
      };
  }
