{
  pkgs,
  nixt,
}: let
  st = w: builtins.trace w w;
in
  with pkgs.lib.attrsets; (pkgs.lib.attrsets.foldlAttrs (
    acc: k: v:
      if (k != "default.nix" && v != "directory")
      then acc ++ [(import (./. + "/${k}") /* {inherit pkgs nixt;} */)]
      else acc
  ) [] (builtins.readDir ./.))
