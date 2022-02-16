{
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
  };

  outputs = { self, nixpkgs, nixosgen, home-manager, envfs, nixos-hardware }:
  let
    find_all_files = dir: nixpkgs.lib.lists.flatten (
      (builtins.map find_all_files (list_elements dir "directory"))
      ++ (list_elements dir "regular")
    );

    list_elements = dir: type: map (f: dir + "/${f}") (
      nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs
          (_: entryType: entryType == type)
          (builtins.readDir  dir)
        )
      );

    # Additionnal modules
    base_modules = (find_all_files ./base) ++ [
      home-manager.nixosModules.home-manager
      {
        _module.args = {hmlib=home-manager.lib.hm;};
      }
      envfs.nixosModules.envfs
    ];

    # Common configuration added to scope, and enabled with a flag
    common_configs = find_all_files ./common;

    # Gets the base name of a file without the extension, from a path
    name_from_fname = fname :
      nixpkgs.lib.removeSuffix ".nix"
        (nixpkgs.lib.lists.last
          (nixpkgs.lib.strings.splitString "/"
            (builtins.toString fname)
        )
      );

    # Create output format derivation using nixos-generators
    build_deriv_output = { machine, system, add_modules, format}: nixosgen.nixosGenerate {
      pkgs = nixpkgs.legacyPackages."${system}" //
        (import ./overlays/overlays.nix nixpkgs.legacyPackages."${system}");
        modules = [ machine ] ++ common_configs ++ base_modules ++ add_modules;
      inherit format;
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = { machine, system, add_modules }: {
      # Target when updating a live NixOS system
      nixos_upt = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ machine ] ++ common_configs ++ base_modules ++ add_modules;
      };

      # All outputs format using nixos-generators
      vbox = build_deriv_output { inherit machine system;
        add_modules=add_modules ++ [ ./format_cfg/virtualbox.nix ];
        format="virtualbox";
      };

      clivm = build_deriv_output { inherit machine system;
        add_modules=add_modules ++ [ ./format_cfg/virtualisation.nix ];
        format="vm-nogui";
      };

      iso = build_deriv_output { inherit machine system add_modules; format="iso"; };
      sdraspi = build_deriv_output { inherit machine system add_modules; format="sd-aarch64"; };
      kvmcli = build_deriv_output { inherit machine system add_modules; format="kvmcli"; };
      iso-install = build_deriv_output { inherit machine system;
        add_modules = add_modules ++ [ ./format_cfg/iso-install-diskfmt.nix ];
        format="install-iso";
      };
    };

    # Build the derivation for each machine declared
    #   as a set in the form: { fname = ; system = ;}
    declare_machines = machines :
      builtins.listToAttrs (
        builtins.map (machine: {
          name = name_from_fname machine.fname;
          value = build_machine_deriv {
            machine = machine.fname;
            system = machine.system;
            add_modules = machine.add_modules or [];
          };
        }) machines
      );
  in
  declare_machines [
    { fname=./machines/nixostest.nix; system="x86_64-linux"; }
    # {
    #   fname=./machines/diamond.nix; system="x86_64-linux";
    #   add_modules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen ];
    # }
  ];
}
