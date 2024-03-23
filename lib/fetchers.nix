{pkgs}: let
  /*
     TODO: replace type check with
  a dynamic alternative that takes in an example
  (noire-utils)
  */
  inherit (pkgs) lib;
  st = w: builtins.trace w w;
in rec {
  /*
  TODO: make a fetchMod function that uses
  the `pkgs.file` package to check the file
  type and decompress accordingly.
  */

  /*
  TODO: have fetchGameBanana utilize the fetchMod
  function
  */
  fetchMod = {
    name ? "${lib.strings.nameFromURL url}",
    url,
    hash ? lib.fakeHash,
  }:
    with pkgs.stdenv;
      mkDerivation {
        inherit name;

        src = builtins.fetchurl {
          inherit name url;
          sha256 = hash;
        };

        unpackPhase = ''true'';

        installPhase = ''
          cp $src $out;
          sync;
        '';
      };

  fetchGameBanana = {
    name,
    hash ? lib.fakeHash,
  }:
    fetchMod {
      inherit name hash;
      url = "https://files.gamebanana.com/mods/${name}";
    };
  # pkgs.fetchurl {
  #   # url = "https://gamebanana.com/mods/download/${builtins.toString traits.modId}#FileInfo_${builtins.toString traits.downloadId}";
  #   url = "https://gamebanana.com/dl/${builtins.toString downloadId}";
  #   hash = "sha256-EE5UgIX11w3uenbENh26LDTMQP5uOgTGQkbDMZFE8eo=";
  #   curlOptsList = [''-H "Accept: application/json"''];
  # }
}
