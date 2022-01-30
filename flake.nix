{
  description = "NixOs config builder";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixosgen = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixosgen }: 
  let
    # Common configuration added to scope, and enabled with a flag
    common_configs = [
      ./base/base.nix
      ./common/gnome.nix
      ./common/server.nix
      ./common/infosec.nix
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
    build_deriv_output = { machine, system, format} : nixosgen.nixosGenerate {
      pkgs = nixpkgs.legacyPackages."${system}";
      modules = [ machine ] ++ common_configs;
      inherit format;
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = machine: system: {
      # Target when updating a live NixOS system
      nixos_upt = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ machine ] ++ common_configs;
      };

      # All outputs format using nixos-generators
      vbox = build_deriv_output { inherit machine system; format="virtualbox"; };
      iso = build_deriv_output { inherit machine system; format="iso"; };
      sdraspi = build_deriv_output { inherit machine system; format="sd-aarch64"; };
      kvmcli = build_deriv_output { inherit machine system; format="kvmcli"; };
      iso-install = build_deriv_output { inherit machine system; format="install-iso"; };
    };

    # Build the derivation for each machine declared
    #   as a set in the form: { fname = ; system = ;}
    declare_machines = machines :
      builtins.listToAttrs (
        builtins.map (machine: {
          name = name_from_fname machine.fname;
          value = build_machine_deriv machine.fname machine.system;
        }) machines
      );
  in
  declare_machines [
    { fname=./machines/nixostest.nix; system="x86_64-linux"; }
  ];
}
