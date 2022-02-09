{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    nixpkgs-wayland.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-wayland.inputs.master.follows = "master";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixosgen, home-manager, nixpkgs-wayland }:
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
    ];

    # Common configuration added to scope, and enabled with a flag
    common_configs = find_all_files ./common;

    # Modules that require to be imported in this scope to work
    imported_modules = system: builtins.map (path: import path system {inherit nixpkgs home-manager nixpkgs-wayland;}) [
        ./modules/nixpkgs-wayland.nix
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
    build_deriv_output = { machine, system, add_modules, format}: nixosgen.nixosGenerate {
      pkgs = nixpkgs.legacyPackages."${system}" //
        (import ./overlays/overlays.nix nixpkgs.legacyPackages."${system}");
        modules = [ machine ] ++ common_configs ++ base_modules ++ add_modules ++ (imported_modules system);
      inherit format;
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = { machine, system, add_modules }: {
      # Target when updating a live NixOS system
      nixos_upt = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ machine ] ++ common_configs ++ base_modules ++ add_modules ++ (imported_modules system);
      };

      # All outputs format using nixos-generators
      vbox = build_deriv_output { inherit machine system;
        add_modules=add_modules ++ [ ./format_cfg/virtualbox.nix ];
        format="virtualbox";
      };
      iso = build_deriv_output { inherit machine system add_modules; format="iso"; };
      sdraspi = build_deriv_output { inherit machine system add_modules; format="sd-aarch64"; };
      kvmcli = build_deriv_output { inherit machine system add_modules; format="kvmcli"; };
      iso-install = build_deriv_output { inherit machine system add_modules; format="install-iso"; };
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
  ];
}
