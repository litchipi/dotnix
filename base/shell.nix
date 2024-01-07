{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  shellPackages = {
    bash = pkgs.bashInteractive;
  };
in
  {
  options.base.shell = lib.mkOption {
    type = lib.types.str;
    description = "The shell to use for anything in the system";
    default = "bash";
  };

  config = {
    users.users.${config.base.user}.shell = shellPackages.${config.base.shell};
    base.home_cfg = {
      programs.bash = {
        enable = (config.base.shell == "bash");
        sessionVariables.COLORTERM="truecolor";
        initExtra = ''
          source ${libdata.get_data_path [ "shell" "git-prompt.sh" ]}
          export PS1="\[${colors.fg.ps1.username}\]\\u \[${colors.fg.ps1.wdir}\]\\w '' +
          ''\[${colors.fg.ps1.gitps1}\]\`__git_ps1 \"<%s> \"\`'' +
          ''\[${colors.fg.ps1.dollarsign}\]$ \[${colors.reset}\]"
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
