{ pkgs }: let
  inherit (import ./lib) fetchers;
  inherit (pkgs) lib;
  inherit (lib) options;
in
  with lib; {
    imports = [];
    options = {
      clients =
        options.mkOption {
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
