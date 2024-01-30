{ config, pkgs, lib, ... }:
let
  cfg = config.services.forgejo-runners;

  mkLabelList = all_labels: lib.lists.flatten (lib.attrsets.mapAttrsToList (name: { repo, versions }: 
    builtins.map (v: "${name}-${v}:docker://${repo}:${v}") versions
  ) all_labels);

in {
  options.services.forgejo-runners = {
    enable = lib.mkEnableOption { description = "Enable Forgejo runners on this system"; };
    extraPkgs = lib.mkOption {
      description = "Additional packages to add to the base docker image";
      default = [];
      type = lib.types.listOf lib.types.package;
    };
    forgejoUrl = lib.mkOption {
      description = "URL to the forgejo instance";
      default = "http://localhost:${builtins.toString config.services.forgejo.settings.server.HTTP_PORT}";
      type = lib.types.str;
    };
    tokenFile = lib.mkOption {
      description = "Path to the file containing the TOKEN environment variable";
      type = lib.types.attrs;  # TODO  Secret type
    };
    labels = lib.mkOption {
      description = "Tags linked to an executor";
      default = {};
      type = lib.types.attrs;
    };
    cacheDir = lib.mkOption {
      type = lib.types.path;
      description = "Directory where to store the cached data on actions";
      default = "/var/cache/forgejo-actions/";
    };
  };

  config = lib.mkIf cfg.enable {
    setup.directories = [
      { path = cfg.cacheDir; owner = "gitea-runner"; other_perms = "+rwX"; }
    ];

    users.users.gitea-runner = {
      isSystemUser = true;
      group = "gitea-runner";
    };
    users.groups.gitea-runner = {};

    secrets.setup.forgejo-runners = {
      user = "gitea-runner";
      secret = cfg.tokenFile;
    };
    virtualisation.docker.enable = true;
    services.gitea-actions-runner.package = pkgs.forgejo-actions-runner;
    services.gitea-actions-runner.instances.baseRunner = {
      enable = true;
      name = "base-runner";
      url = cfg.forgejoUrl;
      tokenFile = cfg.tokenFile.file;
      labels = (mkLabelList cfg.labels) ++ [ "docker" ];
      settings = {
        container.network = lib.mkDefault "host";
        runner.capacity = lib.mkDefault 8;
        runner.timeout = lib.mkDefault "1h";
        cache.enabled = true;
        cache.dir = cfg.cacheDir;
      };
    };
  };
}
