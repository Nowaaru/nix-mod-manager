pkgs: {
  name ? "mod",
  store-path,
}:
with pkgs;
  stdenv.mkDerivation {
    inherit name;
    src = store-path;

    phases = ["installPhase"];
    installPhase = ''cp $src $out'';
  }
