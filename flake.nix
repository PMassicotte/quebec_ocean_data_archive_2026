{
  description = "A Nix-flake-based R development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Track arf on main; run `nix flake update arf` (or `nix flake update`) to upgrade
  inputs.arf = {
    url = "github:eitsupi/arf";
    flake = false;
  };

  inputs.rnaturalearthhires = {
    url = "github:ropensci/rnaturalearthhires";
    flake = false;
  };

  inputs.ggpmthemes = {
    url = "github:PMassicotte/ggpmthemes";
    flake = false;
  };

  outputs =
    { self, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowBroken = true;
              overlays = [ inputs.self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: rec {
        # Build rnaturalearthhires from ropensci source
        rnaturalearthhires = final.rPackages.buildRPackage {
          name = "rnaturalearthhires";
          src = inputs.rnaturalearthhires;

          propagatedBuildInputs = with final.rPackages; [
            sp
          ];

          meta = {
            description = "High resolution world vector map data from Natural Earth";
            homepage = "https://github.com/ropensci/rnaturalearthhires";
            maintainers = [ ];
          };
        };

        # Build ggpmthemes from PMassicotte source
        ggpmthemes = final.rPackages.buildRPackage {
          name = "ggpmthemes";
          src = inputs.ggpmthemes;

          propagatedBuildInputs = with final.rPackages; [
            ggplot2
            extrafont
          ];

          meta = {
            description = "Personal ggplot2 themes by Philippe Massicotte";
            homepage = "https://github.com/PMassicotte/ggpmthemes";
            maintainers = [ ];
          };
        };

        # Build arf (modern Rust-based R console) from the flake input.
        # To upgrade: nix flake update arf  (or just: nix flake update)
        # If outputHashes need updating after upgrade, use lib.fakeHash → run `nix develop` → paste the "got: sha256-..." value.
        arf = final.rustPlatform.buildRustPackage {
          pname = "arf";
          version = inputs.arf.shortRev or "unstable";

          src = inputs.arf;

          cargoLock = {
            lockFile = "${inputs.arf}/Cargo.lock";
            outputHashes = {
              "crossterm-0.29.0" = "sha256-SLgsOq875vQXnKxoAfG5PvEegpRJrxXCD2CV1jyI9TQ=";
              "rd-parser-0.1.0" = "sha256-gb3Q05D+qBWcjLnR5INMb5mn910KsSt5Tk/PW8EnUps=";
              "rd2qmd-core-0.1.0" = "sha256-gb3Q05D+qBWcjLnR5INMb5mn910KsSt5Tk/PW8EnUps=";
              "rd2qmd-mdast-0.1.0" = "sha256-gb3Q05D+qBWcjLnR5INMb5mn910KsSt5Tk/PW8EnUps=";
              "tree-sitter-r-1.2.0" = "sha256-H4iK2p4xXjP6gGrOP/qpHQCiO3Jyy0jmb8u29RM0sBg=";
              "reedline-0.46.0" = "sha256-aYMnnX7dsiunnO/eh3SYP0V32qofpU8UuLrsyRYVVRM=";
            };
          };

          # Two cd/tilde tests fail in the Nix sandbox (no $HOME), skip them
          doCheck = false;

          buildInputs = with final; lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security ];
          nativeBuildInputs = with final; [ pkg-config ];

          meta = {
            description = "A modern Rust-based R console with fuzzy history, tree-sitter highlighting, and vi/emacs modes";
            homepage = "https://github.com/eitsupi/arf";
            license = lib.licenses.mit;
            mainProgram = "arf";
          };
        };

        # IDE packages — required by R.nvim editor features, stable across projects
        ideRPackages = with final.rPackages; [
          httpgd # hgd_browse keymap in r.lua
          data_table # view_df save_fun uses data.table::fwrite
        ];

        # Project packages — specific to this analysis, the reproducible core
        # Edit this list per project
        projectRPackages = with final.rPackages; [
          cli
          fs
          ggpmthemes
          ggthemes
          glue
          gt
          here
          httpgd
          janitor
          knitr
          magick
          patchwork
          pins
          quarto
          readxl
          rnaturalearthdata
          rnaturalearthhires
          scales
          sf
          stars
          tidytext
          tidyverse
        ];

        rPackageList = ideRPackages ++ projectRPackages;

        # Create rWrapper with packages (for LSP and R.nvim)
        wrappedR = final.rWrapper.override { packages = rPackageList; };

        # Create radianWrapper with same packages (for interactive use)
        wrappedRadian = final.radianWrapper.override { packages = rPackageList; };
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              wrappedR # R with packages for LSP
              wrappedRadian # radian with packages for interactive use
              arf # modern Rust-based R console
              jarl # fast R linter (from nixpkgs)
              quarto
            ];

            shellHook = ''
              export R_HOME=$(R RHOME)
              export R_LIBS_SITE=$(grep -oP "'/nix/store/[^']+/library'" "$(command -v R)" | tr -d "'" | sort -u | paste -sd: -)
              export R_LIBS_USER="$PWD/.r-libs"
              mkdir -p "$R_LIBS_USER"
            '';
          };
        }
      );
    };
}
