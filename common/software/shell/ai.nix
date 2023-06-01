{ pkgs, lib, config, ... }: let
  cfg = config.software.shell.ai;
in {
  options.software.shell.ai = {
    token_secret = lib.mkOption {
      type = lib.types.str;
      description = "Path to the file containing the token for OpenAI API";
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      mods
    ];
    environment.interactiveShellInit=''
      export OPENAI_API_KEY=$(cat ${cfg.token_secret})
    '';
  };
}
