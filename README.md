# Dotnix

## Setup a new machine

- Install NixOS using the official live USB and process, ensure that the hostname matches the machine name you wish to install.
- Boot on the new system
- Clone this repository somewhere in your user directory
- Decrypt the `gitcrypt.key.gpg` using `gpg -d`, and use `git-crypt unlock <path to decrypted key>` to unlock the repository
- Copy the generated `/etc/nixos/hardware.nix` file into the files in the `hardware/` directory and adapt it if necessary.
- Generate a new provision key using `nix run .#create_provision_key`
- Change the `keypath` parameter for the `decrypt_provision_key` script
- Execute the command `nix run .#decrypt_provision_key` to provision the key to your system on the path `/etc/secrets_key`.
- Execute the command `nix run .#edit_secrets`, change secrets if you want to, then save and exit
- Execute `sudo nixos-rebuild switch --flake <path to this repo>#<machine name>`
- Reboot

## Secrets management

To avoid having the secrets in cleartext in the nix store, we use a base secret `/etc/secrets_key` (that only `root` can read).

It's provided during the installation of the system (see above), and will be used during boot to decrypt all the secrets inside the `/run/nixos-secrets/` directory,
and apply required permissions on them, etc ..

The secrets are secured:
- Using `git-crypt` on the repository
- Using `rage` encryption with the `/etc/secrets_key` key
- Using `encryptf` on the provision keys used to encrypt the secrets in the nix store, inside `data/secrets/privkeys`
- Using `AES` with `argon2` PKDF for the secrets stored in plaintext inside `data/secrets/secrets.json`
