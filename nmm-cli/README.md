# nmm-cli
###### the nix-mod-manager cli

* [ ] lockfile generation
* [ ] submitting lockfile to store
* [ ] use `nmm get-store` every home manager generation
* [ ] use `fetchStoreMod` with provider + game id + mod id args to retrieve store mod

nix-mod-manager is a currently presented with a problem that
forces clients to have to use mod sources that require
interfacing with an external API.

since internet is not provided during derivation realisation,
this means that API services are a direct roadblock when
fetching mod files through an API.

the purpose of this cli application is to expose a method to retrive
the responses from the API and store them so they can be requested
in Nix code via the `get-store` command combined with `<nixpkgs>.runCommand`.
