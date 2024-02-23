{ config, lib, pkgs, ... }:
let
  libdata = import ../../../lib/manage_data.nix {inherit config lib pkgs;};
  libcolors = import ../../../lib/colors.nix {inherit config lib pkgs;};

  # TODO  Create nix shell alias to wrap `nix shell nixpkgs/<pinned version>#package
  all_aliases = {
    filesystem.shellAliases = {
      tmpdir = "cd $(mktemp -d)";
      ".." = "cd .. && ls";
      "..." = "cd ../../ && ls ";
      "...." = "cd ../../../ && ls";
      "....." = "cd ../../../../ && ls";
      lh = "ls -lh";
      lha = "ls -lah";
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
      grep="grep --color=auto";
    };

    git.interactiveShellInit = ''
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

        function __gh() {
          echo -e "${libcolors.fg.palette.primary} $1:   ${libcolors.reset} $2"
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
          __gh "gds" "Print the staged diffs"
          __gh "gdu" "Print the unstaged diffs"
          __gh "grs" "Remove file from staged state"
          __gd "gru" "Restore the unstaged file"
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
          echo ""
        }
    '';
    git.shellAliases = {
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
      gds="git diff --staged";
      gdu="git diff";
      grs="git restore --staged";
      gru="git restore";

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
    # TODO    Add deemix to it
    music.shellAliases = let
      args = [ "-x" "--add-metadata"];
      dl = "${pkgs.yt-dlp}/bin/yt-dlp ${builtins.concatStringsSep " " args}";
      mp3_args = "--audio-format mp3 --audio-quality 0";
    in {
      zik="${dl} ${mp3_args}";
      ziksearch = "${dl} ${mp3_args} --default-search \"ytsearch\"";
      zikflac = "${dl} --audio-format flac --audio-quality 0";
    };
    network.shellAliases = let
        dns = "8.8.8.8";
    in {
      # TODO  FIXME  Pingt
      pingt = builtins.concatStringsSep " " [
        "ping"
        "-c 1"
        "-W 1"
        dns
        "1> /dev/null"
        "2> /dev/null"
        "&&"
        "echo -e"
        libcolors.fg.palette.ok
        "Connected"
        libcolors.reset
        "||"
        "echo -e"
        libcolors.fg.palette.bad
        "No connection"
        libcolors.reset
      ];
    };
    fzf.shellAliases = {
      fnvim = "nvim $(fzf)";
    };
  };

  mkAliasConfigs = aliases: {
    interactiveShellInit = builtins.concatStringsSep "\n\n"
      (lib.attrsets.mapAttrsToList (_: a: a.interactiveShellInit or "") aliases);
    shellAliases = lib.mkMerge (lib.attrsets.mapAttrsToList (_: a: a.shellAliases or {}) aliases);
  };
in
  {
    config.environment = mkAliasConfigs all_aliases;
  }
