# Dotnix

My dotfiles for the NixOS setup.

## Usage
On Nix 2.5.1:
```
nix build .#<machine>.<output format>
```

### Example
`nix build .#nixostest.vbox`
will output the configuration for `nixostest` as a `virtualbox` image.

## How it works

### Step 1: Create your machine configuration
Inside a `.nix` file, describe how you want your system. It's recommended to
place them inside the `machines/` directory. \\
As much as possible, use the common configuration already defined in the
`common/` directory by simply enabling them with the `commonconf.<name>.enable` flag.

Look at `machines/nixostest.nix` for a simple and commented example.

### Step 2: Add the machine to the list in `flake.nix`
In the end of the file, just add a line
`{ fname=/path/to/your/<machine_name>.nix; system=<machine_system>; }`.

This will create a target `.#<machine_name>.<format>` to be built with `nix build`

### Step 3: Build
For example, `nix nuild .#test.iso-install`. \\
All the output formats added (from `nixos-generators`) for now are:
- vbox: Virtualbox OVA image
- iso: Raw ISO image
- sdraspi: SD card to plug on a Raspberry pi
- kvmcli: KVM virtual machine on the command line
- iso-install: ISO image with the NixOS installer

## Adding the data
In the file `data.toml`, you can write all the "static" data such as SSH public keys.
The ident given will then be used to set them in the configuration.

## TODO
- Storing secrets (SSH private keys, passwords, etc ...)
- Home manager for users
- Cross compiling for Raspberry Pi
- Scripts for easy usage
  - `deploy.sh <IP addr>`
  - `update_nixos.sh`
  - `burn_installer.sh /dev/X`
  - `create_raspi_sdcard.sh /dev/X`

## Contributing
If you feel like it, you can contribute and help me, use my dotnix as a template.
I would really appreciate:
- Feedbacks in general
- Contributions by adding usefull common configurations
- Usefull wrapper functions to make machine configuration more elegant
- Help me advance on any topic of the TODO list

Feel free to open an issue / PR :-)
