{ pkgs }: let
  inherit (import ./lib) fetchers;
in
  with pkgs.lib; {
    imports = [];
    options = {
      clients =
        mkOption {
          type = with lib.types; listOf {
            enabled = bool;
            rootPath = uniq str;
            modsPath = uniq str;

            mods = with lib.hm.types; dagOf package;
          };
        };
    };

    config = {};
  }
