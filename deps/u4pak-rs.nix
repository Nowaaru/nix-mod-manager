{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchzip,
  stdenv,
  ...
} @ pkgs:
# openssl-nixos-vendored-dir-fix-branch = import ./openssl.nix pkgs;
# stdenv.mkDerivation rec {
#   pname = "rust-u4pak";
#   version = "1.4.0";
#   src = fetchzip {
#     url = "https://github.com/panzi/rust-u4pak/releases/download/v${version}/release-v${version}.zip";
#     hash = "sha256-7fMc9AW+aZIFTBSg129t90DIPTiX4nXw1C9q0NhUCsg=";
#     stripRoot = false;
#   };
#
#   installPhase = ''
#     mkdir $out;
#     cp $src/x86_64-unknown-linux-gnu/u4pak $out;
#   '';
# }
rustPlatform.buildRustPackage rec {
  pname = "rust-u4pak";
  version = "1.4.0";
  src = fetchFromGitHub {
    owner = "panzi";
    repo = pname;
    rev = version;
    hash = "sha256-+k/s9yaTURBBmrxvC8xCvWnCLUlxqnExncLEspNTbok=";
    patches = [

    ];
  };

  cargoHash = "sha256-HvJr4pUDPCj3CjNQCNn1pEQeJg28vFBhNxpnSqcnsYo=";
  PKG_CONFIG_PATH="${pkgs.fuse}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig";
  preUnpack = ''
    echo ${pkgs.openssl.bin}
    export CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG=true
    export RUST_BACKTRACE=1
  '';

  buildInputs = with pkgs; [ openssl fuse ];
  nativeBuildInputs = with pkgs; [
    pkg-config
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
