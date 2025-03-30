stdenv: lib: {
  name ? "mod",
  store-path,
  # Whether to automatically
  # unpack mods that have one
  # entry in their top-level
  checksum ? "",
  hash ? "", 

  unpackSingularFolders ? false,
  unpackPhase ? ''true'',
}:
stdenv.mkDerivation {
  inherit name;
  src = store-path;

  phases = ["setupPhase"];
  setupPhase = ''
    cp -Hrsvf "''$src" "''$out"
  '';

  passthru = {
    inherit unpackPhase unpackSingularFolders;
  };
}
