/*
TODO: add mod group support
where mod groups are just another DAG of mods
instead of a DAG. it is then flattened entirely 
and added to the main DAG in post.
*/
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

  st = w: builtins.trace w w;
  modsExample = ''
    entryAnywhere (lib.nmm.mkLocalMod {
      ...
    });
  '';
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

            deploymentType = mkOption {
              type = enum ["loose" "organized"];
              default = "organized";
              description = ''
                The way this client will deploy when Home Manager
                the home manager generation changes.

                Loose - All files are dropped directly into the configured 'modsPath' path.
                Organized - All mods are contained in a folder with a naming scheme of "{load-order}-{mod-name}".
              '';
            };

            binaryPath = mkOption {
              type = str;
              default = ".";
              defaultText = "the root path";
              description = "The path where binary mods (.dlls, executables) are linked to.";
            };

            rootPath = mkOption {
              type = uniq str;
              description = "The path where the game binary is located.";
              example = "~/.local/share/Steam/GUILTY GEAR STRIVE";
            };

            modsPath = mkOption {
              type = uniq str;
              description = "The path where mods are linked to.";
              example = "/RED/Content/Paks/~mods";
            };

            binaryMods = mkOption {
              type = lib.hm.types.dagOf mod;
              default = {};
              description = "The mods to link to the binaryPath.";
              example = modsExample;
            };

            mods = mkOption {
              type = lib.hm.types.dagOf mod;
              default = {};
              description = "The mods to link to the modsPath.";
              example = modsExample;
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
            # if (deriv-filetype == "application/x-rar")
            # then rar
            # else
              (
                if
                  (deriv-filetype
                    == "application/zip"
                    || cfg.forceGnuUnzip
                    || !pkgs.config.allowUnfree)
                then unzip
                else if pkgs.config.allowUnfree
                then p7zip-rar
                else
                  abort ''
                    Archive '${deriv.name}' cannot be extracted with GNU Unzip.
                    Please enable unfree packages through 'nixpkgs.config.allowUnfree = true'
                    or by setting an environment variable before your command 'NIXPKGS_ALLOW_UNFREE=1 <COMMAND>;'.
                  ''
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
                    if (archiveExtractor == p7zip-rar)
                    then ''${p7zip-rar}/bin/7z x "${deriv.outPath}" -y -o"$out"''
                    else if (archiveExtractor == unzip)
                    then ''${unzip}/bin/unzip "${deriv.outPath}" -d "$out"''
                    else if (archiveExtractor == rar)
                    then ''${rar}/bin/rar x -op"$out" "${deriv.outPath}" -or -o+ -y''
                    else ''echo "unable to find correct extractor handler for ${archiveExtractor.name}"'';
                in ''
                  #!/usr/bin/env bash
                  mkdir -vp $out;
                  cd $out
                  ${handler};
                  ${
                    if deriv ? "passthru" && deriv.passthru ? "unpackPhase"
                    then deriv.passthru.unpackPhase
                    else "# No custom 'unpackPhase.'"
                  }
                  sync;
                '';

                fixupPhase =
                  if deriv.passthru ? "unpackSingularFolders"
                  then ''
                    #!/usr/bin/env bash;

                    shopt -s nullglob extglob

                    cd $out;
                    to=(./*);
                    if [[ "''${#to[@]}" -eq 1 ]] && [[ -d "''${to[0]}" ]]; then
                        echo "Moving all entries inside of ''${to[0]}."
                        mv -v "''${to[0]}"/* $out;
                        echo "Removing folder ''${to[0]}.";
                        rm -rf "''${to[0]}";
                    else
                        echo "unable to find singular folder in '${deriv.name}'"
                        echo "''${to[0]/*}"
                    fi
                  ''
                  else '''';
              };

          deriv = stdenv: let
            mass-link-deriv-list-to = root-where: binary-where:
              lists.foldl (acc: v: acc + "${v}\n") ""
              (lists.imap0 (l: w: let
                  is-binary = w ? "passthru" && w.passthru ? "binary" && w.data.passthru.binary;
                  deployed-deriv-path = (deploy-mod-deriv w.data).outPath;
                  deployment-type = clients.${k}.deploymentType;

                  root-out-path = "${root-where}/${modsPath}";

                  out-path =
                    if is-binary
                    then binary-where
                    else
                      (
                        /*
                        TODO: turn this into an attrset
                        at some point
                        */
                        if deployment-type == "organized"
                        then "${root-out-path}/${builtins.toString l}-${w.name}"
                        else root-out-path
                      );
                in ''
                  # MOD: ${w.name};

                  mkdir -vp ${out-path};
                  ls -la ${out-path}/**;
                  cp --no-preserve=mode -vfrs "${deployed-deriv-path}"/* "${out-path}";
                '')
                (st v));
            inherit (clients.${k}) modsPath binaryPath;
          in
            with stdenv;
              mkDerivation {
                name = "nmm-client-${k}";
                unpackPhase = ''
                  mkdir -vp $out/${modsPath};
                '';

                installPhase = ''
                  ${mass-link-deriv-list-to "$out" "$out/${binaryPath}"}
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
            mkdir -vp $out/${k};
            ln -sv ${v.outPath}/* $out/${k};''\n''\n
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
            target = value.rootPath;
            source = nix-mod-manager-final.outPath + "/${name}";
          })
          clients);
    };
}
