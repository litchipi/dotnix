{
  description = "NixOs config builder";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixosgen = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, nixosgen }: 
  let
    # Create output format derivation using nixos-generators
    build_deriv_output = { machine, system, format } : nixosgen.nixosGenerate {
      pkgs = nixpkgs.legacyPackages."${system}";
      modules = [
        (./machines + "/${machine}.nix")
      ];
      format="${format}";
    };

    # Create entire NixOS derivation for a machine
    build_machine_deriv = { machine, system } : {
      # Target when updating a live NixOS system
      nixos_upt = nixpkgs.lib.nixosSystem {
        system="${system}";
        modules = [
          (./machines + "/${machine}.nix")
        ];
      };

      # All outputs format using nixos-generators
      vbox = build_deriv_output { machine=machine; system=system; format="virtualbox";};
      iso = build_deriv_output { machine=machine; system=system; format="iso";};
      sdraspi = build_deriv_output { machine=machine; system=system; format="sd-aarch64";};
      kvmcli = build_deriv_output { machine=machine; system=system; format="vm-nogui";};
      iso-install = build_deriv_output { machine=machine; system=system; format="install-iso";};
    };

  # Machine definitions are located in `all_machines.nix`
  in import ./all_machines.nix build_machine_deriv;
}
