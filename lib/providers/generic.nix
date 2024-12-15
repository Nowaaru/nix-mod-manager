lib: {
  # Make a provider factory. 
  # Intended to create providers.
  mkProvider = providerData: genericModArguments: (providerData genericModArguments);

  # Make a request provider.
  mkRequestProvider = {
    api-base-uri,
    api-key-header ? (api-key: ""),
  }: {
    # Make a request.
    mkRequest = {
      hash,
      endpoint,
      base-uri ? api-base-uri,
      api-key ? "",
      name ? "request",
      postFetch ? ''cp -v $downloadedFile $out'',
      hash-algo ? "sha256",
    }:
      lib.fetchurl {
        inherit postFetch name;
        url = "${base-uri}/${endpoint}";

        curlOptsList = [
          ''-H "accept: application/json"''
          ''-H "${api-key-header api-key}"''
        ];

        downloadToTemp = true;
        recursiveHash = false;

        outputHash = hash;
        outputHashAlgo = hash-algo;
      };
  };
}