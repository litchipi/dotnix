{
  # TODO  Create flake template from this
  #     Flake with only the script declaration, formats on nixos-generators,
  #     deployment with NixOps, and format-specific configuration set.
  #     No NixOS machine configuration given except one of example, no "library" made
  #     Fully commented

  # TODO  Create NixOS template from this
  #     Basic NixOS system (without complicated overlays)
  #     Having home-manager and secrets management set up
  #     Fully commented

  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    envfs.url = "github:Mic92/envfs";
    envfs.inputs.nixpkgs.follows = "nixpkgs";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    StevenBlackHosts.url = "github:StevenBlack/hosts";

    # Overlays
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, ...}@inputs:
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
    pkgsForSystem = system: import nixpkgs {
      overlays = [
        inputs.rust-overlay.overlay
        (prev: final: (import ./overlays/overlays.nix final))
      ];
      config.allowUnfree = true;
      inherit system;
    };

    declare_script = { name, script, env ? [], add_pkgs ? pkgs: [], system }: {
      type = "app";
      program = let
        pkgs = pkgsForSystem system;
        add_paths = builtins.map (pkg:
          "${pkg}/bin:${pkg}/sbin"
        ) (add_pkgs pkgs);
        exec = pkgs.writeShellScriptBin name (pkgs.lib.debug.traceValSeq ((
          pkgs.lib.strings.optionalString ((builtins.length add_paths) > 0)
          ''
            # Script ${name} defined in flake ${self}
            set -e
            ${builtins.concatStringsSep "\n" env}
            PATH=${builtins.concatStringsSep ":" add_paths}:$PATH
          ''
        ) + script));
      in
      "${exec}/bin/${name}";
    };

  # Building
    # Additionnal modules for any nixos configuration
    base_modules = (find_all_files ./base) ++ (find_all_files ./common) ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.StevenBlackHosts.nixosModule
      inputs.envfs.nixosModules.envfs
      {
        _module.args = {
          inherit inputs;
          extra = {};
        };

      }
    ];

    # Gets the base name of a file without the extension, from a path
    name_from_fname = fname :
      nixpkgs.lib.removeSuffix ".nix"
        (nixpkgs.lib.lists.last
          (nixpkgs.lib.strings.splitString "/"
            (builtins.toString fname)
        )
      );

    # Create output format derivation using nixos-generators
    build_deriv_output = { fname, system, add_modules, format}: inputs.nixosgen.nixosGenerate {
        pkgs = pkgsForSystem system;
        modules = [ fname ] ++ base_modules ++ add_modules;
      inherit format;
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = name: { fname, system, add_modules ? [], ...}: rec {
      # Installation ISO formats
      iso-install = build_deriv_output {    # Bootable ISO
        inherit system fname;
        add_modules = add_modules ++ [
          ./format_cfg/iso-install-diskfmt.nix
          ./format_cfg/iso-install-installscript.nix
        ];
        format="install-iso";
      };

      iso = build_deriv_output {    # Live ISO (can be used for servers)
        inherit system fname;
        add_modules = add_modules ++ [];
        format = "iso";
      };

      # Virtual machine options
      vbox = build_deriv_output {
        inherit system fname;
        add_modules=add_modules ++ [ ./format_cfg/virtualbox.nix ];
        format="virtualbox";
      };

      vm = build_deriv_output {
        inherit system fname;
        add_modules=add_modules ++ [ ./format_cfg/virtualisation.nix ];
        format="vm";
      };

      clivm = build_deriv_output {
        inherit system fname;
        add_modules=add_modules ++ [ ./format_cfg/virtualisation.nix ];
        format="vm-nogui";
      };

      spawn = declare_script {
        inherit system;
        name = "${name}-clivm-spawn";
        script = ''
          ${clivm}/bin/run-*-vm
        '';
      };
    };

    # Target used by the installed NixOS system to rebuild the system
    generate_nixos_configuration = machines: {
      nixosConfigurations = builtins.listToAttrs (
        (builtins.map ({fname, system, add_modules ? [], ...}: {
          name = name_from_fname fname;
          value = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [ fname ./configuration.nix ] ++ base_modules ++ add_modules;
          };
        })
        machines)
        );
      };

    # Build the derivation for each machine declared
    #   as a set in the form: { fname = ; system = ;}
    declare_machines = machines :
      (builtins.listToAttrs (
        (builtins.map (machine: rec {
          name = name_from_fname machine.fname;
          value = build_machine_deriv name machine;
        }) machines
      ))) // (generate_nixos_configuration machines);

    generate_outputs = {machines ? [], extra ? {}, devShell ? {}}:
    (declare_machines machines)
      // extra
      // {
        inherit devShell;
      };
  in
  generate_outputs {
    machines = [
      {
        fname=./machines/nixostest.nix;
        system="x86_64-linux";
      }

      {
        fname=./machines/company_server.nix;
        system="x86_64-linux";
      }

      {
        fname=./machines/backup_server.nix;
        system="x86_64-linux";
      }
      # {
      #   fname=./machines/diamond.nix;
      #   system="x86_64-linux";
      #   add_modules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen ];
      # }
    ];
    extra = {
    };
    devShell = {
      x86_64-linux = (pkgsForSystem "x86_64-linux").mkShell {
      };
    };
  };
}
