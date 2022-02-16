{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg = config.base.disks;
in
{
  config = let
    luks_pwd = libdata.try_get_disk_pwd config.base.hostname;

    get_addpart_size = part: ((part.size.Gib or 0) * 1024) + (part.size.Mib or 0);

    build_script = pkgs.writeShellScriptBin "diskfmt" (''
      echo "${colors.primary_color}Preparing disks${colors.reset}"
    '' + (create_partition "boot" "512Mib" false "fat") +
    (if (cfg.swap_encryption && cfg.root_encryption) then
      (create_lvm_partition [
        {label = "root"; size=null; fstype="ext4";}
        {label = "swap"; size=(builtins.toString cfg.swapsize) + "Gib"; fstype="swap";}
      ] true)
    else (
      create_partition "root" null cfg.root_encryption "ext4"
      create_partition "swap" ((builtins.toString cfg.swapsize) + "Gib") cfg.swap_encryption "swap"
    )) +
    (lib.strings.concatStringsSep "\n" (
      builtins.map (part: create_partition part.label (get_addpart_size part) (part.encrypted or false) part.fstype) cfg.add_partition
    ))
  );

  create_partition = label: size: enc: fstype: ''
    echo "${label}: partition of type ${fstype}, size ${builtins.toString size}, with encryption set to ${builtins.toString enc}"
  '';

  create_lvm_partition = parts: enc: ''
    echo "---------- LVM partitions --------------"
  '' + (lib.strings.concatStringsSep "\n" (builtins.map (part:
    create_partition part.label part.size enc part.fstype
  ) parts)) + ''
    echo "-------- END LVM partitions ------------"
  '';
  in
  {
    environment.systemPackages = [
      pkgs.cryptsetup
      pkgs.parted
      build_script
    ];
  };
}
