{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs_unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    StevenBlackHosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shix = {
      url = "github:litchipi/shix";
      # url = "path:/home/john/.local/share/shix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Overlays
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pomodoro = {
      url = "github:litchipi/pomodoro";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-secrets = {
      url = "github:litchipi/nixos-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    json-repl = {
      url = "github:litchipi/json_repl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    encryptf = {
      url = "github:litchipi/encrypt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages
    helix.url = "github:helix-editor/helix/master";
  };

  outputs = { nixpkgs, nixpkgs_unstable, ...}@inputs:
  let
    # Prepare the nixpkgs for a specific system;
    # TODO  Pass the libraries as an overlay
    common_overlays = [
      inputs.rust-overlay.overlays.default
      inputs.pomodoro.overlays.default
      (self: super: (import ./overlays/overlays.nix self super))
    ];

  in inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs_unstable = import nixpkgs_unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = common_overlays;
      };

      pkgs_from_unstable = self: super: {
      };

      pkgs = import nixpkgs {
        overlays = common_overlays ++ [
          inputs.nixos-secrets.overlays.${system}.default
          pkgs_from_unstable
        ];
        config.allowUnfree = true;
        inherit system;
      };

    # Building
      # Additionnal modules for any nixos configuration
      base_modules = system: [
        # TODO  Merge some base files, remove unsued
        ./base/base.nix
        ./base/colors.nix
        ./base/disks.nix
        ./base/networking.nix
        ./base/setup.nix
        ./base/shell.nix
        ./base/usericon.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.StevenBlackHosts.nixosModule
        inputs.shix.nixosModules.${system}.default
        # inputs.envfs.nixosModules.envfs
        (pkgs.secrets.mkModule ./data/secrets/secrets.json)
        {
          _module.args = {
            inherit inputs system pkgs_unstable;
            home-manager-lib = inputs.home-manager.lib.hm;
          };
          secrets.decrypt_key_cmd = inp: out: let
            encryptf = "${inputs.encryptf.packages.${system}.default}/bin/encryptf";
          in "${encryptf} ${out} --decrypt ${inp}";
        }
      ];

      targetlib = import ./lib/targets.nix {
        inherit inputs pkgs;
        lib = pkgs.lib;
      };

      targets = {
        nixostest = { software = ./software/nixostest.nix; };
        suzie = {
          software = ./software/homelab.nix;
          hardware = ./hardware/suzie.nix;
        };
        sparta = {
          software = ./software/personnal_computer.nix;
          hardware = ./hardware/sparta.nix;
          add_modules = [
            inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h
          ];
        };
      };

      common_apps = {
        build_all = targetlib.simple_script "build_all_machines"
          (builtins.concatStringsSep "\n" (builtins.mapAttrs (name: machine: ''
            echo "${name}: ${(targetlib.mkTargetPackages base_modules machine system).guivm}"
          '') targets)
        );

        create_provision_key = pkgs.secrets.scripts.mkProvisionKeyScript {
          pubk_dir = "data/secrets/pubkeys";
          privk_dir = "data/secrets/privkeys";
          secretf= "data/secrets/secrets.json";
          key_type = "rsa";
          runtimeInputs = [ inputs.encryptf.packages.${system}.default ];
          encrypt_key_cmd = inp: out: "encryptf \"${out}\" --encrypt \"${inp}\"";
        };

        decrypt_provision_key = pkgs.secrets.scripts.mkDecryptProvKeyScript {
          privk_dir = "data/secrets/privkeys";
          runtimeInputs = [ inputs.encryptf.packages.${system}.default ];
          decrypt_key_cmd = inp: out: "encryptf \"${out}\" --decrypt \"${inp}\"";
        };

        edit_secrets = pkgs.secrets.scripts.mkEditScript {
          secretf = "data/secrets/secrets.json";
          pubk_dirs = [ "data/secrets/pubkeys" ];
        };
      };
  in {
    # TODO  Create a CI workflow to test this repository at every push on main
    packages = targetlib.mkAllTargetPackages base_modules targets system;
    apps = (targetlib.mkAllTargetApps base_modules targets system) // common_apps;
  });
}


