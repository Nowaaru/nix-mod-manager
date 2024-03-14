{pkgs ? import <nixpkgs> {}}: let
  inherit (pkgs) lib;
  inherit (import ../lib {inherit pkgs;}) fetchers;
in
  with lib.debug;
    fetchers.fetchGameBanana {
      modId = 500153;
      downloadId = 1153304;
    }
