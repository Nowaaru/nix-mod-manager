/*
TODO: add mod group support
where mod groups are just another DAG of mods
instead of a DAG. it is then flattened entirely
and added to the main DAG in post.

format
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
      type = with types;
      with lib.hm.types; let
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
              default = "";

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
              default = "mods";

              description = "The path where mods are linked to.";
              example = "/RED/Content/Paks/~mods";
            };

            binaryMods = mkOption {
              type = dagOf mod;
              default = {};

              description = "The mods to link to the binaryPath.";
              example = modsExample;
            };

            mods = mkOption {
              type = dagOf mod;
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
          deploy-mod-deriv = _deriv: let
            deriv =
              if _deriv ? "tmpPath"
              then _deriv
              else _deriv.overrideAttrs (final: {tmpPath = "/tmp/nmm-tmp-${final.name}";});
            deriv-filetype =
              builtins.readFile
              (
                pkgs.runCommandLocal "nmm-filetype-${deriv.name}" {} ''
                  echo $(${pkgs.file}/bin/file --mime-type -bN "${deriv.outPath}") | tr -d '\n' > $out;
                ''
              )
              .outPath;

            passthruHandler =
              ''
                shopt -s nullglob extglob dotglob;
              ''
              + (
                if ((deriv.passthru ? "unpackSingularFolders") && deriv.passthru.unpackSingularFolders)
                then ''
                  mkdir -vp "$out";

                  to=($TMP/!(env-vars));
                  if [[ "''${#to[@]}" -eq 1 ]] && [[ -d "''${to[0]}" ]]; then
                      echo "Moving all entries inside of ''${to[0]}."
                      for entry in "''${to[0]}"/*; do
                          cp --no-preserve=mode -vfr "$entry" "$out";
                      done
                  else
                      echo "unable to find singular folder in '${deriv.name}'"
                      cp --no-preserve=mode -vfr $TMP/!(env_vars) "$out";
                      echo "Moved."
                  fi
                ''
                else ''
                  mkdir -vp "$out"
                  cp --no-preserve=mode -vfr $TMP/!(env_vars) "$out";
                ''
              )
              + (
                if deriv ? "passthru" && deriv.passthru ? "unpackPhase"
                then builtins.traceVerbose "Executing custom unpackPhase: ${deriv.passthru.unpackPhase}" deriv.passthru.unpackPhase
                else "# No custom 'unpackPhase.'"
              );

            isSrcDirectory = deriv-filetype == "inode/directory";
            archiveExtractor = with pkgs; (
              if
                ((deriv-filetype
                  == "application/zip"
                  && cfg.forceGnuUnzip)
                || !pkgs.config.allowUnfree)
              then unzip
              else if pkgs.config.allowUnfree
              then p7zip-rar
              else if isSrcDirectory
              then "this shouldn't happen"
              else
                abort ''
                  Archive '${deriv.name}' cannot be extracted with GNU Unzip.
                  Please enable unfree packages through 'nixpkgs.config.allowUnfree = true'
                  or by setting an environment variable before your command 'NIXPKGS_ALLOW_UNFREE=1 <COMMAND>;'.
                ''
            );

            tmp = ''''$(readlink "$TMP" || realpath "$TMP")'';
          in
            with pkgs;
            # TODO: set 'src' to the extracted deriv
            # where the 'extracted deriv' refers to
            # another mkDerivation where the original
            # rar derivation is the source and is just
            # the unpacked dir.
              if isSrcDirectory
              then builtins.traceVerbose "derivation ${derivation.name} is already a directory, skipping..." deriv
              else
                stdenv.mkDerivation (_: {
                  # pname = "${deriv.name}-extracted";
                  pname = "nmm-mod-${deriv.name}";
                  version = "1.0.0";
                  src = deriv;

                  nativeBuildInputs = [archiveExtractor];
                  unpackPhase = let
                    handler =
                      # TODO: figure out why i have to use {tmp} instead of {deriv.tmpDir or $tmp/TMP}
                      if (archiveExtractor == p7zip-rar)
                      then ''${p7zip-rar}/bin/7z x "${deriv.outPath}" -y -o"${tmp}"''
                      else if (archiveExtractor == unzip)
                      then ''${unzip}/bin/unzip "${deriv.outPath}" -d "${tmp}"''
                      else if (archiveExtractor == rar)
                      then ''${rar}/bin/rar x -op"${tmp}" "${deriv.outPath}" -or -o+ -y''
                      else ''echo "unable to find correct extractor handler for ${archiveExtractor.name}"'';
                  in ''
                    shopt -s dotglob
                    mkdir -vp $out
                    mkdir -vp ${tmp}
                    cd $out

                    ${handler}
                    ${passthruHandler}
                  '';
                });

          deriv = stdenv: let
            # symlinkJoin but better (probably?)
            mass-link-deriv-list-to = root-where: binary-where:
              lists.foldl (acc: v: acc + "${v}\n") ""
              (lists.imap0 (l: w: let
                  is-binary = w.data ? "passthru" && w.data.passthru ? "binary" && w.data.passthru.binary;
                  deployed-deriv-path = (deploy-mod-deriv w.data).outPath;
                  deployment-type = clients.${k}.deploymentType;

                  root-out-path = "${root-where}";

                  out-path =
                    if is-binary
                    then builtins.trace "Is binary (${binary-where})" binary-where
                    else
                      builtins.trace "Not binary." (
                        /*
                        TODO: turn this into an attrset
                        at some point
                        */
                        if deployment-type == "organized"
                        then "${root-out-path}/${builtins.toString l}${w.name}"
                        else root-out-path
                      );
                in ''
                  # MOD: ${w.name};
                  mkdir -vp "${out-path}";
                  for deployed_file in "${deployed-deriv-path}"/*; do
                      cp --no-preserve=mode -vfrs --target-directory="${out-path}" "$deployed_file"
                  done
                      
                  ls -la ${out-path};
                  ls -la "${deployed-deriv-path}";
                  ${
                    if is-binary
                    then ""
                    else ""
                  }
                '')
                v);
            inherit (clients.${k}) modsPath binaryPath;
          in
            with stdenv;
              mkDerivation {
                name = "nmm-client-${k}";
                unpackPhase = ''
                  mkdir -vp "$out" "$out/.binary" #/${modsPath};
                '';

                installPhase = lib.traceVal ''
                  shopt -s dotglob extglob
                  ${mass-link-deriv-list-to "$out" "$out/.binary"}
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

        installPhase =
          "shopt -s dotglob\n"
          + (foldlAttrs (acc: k: v:
            acc
            + ''
              # ${v.name}
              mkdir -vp $out/${k};
              for out_file in ${v.outPath}/*; do
                  ln -sv $out_file $out/${k};''\n''\n
              done
            '') ""
          client-deployers);
      };
    /*
    PLAN: for every mod derivation, index the `.outPath`.
    this should contain one file. use the `file` command
    as a build input to determine the filetype.

    if it is a zip, then use unzip.
    if it's a tar.gz, then use tar xf.
    if it's a rar, then use rar (but require the user to enable unfree packages!!5
    if it's a 7z, then use p7zip.

    if it's none of these, prompt the user to write their own builder.
    */
  in
    mkIf cfg.enable {
      home.file =
        {
          "nix-mod-manager-${builtins.hashString "sha256" nix-mod-manager-final.outPath}" = {
            enable = true;
            recursive = false;
            force = true;
            ignorelinks = true;
            source = nix-mod-manager-final.outPath;
            target = ".local/share/nix-mod-manager";
          };
        }
        // (attrsets.foldlAttrs (acc: name: value:
          acc
          // {
            "0nmm-deploy-${name}-mods-${builtins.hashString "sha256" nix-mod-manager-final.outPath}" = {
              enable = true;
              recursive = true;
              target = lib.strings.normalizePath "${value.rootPath}/${value.modsPath}";
              source = "${nix-mod-manager-final.outPath}/${name}";
            };
            "0nmm-deploy-${name}-binary-mods-${builtins.hashString "sha256" nix-mod-manager-final.outPath}" = rec {
              enable = value.binaryPath != "" && value.binaryPath != ".";
              recursive = true;
              ignorelinks = true;
              target = lib.strings.normalizePath "${value.rootPath}/${value.binaryPath}";
              source = lib.strings.normalizePath "${nix-mod-manager-final.outPath}/${name}/.binary";
            };
          }) {}
        clients);
    };
}
