/*
FIXME:
Wait for 'https://github.com/sfackler/rust-openssl/pull/2122'
to be merged so I can build this package.

TODO: Just convert the TOML to an attrset and change openssl to a
local library with the PR changes. Should be easy enough.
*/
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchzip,
  stdenv,
  ...
} @ pkgs:
with rustPlatform;
  buildRustPackage rec {
    pname = "rust-openssl";
    version = "0.10.64";

    src = fetchFromGitHub {
      owner = "DanielSidhion";
      repo = pname;
      rev = "734d2c555f1d7ef708fda034db8fb5b545e9efb8";
      hash = "sha256-uUdUeN1+wwZrph01ZK+wL1CfEXSTNGgLERBPOrEBxzY=";
    };

    cargoHash = "sha256-LV8ZkmLTk3lJ2TRgLx+vSIS8m7X75377QzncbPfJHSw=";
    cargoPatches = [ ./openssl-lock.patch ];
    buildInputs = with pkgs; [ pkg-config ];
    nativeBuildInputs = with pkgs; [glibc];
    # postUnpack = ''
    #   build=$PWD/build ;
    #   mkdir $build;
    #
    #   if [ -n "$src" ]
    #   then
    #     oldSrc=$src;
    #     mkdir $out;
    #     cp -r $src/* $build;
    #     chmod -R +w $build/*;
    #     cd $build;
    #     cargo generate-lockfile;
    #     src=$build
    #
    #     # touch $out/wat.txt;
    #   fi
    # '';
    #
    # configurePhase = ''
    #   runHook preConfigure
    #   runHook postConfigure
    #   src=$oldSrc
    # '';
    #
    # fixupPhase = ''
    #   echo "LOLSIES!";
    # '';

    meta = {};
  }
