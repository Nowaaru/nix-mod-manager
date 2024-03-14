{pkgs}:
pkgs.lib.attrsets.foldlAttrs (
  acc: k: v:
    if (k != "default.nix" && v != "directory")
    then acc ++ [(import (./. + "/${k}") {inherit pkgs;})]
    else acc
) [] (builtins.readDir ./.)
