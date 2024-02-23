{ pkgs, lib, config, ... }: let
  cfg = config.software.shell.ai;
in {
  options.software.shell.ai = {
  };

  config = {
    environment.systemPackages = with pkgs; [
      mods
    ];
    # environment.interactiveShellInit=''
    #   export OPENAI_API_KEY=$(cat ${cfg.token.file})
    # '';
  };
}
