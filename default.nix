{
  pkgs,
  lib,
  home-manager,
  config,
  ...
}:
with lib; let
  inherit (home-manager.lib.hm) dag;
  inherit (import ./types.nix lib) mod;
  inherit (lib) options;
  cfg = config.programs.nix-mod-manager;

  st = w: builtins.trace "type: ${w}" w;
in {
  imports = [];

  options.programs.nix-mod-manager = with options; {
    enable = mkEnableOption "nix-mod-manager";
    forceGnuUnzip = mkEnableOption "unzipping using GNU unzip.";

    clients = mkOption {
      default = {};
      type = with types; let
        submodule-type = submodule {
          options = {
            enable = mkEnableOption "the client";

            rootPath = mkOption {
              type = uniq str;
            };

            modsPath = mkOption {
              type = uniq str;
            };

            mods = mkOption {
              type = home-manager.lib.hm.types.dagOf mod;
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
        sorted = dag.topoSort v.mods;
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
      attrsets.foldlAttrs
      (acc: k: v: let
        /*
        TODO:
        instead of making a new derivation from the already-fetched
        mod derivation (which can end up taking a LOT of space),
        make the fetchers do the detection so we don't have the
        compressed file + the decompressed contents
        */
        deploy-mod-deriv = deriv: let
          mkIfElse = p: yes: no:
            mkMerge [
              (mkIf p yes)
              (mkIf (!p) no)
            ];

          deriv-filetype = st (builtins.readFile
            (
              pkgs.runCommandLocal "nmm-filetype-${deriv.name}" {} (
                st ''
                  #/usr/bin/env bash

                  echo $(${pkgs.file}/bin/file --mime-type -bN "${deriv.outPath}") | tr -d '\n' > $out;
                ''
              )
            )
            .outPath);

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
                  then ''"${p7zip}/bin/7z x ${deriv.outPath} -o"$out"''
                  else if (archiveExtractor == unzip)
                  then ''${unzip}/bin/unzip ${deriv.outPath} -d "$out"''
                  else if (archiveExtractor == rar)
                  then ''${rar}/bin/rar e -op"$out" ${deriv.outPath}''
                  else abort "unable to find correct extractor handler for ${archiveExtractor.name}";
              in
                st ''
                  #/usr/bin/env bash

                  ${handler};
                '';
            };

        deriv = stdenv: let
          /*
          install phase:
          after turning the client mod DAG into a list of
          fetch(source, i.e. GameBanana) derivations, symlink
          the out directory into the directory of the `deriv` output.

          home manager final:
          link the modsPath to the `deriv` output.
          */
          mass-link-deriv-list-to = where:
            lists.foldl (acc: v: acc + "${v}\n") ""
            (lists.imap0 (l: w: let
                deployed-deriv = deploy-mod-deriv w.data;
                out-path =  "${where}/${builtins.toString l}-${w.name}";
              in ''
                
                # MOD: ${w.name};
                mkdir -p ${out-path};
                ln -s "${deployed-deriv.outPath}"/* ${out-path};
              '')
              v);
        in
          with stdenv;
            mkDerivation {
              name = "nmm-client-${k}";
              unpackPhase = "true";

              installPhase = st ''
                ${mass-link-deriv-list-to "$out"}
              '';
            };
      in
        acc
        // {
          ${k} =
            if acc ? k
            then acc.${k} ++ [(deriv pkgs.stdenv)]
            else [(deriv pkgs.stdenv)];
        }) {}
      clients-to-deploy;
    # attrsets.foldlAttrs (acc: k: v: acc ++ "echo ${st k} - ${lists.foldl' (acc: v: "${acc}${v.data}\n") "" (st v)}\n") "" clients-to-deploy;
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
      home.activation = {
        nix-mod-manager-deploy = dag.entryAnywhere ''
          echo "Noire's Nix Mod Manager has started deploying."
          echo "it's lol time"
          echo "elem at: ${builtins.elemAt client-deployers.monster-hunter-world 0}"
        '';
        nix-mod-manager-cleanup = dag.entryAfter ["nix-mod-manager-deploy"] ''
          echo "Noire's Nix Mod Manager has finished deploying."
        '';
      };
    };
}
