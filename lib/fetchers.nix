{pkgs}: let
  /*
     TODO: replace type check with
  a dynamic alternative that takes in an example
  (noire-utils)
  */
  inherit (pkgs) lib;
  areListValues = qualifier: with lib.lists; all qualifier;
  valuesExist = keys:
    with lib.lists; all (i: builtins.hasAttr keys);
in {
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
    name ? "mod",
    url,
    hash ? lib.fakeHash,
  } @ mod-data:
    derivation
    {
      inherit name;
      system = builtins.currentSystem;

      outputs = ["out"];
    };

  fetchGameBanana = {downloadId, ...}:
    with lib;
      if true
      # (asserts.assertMsg (valuesExist ["modId" "downloadId"] traits) "all '...Id' fields are required") &&
      # (asserts.assertMsg (areListValues builtins.isInt) [traits.modId traits.downloadId] "all '...Id' fields need to be an integer")
      then
        with pkgs.stdenv;
          mkDerivation {
            # TODO:
            # curl this link and then read the output so i can get the mod file
            # and then fill it into files.gamebanana.com
            # "https://api.gamebanana.com/Core/Item/Data?itemtype=Mod&itemid=500113&fields=Files().aFiles()"
          }
          pkgs.fetchurl {
            # url = "https://gamebanana.com/mods/download/${builtins.toString traits.modId}#FileInfo_${builtins.toString traits.downloadId}";
            url = "https://gamebanana.com/dl/${builtins.toString downloadId}";
            hash = "sha256-EE5UgIX11w3uenbENh26LDTMQP5uOgTGQkbDMZFE8eo=";
            curlOptsList = [''-H "Accept: application/json"''];
          }
      else {};
}
