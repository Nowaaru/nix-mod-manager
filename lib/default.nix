pkgs: let
  inherit (pkgs) lib;
  recursiveApply = with lib.attrsets;
    what: to:
      foldlAttrs (acc: k: v: acc // (lib.attrsets.setAttrByPath [k] (v what))) {} to;
in
  recursiveApply lib {
    providers = import ./providers;
    dag = import ./dag.nix;
    mkLocalMod = import ./mklocalmod.nix pkgs.stdenv; # this guy's a little bit special
  }
