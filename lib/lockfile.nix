pkgs: let
  inherit (pkgs) lib;
in {
  withLockfile = path: let
    lockfile-attrs = builtins.fromJSON (builtins.readFile path);
    out = {
      fetchMod = {
        providerId,
        gameId,
        modId,
        fileId,
      }:
        lockfile-attrs.${providerId}.${gameId}.${modId}.${fileId};
    };
  in
    out
    // {
      fromProvider = providerId: lib.attrsets.mapAttrs (_: v: v providerId) out;
    };
}
