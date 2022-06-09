{ config, lib, pkgs, ... }:
let
  cfg = config.base.shell;
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};
in
{
  options.base.shell = {
    shellPackage = lib.mkOption {
      type = lib.types.package;
      description = "The shell to use for anything in the system";
      default = pkgs.bashInteractive;
    };
  };

  config = {
    users.users.${config.base.user}.shell = cfg.shellPackage;
    home-manager.users.${config.base.user} = {
      programs.bash = lib.mkIf ((lib.strings.getName cfg.shellPackage) == "bash-interactive") {
        sessionVariables.COLORTERM="truecolor";
        initExtra = ''
          source ${libdata.get_data_path [ "shell" "git-prompt.sh" ]}
          export PS1="${colors.fg.ps1.username}\\u ${colors.fg.ps1.wdir}\\w '' +
          (if config.cmn.software.tui.git.enable
            then config.cmn.software.tui.git.ps1
            else ""
          ) + ''${colors.fg.ps1.dollarsign}$ ${colors.reset}"
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
