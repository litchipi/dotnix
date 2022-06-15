{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};

  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg = config.cmn.shell.aliases;
  cfg_memory = cfg.memory;
in
conf_lib.create_common_confs [
  {
    name = "filesystem";
    minimal.cli = true;
    default_enabled = true;
    parents = [ "shell" "aliases" ];
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        tmpdir = "cd $(mktemp -d)";

        ".." = "cd .. && ls";
        "..." = "cd ../../ && ls ";
        "...." = "cd ../../../ && ls";

        lh = "ls -lh";
        lha = "ls -lah";
        ll = "ls -l";
        la = "ls -a";
        lla = "ls -la";
        
        grep="grep --color=auto";
      };
    };
  }

  {
    name = "git";
    parents = [ "shell" "aliases" ];
    minimal.cli = true;
    add_pkgs = with pkgs; [
      git
    ];
    home_cfg.programs.bash = {
      enable = true;
      initExtra = ''
        source ${libdata.get_data_path [ "shell" "git-completion" ]}
        __git_complete gbc _git_branch
        __git_complete gbd _git_branch
        __git_complete gck _git_checkout
        __git_complete gl git_log
        __git_complete gla git_log
        __git_complete gdf _git_branch
        __git_complete grh  _git_reset
        __git_complete gpsh _git_push
        __git_complete gpl _git_pull
        __git_complete gpshu _git_push
        __git_complete gcp  _git_cherry_pick
        __git_complete grm  _git_reset
        
        function gpshu() {
            git push -u $1 $(git branch --show-current)
        }
        function __get_current_branch() {
                git branch |grep "*"| cut -d " " -f 2
        }
        function gkeep() {
            name="$(__get_current_branch).$(git rev-parse --short HEAD)"
            git branch "$name" 2>/dev/null
            echo "$name"
        }
        function gsave() {
                if [ $# -ne 1 ] ; then
                        echo "Usage: $0 <branch name>. Will create a temporary commit and checkout to the given branch"
                        exit 1;
                fi
                git add . && git commit -m "TMP COMMIT" && git checkout $1
        }
        __git_complete gsave _git_checkout
        function gload() {
                if [ $# -ne 1 ] ; then
                        echo "Usage: $0 <branch name>. Will create a temporary commit and checkout to the given branch"
                        exit 1;
                fi
                git checkout $1 && git reset --mixed HEAD~1
        }
        __git_complete gload _git_checkout
        
        function __gh() {
                echo -e "${colors.fg.primary} $1:   ${colors.reset} $2"
        }

        function ghelp() {
                echo "Aliases defined for git:"
                echo ""
                __gh "ga" "Add everything to repo"
                __gh "gcm" "Commit signed with a message (arg: message)"
                __gh "gts" "Get status of repository"
                __gh "gpl" "Pull changes from the remote repository"
                __gh "gpsh" "Push the repository to remote"
                __gh "gpsh_allremote" "Push the repository to all known remote in the repository"
                __gh "gitclean" "Clean the repository, garbage collect, prune"
                echo ""
                __gh "gb" "List the local branches"
                __gh "gba" "List all the branches"
                __gh "gbc" "Create a new branch if doesn't exist, checkout on it"
                __gh "gbd" "Delete a branch"
                __gh "gck" "Checkout to a branch"
                echo ""
                __gh "gl" "Commit log of current branch"
                __gh "gla" "Commit log of every branches"
                __gh "gdf" "Print the diff since last commit"
                __gh "grs" "Remove file from staged state"
                echo ""
                __gh "grh" "Reset HARD the branch to a given ref (default: HEAD)"
                __gh "grm" "Reset MIXED the branch to a given ref (default: HEAD)"
                __gh "gcp" "Cherry pick a commit from the given ref"
                echo ""
                __gh "gg" "Starts git gui in the background"
                __gh "ggk" "Starts git gui with gitk, both in background"
                __gh "gitka" "Starts gitk for with all branches displayed"
                __gh "ggka" "Starts git gui with gitka, both in background"
                echo ""
                __gh "gkeep" " Create a temporary branch on the given commit to keep the ref"
                __gh "gsave" "Create a temporary commit with the ongoing changes, and checkout the given branch"
                __gh "gload" "Checkout the given branch, and restore the last commit made into ongoing changes"
                echo ""
        }

      '';
      shellAliases = {
        ga="git add .";
        gcm="git commit -s -m";
        gca="git commit --amend";
        gts="git status";
        gitclean="git fetch -p && git gc --prune=now";

        gb="git branch";
        gba="git branch --list --all";
        gbc="git checkout -B ";
        gbd="git branch -D";

        gck="git checkout";

        gl="git log --oneline -30";
        gla="gl --all";

        gdf="git diff --staged && echo -e '\n\n\n\n' && git diff";
        grs="git restore --staged";

        grh="git reset --hard";
        grm="git reset --mixed";
        gcp="git cherry-pick";

        gpsh="git push";
        gpl="git pull";
        gpsh_allremote=''for remote in $(git remote); do echo -e "\033[96;1mPushing to $remote\033[0m"; git push "$remote"; echo -e "\n"; done'';

        gg="git gui &";
        gitka="gitk --all --max-count=5000";
        ggk="git gui & gitk &";
        ggka="git gui & gitka &";
      };
    };
  }

  {
    name = "music";
    parents = [ "shell" "aliases" ];
    add_opts = {
      music_dir = lib.mkOption {
        type = lib.types.str;
        default = "Music";
        description = "Directory in \$HOME where to download music";
      };
    };
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = let
        ytdl_args = "-x --add-metadata -o '${config.xdg.dirs.music}/%(title)s.%(ext)s'";
      in
      rec {
        dl_mp3="youtube-dl ${ytdl_args} --audio-format mp3";
        dl_mp3_hq="${dl_mp3} --audio-quality 0";
        dl_search_mp3="${dl_mp3} --default-search \"ytsearch\"";
        dl_search_mp3_hq="${dl_mp3_hq} --default-search \"ytsearch\"";

        dl_flac="youtube-dl ${ytdl_args} --audio-format flac";
        dl_flac_hq="${dl_flac} --audio-quality 0";
        dl_search_flac="${dl_flac} --default-search \"ytsearch\"";
        dl_search_flac_hq="${dl_flac_hq} --default-search \"ytsearch\"";

        # defaults
        zik="${dl_mp3_hq}";
        ziksearch="${dl_search_mp3_hq}";
      };
    };
  }

  {
    name = "network";
    default_enabled=true;
    minimal.cli = true;
    parents = [ "shell" "aliases" ];
    add_opts = {
      pingtest_website = lib.mkOption {
        type = lib.types.str;
        default = "8.8.8.8";
        description = "Website to ping for internet connection test";
      };
    };
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        pingt=''ping -c 1 -W 1 ${cfg.network.pingtest_website} '' +
          ''1> /dev/null 2> /dev/null && echo -e "${colors.fg.ok}Connected${colors.reset}" '' +
          ''|| echo -e "${colors.fg.bad}No connection${colors.reset}" '';
      };
    };
  }

  {
    name = "nix";
    default_enabled = true;
    minimal.cli = true;
    parents = [ "shell" "aliases" ];
    add_opts = {
      nix_shells_dir = lib.mkOption {
        type = lib.types.str;
        default = ".nix_shells";
        description = "Where to store nix shells";
      };
    };
    home_cfg.programs.bash = {
      enable = true;
      sessionVariables = {
        NIX_SHELLS_DIR="$HOME/${cfg.nix.nix_shells_dir}";
      };

      initExtra = '' 
        NIX_SHELL_TEMPLATE='{
          description = "DESCRIPTION_HERE";
          inputs.flake-utils.url = "github:numtide/flake-utils";
          nixConfig.bash-prompt = "${colors.fg.ps1.username}\\u ${colors.fg.ps1.wdir}\\w ${colors.fg.ps1.gitps1}\`__git_ps1 \<%s\>\` ${colors.fg.ps1.dollarsign}\$ ${colors.reset}";
          outputs = { self, nixpkgs, flake-utils }:
            flake-utils.lib.eachDefaultSystem
              (system:
              let
                pkgs = nixpkgs.legacyPackages.\''\${system};
                project_root = START_DIRECTORY;
              in
                {
                  devShell = pkgs.mkShell {
                    shellHook = ''\''cd \"\''\${toString project_root }\"''\'';
                    buildInputs = with pkgs; [ PACKAGE_LIST ];
                  };
                }
              );
        }'

        mkdir -p $NIX_SHELLS_DIR
        if [ ! -d $NIX_SHELLS_DIR/.git ]; then
            cd $NIX_SHELLS_DIR
            git init 1>/dev/null 2>/dev/null
            cd - 1>/dev/null 2>/dev/null
        fi

        function nxshell() {
          nix shell nixpkgs#$1
        }

        function _nixfiles() {
            COMPREPLY=($(compgen -W "$(ls *.nix)" -- "$${COMP_WORDS[COMP_CWORD]}"))
        }

        complete -F _nixfiles nix_refbuild
        function nix_refbuild() {
                nix-store -q --references $(nix-instantiate $1)
        }

        complete -F _nixfiles nix_refrun
        function nix_refrun() {
                drvfile=$(nix-instantiate $1)
                nix-store -q --references $(nix-store -r $drvfile)
        }

        function nxnewdevshell() {
            if [ $# -lt 3 ]; then
                echo "Missing parameter: <name> <start directory> <description> [<package> <package> ...]"
                return;
            fi
            if [ ! -d $2 ]; then
                echo "Directory $2 does not exist"
                return;
            fi
            name=$1
            start_dir=$(realpath $2)
            descr=$3
            shift 3
            mkdir -p $NIX_SHELLS_DIR/$name
            cd $NIX_SHELLS_DIR
            if [ ! -d $NIX_SHELLS_DIR/.git ]; then
                git init 1>/dev/null 2>/dev/null
                git add . 1>/dev/null 2>/dev/null
                git commit -m "Initial commit" 1>/dev/null 2>/dev/null
            fi

            template=$NIX_SHELL_TEMPLATE
            template=$${template//PROJECT_NAME/$name}
            template=$${template//DESCRIPTION_HERE/$descr}
            template=$${template//START_DIRECTORY/$start_dir}
            template=$${template//PACKAGE_LIST/$( echo $@ | tr ' ' '\n')}
            if [ -z $(which nixpkgs-fmt) ]; then
                echo "Installing \"nixpkgs-fmt\"..."
                nix-env -i nixpkgs-fmt
            fi
            echo "$template" | nixpkgs-fmt > $NIX_SHELLS_DIR/$name/flake.nix
            git add $name/ 1>/dev/null 2>/dev/null
            git commit -m "Modify $name shell" 1>/dev/null 2>/dev/null
            cd - 1>/dev/null 2>/dev/null
            echo "Written to $NIX_SHELLS_DIR/$name/flake.nix"
            echo "Use \"nxdevshell $name\" to start shell"
        }

        function nxdevshell() {
            if [ $# -lt 1 ]; then
                echo "Usage: nxdevshell <shell name>"
                return;
            fi
            if [ ! -d $NIX_SHELLS_DIR/$1 ]; then
                echo "Shell $1 not set, set it up in $NIX_SHELLS_DIR/$1 dir"
                return;
            fi
            d=$(pwd)
            cd $NIX_SHELLS_DIR/$1
            shift 1;
            clear
            nix develop $@
            cd - 1>/dev/null 2>/dev/null
        }

        complete -F _nxdevshell_autocomplete nxdevshell
        function _nxdevshell_autocomplete {
            if [ $COMP_CWORD -gt 1 ]; then
                return;
            fi
            # Ensure that the directory exist before trying to autocomplete
            COMPREPLY=($(compgen -W "$(for d in $(ls $NIX_SHELLS_DIR/); do if [ -f $NIX_SHELLS_DIR/$d/flake.nix ]; then echo "$d"; fi; done)" -- "$${COMP_WORDS[COMP_CWORD]}"))
        }

        function nxedit() {
            if [ $# -lt 1 ]; then
                echo "Usage: nxedit <shell name>"
                return
            fi
            nvim $NIX_SHELLS_DIR/$1/flake.nix
            cd $NIX_SHELLS_DIR
            git add $1/ 1>/dev/null 2>/dev/null
            git commit -m "Manually edited $name shell" 1>/dev/null 2>/dev/null
            cd - 1>/dev/null 2>/dev/null
        }
        complete -F _nxdevshell_autocomplete nxedit
      '';
    };
  }
  
  {
    name = "fzf";
    default_enabled = true;
    minimal.cli = true;
    parents = [ "shell" "aliases" ];
    add_pkgs = with pkgs; [
      fzf
    ];
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        fnvim = "nvim $(fzf)";
      };
    };
  }
  
  {
    name = "jrnl";
    default_enabled = true;
    parents = [ "shell" "aliases" ];
    home_cfg.programs.bash = {
      enable = true;
      initExtra = ''
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

  {
    name = "memory";
    parents = [ "shell" "aliases" ];
    add_opts = {
      bck_dir = lib.mkOption {
        type = lib.types.str;
        default = ".backup";
        description = "Where to store memory backups";
      };
      backup_medias = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Paths to media where to copy the backups";
      };
    };
    add_pkgs = with pkgs; [
      litchipi.memory
    ];
    home_cfg.home.file = {
      "${cfg_memory.bck_dir}/locations.mk".text = ''
        SAVE_MEDIA = ""
      '' + (lib.strings.concatStringsSep "\n" (builtins.map (media:
        "SAVE_MEDIA += \"${media}\""
        ) cfg_memory.backup_medias));
    } // (libdata.copy_files_in_home [
      { home_path = "${cfg_memory.bck_dir}/Makefile"; asset_path = [ "shell" "memory_makefile" ]; }
    ]);
    home_cfg.programs.bash = {
      enable = true;
      initExtra = ''
        complete -F _memory_autocomplete memory
        function _memory_autocomplete {
            COMPREPLY=($(compgen -W "$(memory ls -n)" -- "''${COMP_WORDS[COMP_CWORD]}"))
        }
      '';
      shellAliases = {
        backup = "memory all && cd $HOME/${cfg_memory.bck_dir} && make -j$(nproc) && cd -";
      };
    };
  }
]
