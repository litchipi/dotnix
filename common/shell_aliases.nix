{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};

  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg_memory = config.commonconf.shell.aliases.memory;
in
conf_lib.create_common_confs [
  {
    name = "filesystem";
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
    add_pkgs = with pkgs; [
      git
    ];
    home_cfg.programs.bash = {
      enable = true;
      initExtra = (data_lib.read_data [ "shell" "git-completion" ]) + ''
        __git_complete gbc _git_branch
        __git_complete gbd _git_branch
        __git_complete gck _git_checkout
        __git_complete gl git_log
        __git_complete gla git_log
        __git_complete gdf _git_branch
        __git_complete grh  _git_reset
        __git_complete gpsh _git_push
        __git_complete gpsh _git_push
        __git_complete gcp  _git_cherry_pick
        __git_complete grm  _git_reset
        
        function __gpsh_u() {
            git push -u $1 $(git branch --show-current)
        }
        function __get_current_branch() {
                git branch |grep "*"| cut -d " " -f 2
        }
        function __gkeep() {
            name="$(__get_current_branch).$(git rev-parse --short HEAD)"
            git branch "$name" 2>/dev/null
            echo "$name"
        }
        function __gsave() {
                if [ $# -ne 1 ] ; then
                        echo "Usage: $0 <branch name>. Will create a temporary commit and checkout to the given branch"
                        exit 1;
                fi
                git add . && git commit -m "TMP COMMIT" && git checkout $1
        }
        __git_complete gsave _git_checkout
        function __gload() {
                if [ $# -ne 1 ] ; then
                        echo "Usage: $0 <branch name>. Will create a temporary commit and checkout to the given branch"
                        exit 1;
                fi
                git checkout $1 && git reset --mixed HEAD~1
        }
        __git_complete gload _git_checkout
        
        function __gh() {
                echo -e "${colors.primary_color} $1:   ${colors.reset} $2"
        }

        function __ghelp() {
                echo "Aliases defined for git:"
                echo ""
                __gh "ga" "Add everything to repo"
                __gh "gcm" "Commit signed with a message (arg: message)"
                __gh "gts" "Get status of repository"
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
        gpshu="__gpsh_u $@";
        gpsh_allremote=''for remote in $(git remote); do echo -e "\033[96;1mPushing to $remote\033[0m"; git push "$remote"; echo -e "\n"; done'';

        gkeep="__gkeep";

        gg="git gui &";
        gitka="gitk --all --max-count=5000";
        ggk="git gui & gitk &";
        ggka="git gui & gitka &";

        gsave="__gsave";
        gload="__gload";
        ghelp="__ghelp";
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
    parents = [ "shell" "aliases" ];
    add_opts = {
      pingtest_website = lib.mkOption {
        type = lib.types.str;
        default = "www.google.fr"; # TODO find better
        description = "Website to ping for internet connection test";
      };
    };
    home_cfg.programs.bash = {
      enable = true;
      shellAliases = {
        pingt=''ping -c 1 ${config.commonconf.shell.aliases.network.pingtest_website}'' +
          '' 1> /dev/null 2> /dev/null && echo -e "'${colors.great}'Connected'${colors.reset}'"'' +
          '' || echo -e "'${colors.bad}'No connection'${colors.reset}'"'';
      };
    };
  }

  {
    name = "nix";
    default_enabled = true;
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
      initExtra = ''
        NIX_SHELLS_DIR="$HOME/${config.commonconf.shell.aliases.nix.nix_shells_dir}"
      '' + (data_lib.read_data [ "shell" "nix-shells" ]);
    };
  }
  
  {
    name = "fzf";
    default_enabled = true;
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
    } // (data_lib.copy_files_in_home [
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