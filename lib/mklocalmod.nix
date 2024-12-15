stdenv: {
  name ? "mod",
  store-path,
  # Whether to automatically
  # unpack mods that have one
  # entry in their top-level
  unpackSingularFolders ? false,
  unpackPhase ? ''true'',
}:
stdenv.mkDerivation {
  inherit name;
  src = store-path;

  phases = ["installPhase"];
  installPhase = ''ln -sv $src $out'';

  passthru = {
    inherit unpackPhase unpackSingularFolders;
  };
}
