lib: let
  inherit (lib) types;

  contains = attrs: what:
    builtins.map (x: attrs ? x) what;

in
  with types; {
    client = mkOptionType {
      name = "client";
      check = what: builtins.isAttrs what && builtins.all (contains what ["enable" "deploymentType" "rootPath" "modsPath" "binaryPath" "mods" "binaryMods"]);
      descriptionClass = "noun";
      description = "client";
    };

    mod = mkOptionType {
      name = "mod";
      check = _: true;
      descriptionClass = "noun";
      description = "mod";
    };
  }
