{
  pkgs,
  lib,
}: let
  st = w: builtins.trace w w;
  recursiveApply = with lib.attrsets;
    what: to:
      foldlAttrs (acc: k: v: acc // lib.attrsets.setAttrByPath [(st k)] ((st v) what)) {} to;
in
  recursiveApply pkgs {
    providers = import ./providers;
    fetchers = import ./fetchers.nix;
    mkLocalMod = import ./mklocalmod.nix;
  }
