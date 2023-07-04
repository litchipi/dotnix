{ config, lib, pkgs, ... }:
let
  cfg = config.services.gitlab-runner;
in
  {
    options.services.gitlab-runner = {
      secrets = pkgs.secrets.mkSecretOption "Secrets for Gitlab Runners";
      runner-images = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Images to use for services";
      };
      add_nix_service = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wether to add a service to build using the host's nix store";
      };
    };
    config = {
      virtualisation.docker.enable = true;
      secrets.secret_files."gitlab/runner_registrationConfigFile" = {
        user = "root";
        text = ''
          CI_SERVER_URL="http://git.${config.base.networking.domain}"
          REGISTRATION_TOKEN="$(cat ${cfg.secrets.runner_registration_token.file})"
        '' + (if config.services.gitlab.enable then ''
            DOCKER_NETWORK_MODE="host"
          '' else "");
      };

      services.gitlab-runner = {
        enable = true;
        settings.concurrent = lib.mkDefault 1;

        services = (builtins.mapAttrs (_:
          { runnerOpts ? {}, runnerEnvs ? {}, ...} : lib.attrsets.recursiveUpdate {
            registrationConfigFile = pkgs.secrets.getSecretFileDest "gitlab/runner_registrationConfigFile";
            environmentVariables = runnerEnvs;
          } runnerOpts) cfg.runner-images
        ) // (if cfg.add_nix_service then
          { nix = {
            registrationConfigFile = pkgs.secrets.getSecretFileDest "gitlab/runner_registrationConfigFile";
            dockerImage = "alpine";
            dockerVolumes = [
              "/nix/store:/nix/store:ro"
              "/nix/var/nix/db:/nix/var/nix/db:ro"
              "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            ];
            dockerDisableCache = true;
            preBuildScript = pkgs.writeScript "setup-container" ''
              mkdir -p -m 0755 /nix/var/log/nix/drvs
              mkdir -p -m 0755 /nix/var/nix/gcroots
              mkdir -p -m 0755 /nix/var/nix/profiles
              mkdir -p -m 0755 /nix/var/nix/temproots
              mkdir -p -m 0755 /nix/var/nix/userpool
              mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
              mkdir -p -m 1777 /nix/var/nix/profiles/per-user
              mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
              mkdir -p -m 0700 "$HOME/.nix-defexpr"

              . ${pkgs.nix}/etc/profile.d/nix.sh

              ${pkgs.nix}/bin/nix-env -i ${builtins.concatStringsSep " " (with pkgs; [ nix cacert git openssh ])}

              ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
              ${pkgs.nix}/bin/nix-channel --update nixpkgs
            '';
            environmentVariables = {
              ENV = "/etc/profile";
              USER = "root";
              NIX_REMOTE = "daemon";
              PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
              NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
            };
            tagList = [ "nix" ];
          };
          } else {
          }
        );
      };
    };
  }
