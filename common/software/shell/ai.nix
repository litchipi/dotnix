{ pkgs, lib, config, ... }: let
  cfg = config.software.shell.ai;
in {
  options.software.shell.ai = {
    token = lib.mkOption {
      type = lib.types.attrs;
      description = "Secret token for OpenAI services";
    };
  };

  config = {
    secrets.setup.openai_token = {
      secret = cfg.token;
      user = config.base.user;
    };
    environment.systemPackages = with pkgs; [
      mods
    ];
    environment.interactiveShellInit=''
      export OPENAI_API_KEY=$(cat ${cfg.token.file})
    '';
  };
}
