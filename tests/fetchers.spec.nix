{
  nixt,
  ...
}: let
  inherit (nixt.lib) block it describe';
in
  block ./fetchers.spec.nix [
    (describe' "GameBanana" [
      (it "should fetch this module" true)
    ])
  ]
