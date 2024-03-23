<div align="center">
        <h3> nix-mod-manager</h1>
	    <h5> the purest mod manager for home-manager<br/><br/>-</h6>
        <h6>
        <a href = "#-getting-started">getting started</a> · <a href="#-contributing">contributing</a> · <a href="#%EF%B8%8F-customization">customization</a>
        </h6>
        <img alt="GitHub License" src="https://img.shields.io/github/license/Nowaaru/nix-mod-manager?style=flat-square&logo=license&logoColor=%23D9E0EE&labelColor=%23302D41&color=%23F2CDCD"/>
        <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Nowaaru/nix-mod-manager?style=flat-square&labelColor=%23302D41&color=%2389ADF3"/>
        <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/nowaaru/nix-mod-manager?style=flat-square&labelColor=%23302D41&color=%23A6DA95"/>
        <br />
        <h6>❄</h6>
        <hr />
</div>

<h3>🔰 Getting Started</h3>
<ul>
	  <h5>Requirements to Slay ⚔️</h5>

- [x] Nix, Manager of Packages 🐲
- [x] Flakes, The Mysterious One ❄️
- [x] Home Manager, Manager of Home Directories 🏰

</ul>

First, bust out your favorite text editor and add the repository
to your flake:

```nix
[^]
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    	home-manager = {
            url = "github:nix-community/home-manager/master";
            inputs.nixpkgs.follows = "nixpkgs";
    	};

        nix-mod-manager.url = "github:nowaaru/nix-mod-manager/master";
    };

    outputs = {
    	home-manager,
        nix-mod-manager, # 🌟
[v]
```

Afterwards, add it to your Home Manager configuration either as an import in
a module file or directly through the module list:

```nix
[^]
            specialArgs = {inherit inputs;};
       		modules = [];
        };

    	homeConfigurations."rainbow-road" = home-manager.lib.homeManagerConfiguration {
      		inherit pkgs;
      		extraSpecialArgs = {inherit inputs;};
      		modules = [
        		nix-mod-manager.homeManagerModules.default # 🌟
        		./home.nix
      		];
    	};
[v]
```

And, voilà! nix-mod-manager is finally ready to roll! To start configuring, make a
new module for your Home Manager configuration:

```nix
[^]
        };

    	homeConfigurations."rainbow-road" = home-manager.lib.homeManagerConfiguration {
      		inherit pkgs;
      		extraSpecialArgs = {inherit inputs;};
      		modules = [
        		nix-mod-manager.homeManagerModules.default
                ./nix-mod-manager.nix # 🌟
        		./home.nix
      		];
    	};
	};
```

nix-mod-manager's default module exports the `programs.nix-mod-manager` module for you to change to your liking. To see what fields you can customize, check out the <a href="#%EF%B8%8F-customization">customization index</a>.

<h3>🧰 Library</h3>

The nix-mod-manager's `lib` output contains the `nnmm` (noire's-nix-mod-manager) library. In this library contains a handful of useful functions for things like creating mod derivations through [referencing store files](https://github.com/Nowaaru/nix-mod-manager/blob/fd1a733b7ba5570b11711c85a5abf6736a2f3b62/lib/fetchers.nix#L19C1-L30) and [fetching from remote CDNs](https://github.com/Nowaaru/nix-mod-manager/blob/fd1a733b7ba5570b11711c85a5abf6736a2f3b62/lib/fetchers.nix#L32-L45).

<h3>⚙️ Customization</h3>
nix-mod-manager exports the `programs.nix-mod-manager` module. For the module to work, the `enable` property must be set to true:
```nix
{
    programs.nix-mod-manager = {
        enable = true;
    };
}
```
A game that is managed is called a **client.** The property is also aptly named `clients` and requires an attribute set of attribute sets. Like the module, clients must also be enabled for their mods to be deployed:
```nix

{
    programs.nix-mod-manager = {
        enable = true;
            clients = {
                monster-hunter-world = {
                enable = true;
            };
        };
    };
}

```
A client requires a `modsPath` and a `binaryPath` to be functional. The `binaryPath` field should be relative to the `$HOME` (`~`) directory, and the `modsPath` field should be relative to the `binaryPath` field.

```nix

{
    programs.nix-mod-manager = {
        enable = true;
        clients = {
            monster-hunter-world = {
                enable = true;
                modsPath = "nativePC";
                binaryPath = ".local/share/Steam/steamapps/common/Monster Hunter World";
            };
        };
    };
}
```

A mod manager isn't a mod manager without mods. To get started, we'll be using **D**ynamic **A**crylic **G**raphics (DAGs) from Home Manager. Mods can either be fetched via turning a store path into a derivation or fetching it through a fetcher. If a mod needs to be placed alongside the binary, the `binaryMods` DAG should suffice.
```nix
with lib.nnmm; with fetchers;
{
    programs.nix-mod-manager = {
        enable = true;
        clients = {
            monster-hunter-world = {
                enable = true;
                modsPath = "nativePC";
                binaryPath = ".local/share/Steam/steamapps/common/Monster Hunter World";

                binaryMods = {
                    example-binary-mod-0 = entryAnywhere (fetchGameBanana {
                        name = "my-super-cool-gamebanana-mod";
                        hash = lib.fakeHash;
                    });
                };

                mods = {
                    example-mod-0 = entryAfter ["example-binary-mod-0"] (mkLocalMod {
                        name = "example-mod-0";
                        store-path = /nix/store/...;
                    });
                    example-mod-1 = entryAfter ["example-binary-mod-1"] (mkLocalMod {
                        name = "example-mod-1";
                        store-path = /nix/store/...;
                    });
                };
            };
        };
    };
}
```

<h3>💙 Contributing</h3>
<h5>Pull Requests</h5>
Generally, I'm okay to pull requests as long as the code is good and neat and follows the conventions that the project follows (or lines up closely enough to it). If your pull request takes a while to get merged while there appears to be no backlog, feel free to mention a maintainer or two - but overdoing it makes the whole process slower. It might even get your permissions to contribute revoked!
<br/><br/>
If you don't know what to make a pull request about, then <i>please</i> don't bother to search for a reason, instead use the project a little bit and figure out something you don't like or something that you think most of the userbase would collectively enjoy. Misspellings and accidental character placements will be addressed at some point, but it is of nothing of urgency to make a pull request for. This isn't a repository you can farm points on!
<h5>Issue-making</h5>
<p>
If you notice something wrong with the project or the way it functions, let me know by <a href="https://github.com/Nowaaru/nix-mod-manager/issues/new">making an issue</a>! I'll get on it as quickly as my fingers 💅 and brain 🧠 allows me to - the latter of which likely being the bottleneck.
<br/><br/>
When making an issue, do be sure to <b>remember the human</b> and <b>remember the newbie</b>. Despite the facade of an anime icon or a mysterious set of blue-tinted buildings with a red room, there's still a human behind that icon, and that human could very well be new to what they're coming across. Newcomers will soon be our replacements, so no reason to bite the hand that will feed us the following day!
</p>
<h5>Codewriting</h5>
<p>
  While creating nix-mod-manager, I had a very strong intention to use as much Nix as possible and rely as little on shell scripts to get a better grasp of the language, but now I feel it's to upkeep the "<b>nix</b>" aspect of the name. When making contributions, I would prefer and deeply appreciate if contributors used the intended language whenever they can (within reason).
</p>
<hr />
<div align="center"><h6> ❄ </h6></div>
````
