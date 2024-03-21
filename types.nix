lib: let
  inherit (lib) types;
in
  with types; {
    client = mkOptionType {
      name = "client";
      check = what: (what ? "enable" && builtins.isBool what) && (what ? "rootPath" && builtins.isString what) && (what ? "modsPath" && builtins.isString "modsPath");
    };

    mod = mkOptionType {
      name = "mod";
    };
  }
