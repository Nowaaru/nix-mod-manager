{lib}: let
  inherit (lib) noire;

  GameBananaMod = with lib.types;
    mkOptionType {
      name = "game-banana-mod";
      check = modData: {};
    };
in {
  fetchGameBanana = traits: {};
}
