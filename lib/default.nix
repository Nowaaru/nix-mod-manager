{ nixpkgs }: 

let
  inherit (nixpkgs) lib;

  recursiveApply = with lib.attrsets; what: to: 
     foldl' (acc: k: v: acc[k]  (v what)) {} to;
in recursiveApply {
  fetchers = import ./fetchers.nix;
} lib
