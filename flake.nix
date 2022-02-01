{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixosgen }: 
  let
    list_files = dir: map (f: dir + "/${f}") (nixpkgs.lib.attrNames (
      nixpkgs.lib.filterAttrs
        (_: entryType: entryType == "regular")
        (builtins.readDir dir)
    ));

    # Additionnal modules
    base_modules = [
    ];

    # Common configuration added to scope, and enabled with a flag
    common_configs = [
      ./base/base.nix
    ] ++ (list_files ./common);

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
      pkgs = nixpkgs.legacyPackages."${system}";
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
      vbox = build_deriv_output { inherit machine system add_modules; format="virtualbox"; };
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
            add_modules = if builtins.hasAttr "add_modules" machine
              then machine.add_modules
              else [];
          };
        }) machines
      );
  in
  declare_machines [
    { fname=./machines/nixostest.nix; system="x86_64-linux"; }
  ];
}
