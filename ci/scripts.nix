{ pkgs, system, build_machine_deriv, simple_script, find_all_files, machines, ...}: let
  get_all_ci_scripts = gui: files: builtins.map (f: let
    conf = {
      name = "ci_${if gui then "gui" else "cli"}_${builtins.baseNameOf f}";
      software = import f machines;
      add_modules = [ ./common.nix ];
    };
  in ''
    echo "${conf.name}: ${(build_machine_deriv conf system).${if gui then "guivm" else "clivm"}}"
  '') files;
  all_ci_gui_scripts = get_all_ci_scripts true (find_all_files ./gui);
  all_ci_cli_scripts = get_all_ci_scripts false (find_all_files ./cli);
  all_ci_scripts = all_ci_gui_scripts ++ all_ci_cli_scripts;
in simple_script pkgs "dotnix_ci" (builtins.concatStringsSep "\n" all_ci_scripts)
