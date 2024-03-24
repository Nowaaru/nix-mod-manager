pkgs: let
  mkLocalMod = import ../mklocalmod.nix pkgs;
  inherit (pkgs) lib;

  stringify = builtins.toString;
in
  with pkgs; rec {
    mkApiPath = protocol: host: "${protocol}://${host}";

    mkProvider = provider:
      provider
      // {
        useGame = game-id:
          lib.attrsets.mapAttrs (_: v: v game-id) provider;
      };

    mkNexus = api-key: let
      api-base-uri = mkApiPath "https" "api.nexusmods.com";
    in
      mkProvider rec {
        mkRequest = api:
          builtins.fromJSON (builtins.readFile (fetchurl {
            name = "request-nexus";
            url = "${api-base-uri}/${api}";

            downloadToTemp = true;
            curlOptsList = [
              ''-H "accept: application/json"''
              ''-H "apikey: ${api-key}"''
            ];

            inherit hash;
          }));

        fetchNexus = game-domain-name: {
          name ? "nexus-mod-${stringify mod-id}-${stringify file-id}-${stringify hash}",
          hash ? lib.fakeHash,
          mod-id,
          file-id,
        }:
          mkLocalMod {
            inherit name;

            store-path = stdenv.mkDerivation {
              name = "request-${name}";
              src = mkRequest "v1/games/${stringify game-domain-name}/mods/${stringify mod-id}/files/${stringify file-id}/download_link.json";
            };
          };
      };
  }
