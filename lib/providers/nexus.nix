lib:
with lib.nnmm; let
  stringify = builtins.toString;
in {
  mkApiPath = protocol: host: "${protocol}://${host}";

  mkNexus = providers.generic.mkProvider ({unpackSingularFolders ? false} @ layeredProviderArguments: {
    fetchNexus = game-domain-name: {
      name ? "nexus-mod-${stringify mod-id}-${stringify file-id}-${stringify hash}",
      hash ? lib.fakeHash,
      hash-type ? "md5",
      mod-id,
      file-id,
    }:
      mkRequest {
        inherit hash hash-type name;
        endpoint = "v1/games/${stringify game-domain-name}/mods/${stringify mod-id}/files/${stringify file-id}/download_link.json";
      };
  });
}
