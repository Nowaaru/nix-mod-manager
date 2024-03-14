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
  fetchGameBanana = { downloadId, ... }:
    with lib;
      if
        true
        # (asserts.assertMsg (valuesExist ["modId" "downloadId"] traits) "all '...Id' fields are required") &&
        # (asserts.assertMsg (areListValues builtins.isInt) [traits.modId traits.downloadId] "all '...Id' fields need to be an integer")
      then
        pkgs.fetchurl {
          # url = "https://gamebanana.com/mods/download/${builtins.toString traits.modId}#FileInfo_${builtins.toString traits.downloadId}";
          url = "https://gamebanana.com/dl/${builtins.toString downloadId}";
          hash = "sha256-EE5UgIX11w3uenbENh26LDTMQP5uOgTGQkbDMZFE8eo=";
        }
      else {};
}
