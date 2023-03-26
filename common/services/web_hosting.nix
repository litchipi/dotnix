{ config, lib, pkgs, ... }:
let
  cfg = config.services.web_hosting;

  website = lib.types.submodule {
    options.package = lib.mkOption {
      type = lib.types.package;
      description = "Packages to use for this website";
      default = null;
    };
  };

  application = lib.types.submodule {
    options.add_pkgs = lib.mkOption {
      type = with lib.types; listOf package;
      description = "List of packages to add to the PATH variable";
      default = [];
    };
    options.command = lib.mkOption {
      type = lib.types.str;
      description = "Command to start the application";
      default = "";
    };

    options.port = lib.mkOption {
      type = lib.types.port;
      description = "Port that the application use";
      default = null;
    };

    options.wait_service = lib.mkOption {
      type = with lib.types; nullOr (listOf str);
      description = "Systemd service to wait before starting app";
      default = null;
    };

    options.service_user = lib.mkOption {
      type = lib.types.str;
      description = "Name of the User from which the service is start";
      default = cfg.user;
    };

    options.initScript = lib.mkOption {
      type = lib.types.str;
      description = "Script to execute before the web application";
      default = "";
    };
  };

  create_application_service = name: app: {
    "webapp-${name}" = {
      enable = true;
      path = app.add_pkgs;
      serviceConfig = {
        User = app.service_user;
      };
      script = app.command;
      after = ["network.target"] ++ (if builtins.isNull app.wait_service then [] else app.wait_service);
      wantedBy = [ "multi-user.target" ];
    };
  };
in
  {
    options = {
      websites = lib.mkOption {
        type = with lib.types; attrsOf website;
        description = "Static websites to serve";
        default = {};
      };

      applications = lib.mkOption {
        type = with lib.types; attrsOf application;
        description = "Web applications to serve";
        default = {};
      };
    };

    # TODO  Asserts that applications and websites do not overlap subdomain
    config = {
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      base.networking.subdomains = lib.attrsets.mapAttrsToList
        (sub: _: sub)
        (cfg.applications // cfg.websites);

      system.activationScripts.webapp_init_scripts = builtins.concatStringsSep "\n" (
        lib.attrsets.mapAttrsToList (_: app: app.initScript) cfg.applications
      );

      users.extraUsers = lib.attrsets.mapAttrs' (_: app: {
        name = app.service_user;
        value = {
          isSystemUser = true;
          group = app.service_user;
        };
      }) cfg.applications;

      services.nginx = {
        enable = true;

        # TODO  Find a way to limit the web server to cfg.user (on the web hosting services)
        #     If it's a global config, move the www-data creation and setup inside base/networking.nix
        virtualHosts = lib.mkMerge [
          (lib.attrsets.mapAttrs' (subdomain: website: {
            name = "${subdomain}.${config.base.networking.domain}";
            value = {
              root = website.package;
            };
          }) cfg.websites)
          (lib.attrsets.mapAttrs' (subdomain: app: {
            name = "${subdomain}.${config.base.networking.domain}";
            value = {
              locations."/".proxyPass = "http://0.0.0.0:${builtins.toString app.port}";
            };
          }) cfg.applications)
          {
            "_" = {
              default = true;
              extraConfig = ''
                return 404;
              '';
            };
          }
        ];
      };

      systemd.services = lib.mkMerge (
        lib.attrsets.mapAttrsToList create_application_service cfg.applications
      );
    };
  }
