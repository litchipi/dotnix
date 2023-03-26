{ inputs, lib, pkgs, ...}: rec {
  simple_script = name: text: {
    type = "app";
    program = let
      exec = pkgs.writeShellScript name text;
    in "${exec}";
  };

  # Create output format derivation using nixos-generators
  build_deriv_output = base_modules: format: { software, hardware ? null, add_modules ? [], ...}:
    system: format_modules: inputs.nixosgen.nixosGenerate {
      inherit pkgs format;
      modules = [ software ] ++ (if builtins.isNull hardware then [] else [hardware])
        ++ (base_modules system) ++ add_modules ++ format_modules;
      };

  mkTargetPackages = base_modules: machine: system: {
    # Virtual machine options
    vbox = build_deriv_output base_modules "virtualbox" machine system [
      ../format_cfg/virtualbox.nix
    ];

    guivm = build_deriv_output base_modules "vm" machine system [
      ../format_cfg/virtualisation.nix
    ];

    clivm = build_deriv_output base_modules "vm-nogui" machine system [
      ../format_cfg/virtualisation.nix
      ../format_cfg/nogui.nix
    ];
  };

  mkNixosSystem = base_modules: { software, hardware ? null, add_modules ? [], ...}: system: inputs.nixpkgs.lib.nixosSystem {
    inherit system pkgs;
    modules = [
      software
      { config.setup.is_nixos = true; }
    ] ++ (if builtins.isNull hardware then [] else [hardware])
    ++ (base_modules system) ++ add_modules;
  };

  mkTargetApps = base_modules: { name, ...}@machine: system: let
    derivs = mkTargetPackages base_modules machine system;
  in {
    spawn.cli = simple_script "spawn_${name}_clivm" ''
      ${derivs.clivm}/bin/run-${name}-vm
    '';

    spawn.gui = simple_script "spawn_${name}_guivm" ''
      ${derivs.guivm}/bin/run-${name}-vm
    '';
  };

  mkAllTargetApps = base_modules: targets: system: builtins.mapAttrs (
    name: machine: mkTargetApps base_modules (machine // { inherit name; }) system
  ) targets;

  mkAllTargetPackages = base_modules: targets: system: (builtins.mapAttrs (
    name: machine: mkTargetPackages base_modules (machine // { inherit name; }) system
  ) targets) // { nixosConfigurations = mkAllNixosSystems base_modules targets system; };

  mkAllNixosSystems = base_modules: targets: system: builtins.mapAttrs (
    name: machine: mkNixosSystem base_modules (machine // { inherit name; }) system
  ) targets;
}
