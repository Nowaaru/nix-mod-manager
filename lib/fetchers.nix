{lib}: let
  /*
     TODO: replace type check with
  a dynamic alternative that takes in an example
  (noire-utils)
  */
  areListValues = qualifier: with lib.lists; all qualifier;
  valuesExist = keys:
    with lib.lists; all (i: builtins.hasAttr keys);
in {
  fetchGameBanana = traits:
    with lib;
      lib.mkIf (asserts.assertMsg (valuesExist ["modId" "downloadId"] traits) "all '...Id' fields are required")
      lib.mkIf (asserts.assertMsg (areListValues builtins.isInt) [traits.modId traits.downloadId] "all '...Id' fields need to be an integer")
      fetchurl {
        url = "https://gamebanana.com/mods/download/${traits.modId}#FileInfo_${traits.downloadId}";
      };
}
