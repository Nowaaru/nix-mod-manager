pkgs: lib:
with lib;
  attrsets.foldlAttrs (
    a: k: _:
      a // {${strings.removeSuffix ".nix" k} = import (./. + "/${k}") lib;}
  ) {
  }
  (attrsets.filterAttrs
    (n: v: v == "regular" && n != "default.nix" && (strings.hasSuffix ".nix" n))
    (builtins.readDir ./.))
