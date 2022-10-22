{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  netw_lib = import ../lib/networking.nix {inherit config lib pkgs;};

  cfg = config.cmn.remote.gogs;
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

    assertions = [
      {
        assertion = (builtins.tryEval (netw_lib.IpFromString cfg.ipaddr)).success;
        message = "IP address not valid, please check cmn.remote.gogs.ipaddr config";
      }
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
    home_cfg.home.file.".gogs_token".text = ''${builtins.toString (libdata.load_token "gogs" config.networking.hostName)}'';
    cfg.environment = {
      variables.GOGS_SSH = "gogs@${cfg.name}";
      interactiveShellInit = ''
        new_gogs_repo(){
            REPO=$1
            TOK=$(cat $HOME/.gogs_token)
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
