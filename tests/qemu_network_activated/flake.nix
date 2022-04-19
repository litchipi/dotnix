{
  description = "NixOs VM with working network configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ...}@inputs: {
    vm  = inputs.nixosgen.nixosGenerate {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      format = "vm-nogui";
      modules = [ ./machine.nix ./nextcloud.nix ];
    };
  };
}
