# Copied from https://github.com/Xe/nixos-configs/blob/master/common/crypto/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  cfg = config.base.secrets;

  secret = types.submodule {
    options = {
      source = mkOption {
        type = types.path;
        description = "Local secret path";
      };

      dest = mkOption {
        type = types.str;
        description = "Where to write the decrypted secret to";
      };

      owner = mkOption {
        default = "root";
        type = types.str;
        description = "Who should own the secret";
      };

      group = mkOption {
        default = "root";
        type = types.str;
        description = "What group should own the secret";
      };

      permissions = mkOption {
        default = "0400";
        type = types.str;
        description = "Permissions expressed as octal.";
      };
    };
  };

  ssh_pubkey = libdata.get_data_path ["secrets" "provision_key" "${config.base.hostname}.pub"];

  mkSecretOnDisk = name:
    { source, ... }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-secret";
      phases = "installPhase";
      buildInputs = [ pkgs.rage ];
      installPhase = ''
          rage -a -R '${ssh_pubkey}' -o "$out" '${source}'
        '';
    };

  mkService = name:
    { source, dest, owner, group, permissions, ... }: {
      description = "Decrypt secret for ${name}";
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = with pkgs; ''
        rm -rf ${dest}
        mkdir -p $(dirname ${dest})
        "${rage}"/bin/rage -d -i /etc/secrets_key -o '${dest}' '${
          mkSecretOnDisk name { inherit source; }
        }'

        chown '${owner}':'${group}' '${dest}'
        chmod '${permissions}' '${dest}'
      '';
    };
in {
  options.base.secrets = mkOption {
    type = types.attrsOf secret;
    description = "secret configuration";
    default = { };
  };

  config.systemd.services = let
    units = mapAttrs' (name: info: {
      name = "${name}-key";
      value = (mkService name info);
    }) cfg;
  in units;

  config.environment.etc."secrets_key" = {
    source = libdata.get_data_path ["secrets" "provision_key" "${config.base.hostname}"];
    mode = "0400";
    uid = 0;
    gid = 0;
    user = "root";
  };
}
