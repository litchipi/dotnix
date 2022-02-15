{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.commonconf.remote.gogs;
in
conf_lib.create_common_confs [
  {
    name = "gogs";
    parents = [ "remote" ];

    add_opts = {
      ipaddr = lib.mkOption {
        type = with lib.types; str;
        description = "Address IP of the Gogs server";
        default = "";
      };

      name = lib.mkOption {
        type = with lib.types; str;
        description = "Name of the Gogs server";
        default = "gogs_srv";
      };
    };

    # TODO Check is the correct IP format
    assertions = [
      { assertion = cfg.ipaddr != ""; message = "You have to set the IP address";}
    ];

    cfg = {
      networking.extraHosts = ''
        ${cfg.ipaddr} ${cfg.name}
      '';
    };
    add_pkgs = with pkgs; [
      git
      curl
    ];
    home_cfg.home.file.".gogs_token".text = ''${builtins.toString (data_lib.load_token "gogs" config.networking.hostName)}'';
    home_cfg.programs.bash = {
      enable = true;
      initExtra = ''
        GOGS_SSH="gogs@${cfg.name}"
        new_gogs_repo(){
            REPO=$1
            TOK=$(cat $HOME/gogs_token)
            URL="http://${cfg.name}:3000/api/v1"
            REQ="{\"name\":\"''${REPO}\"}"
            RES=$(curl \
              -H "Content-Type: application/json" \
              -H "Authorization: token ''${TOK}" \
              -d "''${REQ}" \
              ''${URL}/user/repos 2>/dev/null)
            echo "$RES" | grep "_url" | grep -v "avatar"
        }

        add_gogs_remote(){
            URL="$GOGS_SSH:litchipi/$1.git"
            if git remote | grep "gogs" 1>/dev/null; then
                git remote set-url gogs "$URL"
            else
                git remote add gogs "$URL"
            fi
            git push -u --all gogs
        }
      '';
      shellAliases = {
        update_gogs_url = ''git remote set-url gogs $GOGS_SSH:"'$(git remote -v | grep push | grep gogs | awk '"'{"'print $2'"}'"' | cut -d ':' -f 2)'';
      };
    };
  }
]
