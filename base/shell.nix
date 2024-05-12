{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  shellPackages = {
    bash = pkgs.bashInteractive;
  };
in
  {
  options.base.shell = {
    shellBin = lib.mkOption {
      type = lib.types.str;
      description = "The shell to use for anything in the system";
      default = "bash";
    };

    ps1.add_hostname = lib.mkOption {
      type = lib.types.bool;
      description = "Allow hostname to appear on PS1";
      default = false;
    };
  };

  config = {
    users.users.${config.base.user}.shell = shellPackages.${config.base.shell.shellBin};
    base.home_cfg = {
      programs.bash = {
        enable = (config.base.shell.shellBin == "bash");
        sessionVariables.COLORTERM="truecolor";
        initExtra = let
          ps1 = builtins.concatStringsSep " " [
            ("${colors.fg.ps1.username}\\u"
              + (if config.base.shell.ps1.add_hostname
                then "${colors.reset}@${colors.fg.ps1.hostname}\\h"
                else "")
            )
            "${colors.fg.ps1.wdir}\\w"
            ''\[${colors.fg.ps1.gitps1}\]\`__git_ps1 \"<%s> \"\`''
            "${colors.fg.ps1.dollarsign}$"
            "${colors.reset}"
          ];
        in ''
          source ${libdata.get_data_path [ "shell" "git-prompt.sh" ]}
          export PS1="${ps1}"
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      util-linux
      vim
      wget
      lshw
    ];
  };
}
