lib:
    attrs: builtins.hashString "sha256" (lib.generators.toKeyValue {} (lib.attrsets.filterAttrsRecursive (_: lib.strings.isStringLike) attrs))
