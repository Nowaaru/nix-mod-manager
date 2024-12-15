lib: let
  inherit (lib.nnmm) providers;

  stringify = builtins.toString;

  requestProvider = providers.generic.mkRequestProvider {
    api-base-uri = "https://gamebanana.com/dl";
  };
in {
  mkGameBanana = providers.generic.mkProvider ({unpackSingularFolders ? false} @ layeredProviderArguments: {
    /*
    Fetch a mod from GameBanana.
    */

    fetchGameBanana = {
      name ? "gamebanana-mod-${stringify file-id}-${stringify hash}",
      hash ? lib.fakeHash,
      checksum ? lib.fakeHash,
      unpackPhase ? ''true'',
      file-id,
    }:
      lib.nnmm.mkLocalMod {
        inherit name unpackPhase;
        inherit unpackSingularFolders;

        store-path = requestProvider.mkRequest {
          name = "${name}-zip";
          hash-algo = "sha256";

          hash =
            if (hash == lib.fakeHash && checksum != lib.fakeHash)
            then checksum
            else hash;

          endpoint = "${builtins.toString file-id}";
        };
      };
  });
}
