pkgs: let
  inherit (pkgs) lib;
in
  with lib.attrsets;
    foldlAttrs (
      a: k: v:
        a // {${lib.strings.removeSuffix ".nix" k} = import (./. + "/${k}") pkgs;}
    ) {}
    (filterAttrs
      (n: v: v == "regular" && n != "default.nix" && (lib.strings.hasSuffix ".nix" n))
      (builtins.readDir ./.))

