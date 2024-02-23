{ config, lib, pkgs, ... }:
let
  cfg = config.software.tui.jrnl;
in {
  options.software.tui.jrnl = {
    opts_override = lib.mkOption {
      type = lib.types.attrs;
      description = "Options for Jrnl to manually set";
      default = {};
    };

    encrypt = lib.mkOption {
      type = lib.types.bool;
      description = "Wether to encrypt the journal or not";
      default = true;
    };

    add_journals = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Additional journals to add for usage";
      default = ["default"];
    };

    jrnl_paths = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/.local/share/jrnl";
      description = "Where to store the journal files";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      description = "Command to use for journal edition";
    };
  };
  config = {
    environment.systemPackages = [ pkgs.jrnl ];
    base.home_cfg.xdg.configFile."jrnl/jrnl.yaml".text = ''
      colors:
        body: none
        date: none
        tags: none
        title: none
      default_hour: 9
      default_minute: 0
      editor: '${cfg.editor}'
      encrypt: ${builtins.toString cfg.encrypt}
      highlight: true
      indent_character: '|'
      journals:
    '' + (builtins.foldl' (acc: name:
        acc + "  ${name}: ${cfg.jrnl_paths}/${name}.txt\n"
        ) "" cfg.add_journals) +
    ''
      linewrap: 100
      tagsymbols: '@'
      template: false
      timeformat: '%Y-%m-%d %H:%M'
      version: v2.8.3
    '';

    environment.interactiveShellInit = ''
      function djrnl {
        jrnl "$@" -1500 | less +G -r
      }
      complete -F _jrnl_autocomplete jrnl
      function _jrnl_autocomplete {
        COMPREPLY=($(compgen -W "$(jrnl --ls | grep "*" | awk '{print $2}')" -- "''${COMP_WORDS[COMP_CWORD]}"))
      }
      complete -F _djrnl_autocomplete djrnl
      function _djrnl_autocomplete {
        COMPREPLY=($(compgen -W "$(jrnl --ls | grep "*" | awk '{print $2}')" -- "''${COMP_WORDS[COMP_CWORD]}"))
      }
    '';
  };
}
