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
  };

  config = lib.mkIf cfg.enable {
    secrets.setup.forgejo-runners = {
      user = "gitea-runner";
      secret = cfg.tokenFile;
    };
    virtualisation.docker.enable = true;
    services.gitea-actions-runner.enable = true;
    services.gitea-actions-runner.package = pkgs.forgejo-actions-runner;
    services.gitea-actions-runner.instances.baseRunner = {
      enable = true;
      name = "base-runner";
      url = cfg.forgejoUrl;
      tokenFile = cfg.tokenFile.file;
      labels = mkLabelList cfg.labels;
    };
  };
}
