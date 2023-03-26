{ config, lib, pkgs, ... }:
let
  cfg = config.software.tui.irssi;
in {
  options.software.tui.irssi = {
    extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Configuration to add at the bottom of the default one";
    };
    default_nick = lib.mkOption {
      type = lib.types.str;
      default = "nonickset";
      description = "The nickname to set by default";
    };
    theme = lib.mkOption {
      type = with lib.types; nullOr package;
      default = null;
      description = "Theme to apply";
    };
  };
  config = {
    environment.systemPackages = [ pkgs.irssi ];
    home-manager.users.${config.base.user} = {
      programs.irssi = {
        enable = true;
        extraConfig = cfg.extraConfig + ''
          settings = {
            core = {
              real_name = "${cfg.default_nick}";
              nick = "${cfg.default_nick}";
            };
            "fe-common/core" = { theme = "nixos"; };
          };
          keyboard = (
            { key = "meta-e"; id = "next_window"; data = ""; },
            { key = "meta-a"; id = "previous_window"; data=""; }
          );
        '';
        networks = {
          libera = {
            nick = cfg.default_nick;
            server = {
              address = "irc.libera.chat";
              port = 6697;
            };
            # TODO    Create new secret file with the secret embedded in it
            #   Create an alias that uses the secret file with the config
            #
            # autoCommands = if builtins.hasAttr "libera_${cfg.default_nick}" libdata.plain_secrets.irssi
            # then [
            #   "/msg NickServ identify ${cfg.default_nick} ${
            #     libdata.plain_secrets.irssi."libera_${cfg.default_nick}"
            #   }"
            # ] else [];
          };
        };
      };
      home.file = lib.mkIf (!builtins.isNull cfg.theme) {
        ".irssi/startup".source = "${cfg.theme}/startup";
        ".irssi/scripts".source = "${cfg.theme}/scripts";
        ".irssi/nixos.theme".source = "${cfg.theme}/nixos.theme";
      };
    };
  };
}
