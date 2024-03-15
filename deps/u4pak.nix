{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchzip,
  stdenv,
  ...
} @ pkgs:
with rustPlatform;
  stdenv.mkDerivation rec {
    pname = "rust-u4pak";
    version = "1.4.0";

    src = fetchFromGitHub {
      owner = "panzi";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-+k/s9yaTURBBmrxvC8xCvWnCLUlxqnExncLEspNTbok=";
    };

    nativeBuildInputs = with pkgs; [rust-bin.nightly.latest.default];

    unpackPhase = ''
      mkdir $out
      cd $src
      cargo build --release
      ls -R > $out/gamer.txt
    '';

    buildPhase = ''

    '';

    meta = {
      description = "unpack, pack, list, check and mount Unreal Engine 4 .pak archives";
      homepage = "https://github.com/panzi/rust-u4pak";
      license = lib.licenses.mpl20;
      maintainers = [];
    };
  }
/*
  FIXME:
  Wait for 'https://github.com/sfackler/rust-openssl/pull/2122'
  to be merged so I can build this package.

  TODO: Just convert the TOML to an attrset and change openssl to a
  local library with the PR changes. Should be easy enough.

buildRustPackage rec {
  pname = "rust-u4pak";
  version = "1.4.0";
  src = fetchFromGitHub {
    owner = "panzi";
    repo = pname;
    rev = version;
    hash = "sha256-+k/s9yaTURBBmrxvC8xCvWnCLUlxqnExncLEspNTbok=";
  };

  cargoHash = "sha256-HvJr4pUDPCj3CjNQCNn1pEQeJg28vFBhNxpnSqcnsYo=";
  preUnpack = ''
    echo ${pkgs.openssl.bin}
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${pkgs.fuse}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig
    export OPENSSL_DIR=${pkgs.openssl.bin}
    export CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG=true
    export RUST_BACKTRACE=full
  '';

  buildInputs = with pkgs; [ openssl ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    fuse
  ];


  meta = {
    description = "unpack, pack, list, check and mount Unreal Engine 4 .pak archives";
    homepage = "https://github.com/panzi/rust-u4pak";
    license = lib.licenses.mpl20;
    maintainers = [];
  };

  # nativeBuildInputs = [rust-bin.nightly.latest.default];
  # buildPhase = ''
  #   #!${pkgs.bash}/bin/bash
  #   cargo build --release
  # '';
}
*/

