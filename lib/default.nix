{
  pkgs,
  lib,
}: let
  st = w: builtins.trace w w;
  recursiveApply = with lib.attrsets;
    what: to:
      foldlAttrs (acc: k: v: acc // lib.attrsets.setAttrByPath [(st k)] ((st v) what)) {} to;
in
  st (
    recursiveApply {inherit pkgs;} {
      fetchers = import ./fetchers.nix;
    }
  )
