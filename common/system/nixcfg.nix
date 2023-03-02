{ config, lib, pkgs, ... }:
let
  libconf = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libssh = import ../../lib/ssh.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  cfg = config.cmn.nix;

  remote_builders_default = {
    orionstar = {
      enable = true;
      system = "x86_64-linux";
      sshUser = "nixremotebuilder";
      maxJobs = 1;
      protocol = "ssh";
      hostName = "orionstar.cyou";
      speedFactor = 10;
      supportedFeatures = [
        "kvm"
        "big-parallel"
      ];
      mandatoryFeatures = [];
    };
  };
in
libconf.create_common_confs [
  {
    name = "ecospace";
    parents = ["nix"];
    minimal.cli = true;
    add_opts = {
      # minfree = lib.mkOption {
      #   type = lib.types.int;
      #   description = "Triggers cleaning when there's less than X MiB space left";
      #   default = 256;
      # };
      # maxfree = lib.mkOption {
      #   type = lib.types.int;
      #   description = "To which limit we clean when minfree is triggered (in MiB)";
      #   default = 1024;
      # };
      olderthan = lib.mkOption {
        type = lib.types.str;
        description = "Auto delete nix store elements older than X";
        default = "7d";
      };
      freq = lib.mkOption {
        type = lib.types.str;
        description = "Frequency to collect garbages in nix store";
        default = "daily";
      };
    };
    cfg = {
      nix = {
        settings = {
          auto-optimise-store = true;
          # gc-keep-output = true;
          # gc-keep-derivations = true;
        };
        gc = {
          automatic = true;
          dates = cfg.ecospace.freq;
          options = "--delete-older-than ${cfg.ecospace.olderthan}";
        };
        # extraOptions = ''
        #   min-free = ${toString (cfg.ecospace.minfree * 1024 * 1024)}
        #   max-free = ${toString (cfg.ecospace.maxfree * 1024 * 1024)}
        # '';
      };
    };
  }
  {
    name = "remote";
    parents = ["nix" "builders"];
    add_opts.machines = builtins.mapAttrs (name: default: lib.mkOption {
      type = with lib.types; attrsOf anything;
      description = "Configuration for ${name} remote builder";
      inherit default;
    }) remote_builders_default;
    cfg = {
      base.secrets.store = lib.attrsets.mapAttrs' (name: _: {
        name = "${name}_nixbuilder_ssh";
        value = libdata.set_secret {
          user = "root";
          path = libssh.get_remote_builder_privk_path name;
        };
      }) (lib.attrsets.filterAttrs (_: opts: opts.enable) cfg.builders.remote.machines);

      nix.buildMachines = lib.attrsets.mapAttrsToList (name: usr_opts: let
        opts = remote_builders_default.${name} // usr_opts;
      in {
        inherit (opts) system sshUser maxJobs protocol;
        inherit (opts) hostName speedFactor supportedFeatures;
        inherit (opts) mandatoryFeatures;
        sshKey = config.base.secrets.store."orionstar_nixbuilder_ssh".dest;
      }) (lib.attrsets.filterAttrs (_: opts: opts.enable) cfg.builders.remote.machines);
    };
  }
  {
    name = "setup";
    parents = ["nix" "builders"];
    add_opts = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the builder";
      };
      configuration = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = remote_builders_default.${cfg.builders.setup.name};
        description = "Configuration to set on the builder";
      };
    };
    cfg = let
      builder_opt = cfg.builders.setup.configuration;
    in {
      users.users.${builder_opt.sshUser} = {
        isSystemUser = true;
        openssh.authorizedKeys.keyFiles=[(libssh.get_remote_builder_pubk cfg.builders.setup.name)];
        group = builder_opt.sshUser;
      };
      users.groups.${builder_opt.sshUser} = {};
      nix.settings.trusted-users = [ builder_opt.sshUser ];
    };
  }
]
