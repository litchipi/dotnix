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

      symlink = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = "Symlink to create of this secret on the filesystem";
      };
    };
  };

  provision_privk = libdata.get_data_path ["secrets" "provision_key" "${config.base.hostname}.gpg"];
  provision_pubk = libdata.get_data_path ["secrets" "provision_key" "${config.base.hostname}.pub"];
  provision_shasum = libdata.get_data_path ["secrets" "provision_key" "${config.base.hostname}.sha512sum"];

  mkSecretOnDisk = name:
    { source, ... }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-secret";
      phases = "installPhase";
      buildInputs = [ pkgs.rage ];
      installPhase = ''
        rage -a -R '${provision_pubk}' -o "$out" '${source}'
      '';
    };

  mkService = name:
    { source, dest, owner, group, permissions, symlink, ... }: {
      path = [ pkgs.rage ];
      description = "Decrypt secret for ${name}";
      wantedBy = [ "multi-user.target" ];
      after = ["local-fs.target"];

      serviceConfig.Type = "oneshot";

      script = let
        secret = mkSecretOnDisk name { inherit source; };
      in ''
        rm -rf ${dest}
        mkdir -p $(dirname ${dest})
        rage -d -i ${cfg.machine_secret_key_fname} -o '${dest}' '${secret}'

        chown '${owner}':'${group}' '${dest}'
        chmod '${permissions}' '${dest}'

        ${lib.strings.optionalString (!builtins.isNull symlink) "rm -f ${symlink} && ln -s ${dest} ${symlink}"}
      '';
    };
in {
  options.base.secrets = {
    machine_secret_key_fname = lib.mkOption {
      type = types.str;
      description = "Filename for the master key";
      default = "/etc/secrets_key";
    };
    store = mkOption {
      type = types.attrsOf secret;
      description = "secret configuration";
      default = { };
    };
  };

  config = {
    systemd.services = let
      units = mapAttrs' (name: info: {
        name = "${name}-key";
        value = (mkService name info);
      }) cfg.store;
    in units;

    system.activationScripts.decrypt_machine_secret_key = ''
      export PATH=$PATH:${pkgs.gnupg}/bin/

      function decrypt_key() {
        echo "Decrypting provision key..."

        echo "Password hint: ${builtins.readFile ../.passwordhint}"
        read -p "Enter password: " -s password
        gpg -q --batch --passphrase "$password" --output ${cfg.machine_secret_key_fname} -d ${provision_privk}
      }

      while true; do
        if [ -f ${cfg.machine_secret_key_fname} ]; then
          key_shasum=$(sha512sum ${cfg.machine_secret_key_fname} | cut -d " " -f 1)
          if [[ "$key_shasum" == "$(cat ${provision_shasum})" ]]; then
            echo "Found matching secret key"
            break
          fi
          rm -f ${cfg.machine_secret_key_fname}
        fi

        if ! decrypt_key; then
          echo "Failed to decrypt key"
          echo ""
          continue;
        fi
        echo "Success"
      done

    chmod 0400 ${cfg.machine_secret_key_fname}
    chown root:root ${cfg.machine_secret_key_fname}
    '';
  };
}
