# Rework of the secrets management

Have a nix script to edit secrets in the NixOS repo:
```
nix run .#edit_secret
```

That "translates" some kind of encrypted binary blob into a `.nix` file in `/tmp/`
and opens it with `$EDITOR`.

Then, just have to set the secrets in the files with the editor in plaintext,
save, and quit.

Once we saved and exited, the temp file is processed, encrypted, and securely deleted.

For the decryption of secrets, the file is imported, decrypted, and its content are
readable at build time by any configuration, without storing anything in the store.

The script only goes through the json file with encrypted data in it,
and decrypts each line and displays it, re-encrypt after.

The content is only encrypted, base64 encoded data.

In the decryption process of secrets, decode the base64 and decrypt the data using
the system global key.

## Upstream

Let this be runnable in a lib, this way they import it in their `inputs`,
and in the `apps` section, they define:

``` nix
apps.secrets = inputs.nixos_secrets_gen.edit_secrets {
    editor = pkgs.vim;
    command = "vim --no-cache --no-undo";
    temp_file = "/tmp/temp.nix";
    secure_delete = true;
};
```

And import the module containing the secrets definition (`secrets.store.<name>` stuff)

And can read the decrypted secrets from `config.secrets.store.<name>.dest`.

Explain that you only have to set a global secret key for the target system, the
rest is derived from it.

## Data format

In encrypted file, stores an encrypted version of the secret for each different global
key stored in the git repo.
