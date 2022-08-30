{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/22.05";
    nixpkgs_unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    StevenBlackHosts = {
      url = "github:StevenBlack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    shix = {
      url = "github:litchipi/shix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    persowebsite = {
      url = "path:/home/tim/Projects/perso/webdev_portfolio/personnal_website";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Overlays
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs_unstable, ...}@inputs:
  let
  # General utils
    # Find all files located in a specific directory
    find_all_files = dir: nixpkgs.lib.lists.flatten (
      (builtins.map find_all_files (list_elements dir "directory"))
      ++ (list_elements dir "regular")
    );

    # List all elements inside the directory that matches a certain type
    list_elements = dir: type: map (f: dir + "/${f}") (
      nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs
          (_: entryType: entryType == type)
          (builtins.readDir  dir)
        )
      );

    # Prepare the nixpkgs for a specific system;
    pkgsForSystem = system: let
      pkgs_unstable = import nixpkgs_unstable {
        inherit system;
      };
      packages_on_unstable = [
        pkgs_unstable.protonvpn-cli
        pkgs_unstable.gitFull
        pkgs_unstable.neovim
        pkgs_unstable.rust-analyzer
        pkgs_unstable.vimPlugins.coc-rust-analyzer
      ];
    in import nixpkgs {
      overlays = [
        inputs.rust-overlay.overlay
        (prev: final: (import ./overlays/overlays.nix final))
        (prev: final: builtins.listToAttrs (builtins.map (pkg: {
          name = pkg.name;
          value = pkg;
        }) packages_on_unstable))
      ];
      config.allowUnfree = true;
      inherit system;
    };

    simple_script = pkgs: name: text: {
      type = "app";
      program = let
        exec = pkgs.writeShellScript name text;
      in "${exec}";
    };

  # Building
    # Additionnal modules for any nixos configuration
    base_modules = system: (find_all_files ./base) ++ (find_all_files ./common) ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.StevenBlackHosts.nixosModule
      inputs.nix-ld.nixosModules.nix-ld
      inputs.shix.nixosModules.x86_64-linux.default
      # inputs.envfs.nixosModules.envfs
      {
        _module.args = {
          inherit inputs system;
        };
      }
    ];

    # Create output format derivation using nixos-generators
    build_deriv_output = format: { software, hardware ? null, add_modules ? [], ...}:
      system: format_modules:
      inputs.nixosgen.nixosGenerate {
        pkgs = pkgsForSystem system;
        inherit format;
        modules = [ software ] ++ (if builtins.isNull hardware then [] else [hardware])
          ++ (base_modules system) ++ add_modules ++ format_modules;
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = { name, add_modules ? [], ...}@machine: system: let
    in {
      # Virtual machine options
      vbox = build_deriv_output "virtualbox" machine system [
        ./format_cfg/virtualbox.nix
      ];

      guivm = build_deriv_output "vm" machine system [
        ./format_cfg/virtualisation.nix
      ];

      clivm = build_deriv_output "vm-nogui" machine system [
        ./format_cfg/virtualisation.nix
      ];
    };

    build_machine_scripts = { name, ...}@machine: system: let
      derivs = build_machine_deriv machine system;
      pkgs = pkgsForSystem system;
    in {
      spawn.cli = simple_script pkgs "spawn_${name}_clivm" ''
        ${derivs.clivm}/bin/run-${name}-vm
      '';

      spawn.gui = simple_script pkgs "spawn_${name}_guivm" ''
        ${derivs.guivm}/bin/run-${name}-vm
      '';
    };

    build_machine_nixoscfg = { name, software, hardware ? null, add_modules ? [], ...}:
    system: nixpkgs.lib.nixosSystem {
      pkgs = pkgsForSystem system;
      inherit system;
      modules = [
        software
        { config.setup.is_nixos = true; }
      ] ++ (if builtins.isNull hardware then [] else [hardware])
      ++ (base_modules system) ++ add_modules;
    };

    declare_machines = system: machines: {
      packages = (builtins.listToAttrs (
        (builtins.map (machine: rec {
          name = machine.name;
          value = build_machine_deriv machine system;
        }) machines
      ))) // {
          nixosConfigurations = builtins.listToAttrs (
            builtins.map (machine: {
              name = machine.name;
              value = build_machine_nixoscfg machine system;
            }) machines
          );
      };

      apps = builtins.listToAttrs (
        (builtins.map (machine: rec {
          name = machine.name;
          value = build_machine_scripts machine system;
        }) machines
      ));
    };

  in inputs.flake-utils.lib.eachDefaultSystem (system: declare_machines system [
    {
      name="nixostest";
      software=./software/nixostest.nix;
    }

    {
      name="tyf";
      software=./software/company_server.nix;
      hardware=./hardware/suzie.nix;
    }

    {
      name="dumbo";
      software=./software/backup_server.nix;
    }
    {
      name="sparta";
      software=./software/personnal_computer.nix;
      hardware=./hardware/sparta.nix;
      add_modules = [
        inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h
      ];
    }
    # {
    #   name="diamond";
    #   software=./software/work_computer.nix;
    #   hardware=./hardware/diamond.nix;
    #   add_modules = [
    #     inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
    #   ];
    # }
  ]);
}
