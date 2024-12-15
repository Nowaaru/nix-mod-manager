pkgs: let
  inherit (pkgs) lib;
  recursiveApply = with lib.attrsets;
    what: to:
      foldlAttrs (acc: k: v: acc // (lib.attrsets.setAttrByPath [k] (v what))) {} to;
in
  recursiveApply lib {
    providers = import ./providers;
    fetchers = import ./fetchers.nix;
    mkLocalMod = _: (import ./mklocalmod.nix pkgs.stdenv);
  }
