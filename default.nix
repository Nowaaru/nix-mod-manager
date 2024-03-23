{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  inherit (lib.hm) dag;
  inherit (import ./types.nix lib) mod;
  inherit (lib) options;
  cfg = config.programs.nix-mod-manager;
in {
  imports = [];

  options.programs.nix-mod-manager = with options; {
    enable = mkEnableOption "nix-mod-manager";
    forceGnuUnzip = mkEnableOption "unzipping using GNU unzip";

    clients = mkOption {
      default = {};
      type = with types; let
        submodule-type = submodule {
          options = {
            enable = mkEnableOption "the client";

            binaryPath = mkOption {
              type = uniq str;
            };

            modsPath = mkOption {
              type = uniq str; # huh
            };

            binaryMods = mkOption {
              type = lib.hm.types.dagOf mod;
              default = {};
            };

            mods = mkOption {
              type = lib.hm.types.dagOf mod;
            };

            /*
            TODO: when using the `list` mod option, change
            names to the download output instead of the list
            index
            */
          };
        };
      in
        attrsOf submodule-type;
    };
  };

  /*
  TODO: make derivation for every client that copies the mods into the modspath folder
  FIXME: my laziness
  */
  config = let
    inherit (cfg) clients;
    clients-to-deploy =
      attrsets.foldlAttrs
      (acc: k: v: let
        sorted = dag.topoSort (v.mods // (attrsets.mapAttrs (_: v: v // {data = v.data // {passthru.binary = true;};}) v.binaryMods));
        isSorted = sorted ? "result";
      in
        acc
        // {
          ${k} =
            if isSorted
            then sorted.result
            else abort "mods for client '${k}' were not sorted; possible circular dependency loop?";
        }) {}
      clients;

    client-deployers =
      attrsets.mapAttrs
      (
        k: v: let
          /*
          TODO:
          instead of making a new derivation from the already-fetched
          mod derivation (which can end up taking a LOT of space),
          make the fetchers do the detection so we don't have the
          compressed file + the decompressed contents
          */
          deploy-mod-deriv = deriv: let
            deriv-filetype =
              builtins.readFile
              (
                pkgs.runCommandLocal "nmm-filetype-${deriv.name}" {} ''
                  #/usr/bin/env bash

                  echo $(${pkgs.file}/bin/file --mime-type -bN "${deriv.outPath}") | tr -d '\n' > $out;
                ''
              )
              .outPath;

            archiveExtractor = with pkgs;
              if (deriv-filetype == "application/x-rar")
              then rar
              else
                (
                  if (deriv-filetype == "application/zip" && cfg.forceGnuUnzip)
                  then unzip
                  else p7zip
                );
          in
            with pkgs;
              stdenv.mkDerivation {
                name = "nmm-mod-${deriv.name}";

                nativeBuildInputs = [
                  archiveExtractor
                ];

                unpackPhase = let
                  handler =
                    if (archiveExtractor == p7zip)
                    then ''${p7zip}/bin/7z x "${builtins.trace "extracting p7zip" deriv.outPath}" -y -o"$out"''
                    else if (archiveExtractor == unzip)
                    then ''${unzip}/bin/unzip "${builtins.trace "extracting unzip" deriv.outPath}" -d "$out"''
                    else if (archiveExtractor == rar)
                    then ''${rar}/bin/rar e -op"$out" "${builtins.trace "extracting rar" deriv.outPath}"''
                    else ''echo "unable to find correct extractor handler for ${archiveExtractor.name}"'';
                in ''
                  #/usr/bin/env bash
                  mkdir -p $out;

                  ${handler};
                  sync;
                '';
              };

          deriv = stdenv: let
            mass-link-deriv-list-to = binary-where:
              lists.foldl (acc: v: acc + "${v}\n") ""
              (lists.imap0 (l: w: let
                  is-binary = w.data.passthru ? "binary" && w.data.passthru.binary;
                  deployed-deriv-path = (deploy-mod-deriv w.data).outPath;
                  out-path =
                    if is-binary
                    then binary-where
                    else "${binary-where}/${modsPath}/${builtins.toString l}-${w.name}";
                in ''
                  # MOD: ${w.name};
                  mkdir -p ${out-path};
                  ls -la ${out-path}/**;
                  cp --no-preserve=mode -frs "${deployed-deriv-path}"/* "${out-path}";
                '')
                v);
            inherit (clients.${k}) modsPath;
          in
            with stdenv;
              mkDerivation {
                name = "nmm-client-${k}";
                unpackPhase = ''
                  mkdir -p $out/${modsPath};
                '';

                installPhase = ''
                  ${mass-link-deriv-list-to "$out"}
                '';
              };
        in
          deriv pkgs.stdenv
      )
      clients-to-deploy;

    nix-mod-manager-final = with pkgs.stdenv;
      mkDerivation {
        name = "nix-mod-manager";
        unpackPhase = "true";

        installPhase = foldlAttrs (acc: k: v:
          acc
          + ''
            # ${v.name}
            mkdir -p $out/${k};
            ln -s ${v.outPath}/* $out/${k};''\n''\n
          '') ""
        client-deployers;
      };
    /*
    PLAN: for every mod derivation, index the `.outPath`.
    this should contain one file. use the `file` command
    as a build input to determine the filetype.

    if it is a zip, then use unzip.
    if it's a tar.gz, then use tar xf.
    if it's a rar, then use rar (but require the user to enable unfree packages!!)
    if it's a 7z, then use p7zip.

    if it's none of these, prompt the user to write their own builder.
    */
  in
    mkIf cfg.enable {
      home.file =
        {
          nix-mod-manager = {
            enable = true;
            recursive = true;
            source = nix-mod-manager-final.outPath;
            target = ".local/share/nix-mod-manager";
          };
        }
        // (attrsets.mapAttrs (name: value: {
            enable = true;
            recursive = true;
            target = value.binaryPath;
            source = nix-mod-manager-final.outPath + "/${name}";
          })
          clients);
    };
}
