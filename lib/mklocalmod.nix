pkgs: {
  name ? "mod",
  store-path,
  unpackPhase ? ''true'',
}:
with pkgs;
  stdenv.mkDerivation {
    inherit name;
    src = store-path;

    phases = ["installPhase"];
    installPhase = ''cp $src $out'';
    passthru.unpackPhase = unpackPhase;
  }
