{ config, lib, pkgs, ... }:
let
  libdata = import ../lib/manage_data.nix {inherit config lib pkgs;};
  colors = import ../lib/colors.nix {inherit config lib pkgs;};

  cfg = config.base.disks;
in
{
  config = let
    get_addpart_size = part: ((part.size.Gib or 0) * 1024) + (part.size.Mib or 0);
    add_parts_sz = builtins.foldl' (acc: sz: acc + sz) 0 (builtins.map get_addpart_size cfg.add_partition);
    root_end = -(add_parts_sz+(cfg.swapsize*1024)+2);

    disp_disks = ''lsblk|grep disk --color=none|'' +
      ''awk '{print "\tDevice ${colors.fg.primary}"$1"${colors.reset} '' +
      ''of size ${colors.fg.secondary}"$4"${colors.reset}"}' '';

    build_script = pkgs.writeShellScriptBin "diskfmt" (''
      set -e
      while true; do
        echo -e "${colors.fg.primary}Disks:${colors.reset}"
        ${disp_disks}
        echo -e -n "${colors.fg.secondary}Choose on what disk to install NixOS${colors.reset}: "
        read target
        if lsblk|grep disk|grep -w $target 1>/dev/null; then
          break;
        else
          echo -e "${colors.fg.tertiary}$target${colors.reset} is ${colors.fg.bad}not a valid${colors.reset} disk"
        fi
      done

      echo -n "Enter the suffix added to the dev for each partition (leave blank if none): "
      read suffix
      
      target=/dev/$target

      UNIX_MKFS="ext2 ext3 ext4 ntfs"
      FAT_MKFS="msdos fat vfat"

      NB_PART=0
    '' + (if cfg.use_uefi then build_script_uefi else build_script_legacy) + ''
        echo -e -n "${colors.fg.primary}Finished successfully${colors.reset}, "
        echo -e "you can now install the NixOS system using the command ${colors.fg.secondary}install_nixos${colors.reset}"
    '');

    build_script_uefi = (
      create_table "gpt" +
      (
        if cfg.disk_encryption then
          (create_encrypted_lvm_partition { start=512; end=-(add_parts_sz + 1); })
        else (
          create_partition cfg.root_part_label 512 root_end "ext4"
          create_partition "swap" root_end (-(add_parts_sz+1)) "linux-swap"
        )
      ) + ''
        echo -e "${colors.fg.secondary}Creating ESP partition${colors.reset}"
        echo -e "${colors.fg.tertiary}======================================================${colors.reset}"
        NB_PART=$((NB_PART+1))
        parted $target -- mkpart ESP fat32 1MiB 512MiB
        parted $target -- set 2 esp on
        mkfs.fat -F 32 -n boot $target$suffix$NB_PART
        echo -e "${colors.fg.secondary}Creating additionnal partition${colors.reset}"
        echo -e "${colors.fg.tertiary}======================================================${colors.reset}"
      '' + (create_add_parts (-(add_parts_sz+1)))
    );

    build_script_legacy = (
      create_table "msdos" +
      (
        if cfg.disk_encryption then
          (create_encrypted_lvm_partition { start=1; end=-(add_parts_sz + 1); })
        else (
          create_partition cfg.root_part_label 1 root_end "ext4"
          create_partition "swap" root_end (-(add_parts_sz+1)) "linux-swap"
        )
      ) + (create_add_parts (-(add_parts_sz+1)))
    );

    create_table = type: ''
      echo -e -n "${colors.fg.secondary}Creating table${colors.reset} "
      echo -e -n "of type ${colors.fg.primary}${type}${colors.reset} "
      echo -e "on disk ${colors.fg.primary}$target${colors.reset}"
      parted $target -- mklabel ${type}
    '';

    create_partition = label: istart: iend: fstype: let
      start = (builtins.toString istart) + "Mib";
      end = (builtins.toString iend) + "Mib";
    in
      ''
      NB_PART=$((NB_PART+1))
      echo -e -n "${colors.fg.secondary}$NB_PART - ${label}|   \t${colors.reset}"
      echo -e -n "partition of type ${colors.fg.tertiary}${fstype}${colors.reset},"
      echo -e "from ${colors.fg.tertiary}${start}${colors.reset} to ${colors.fg.tertiary}${end}${colors.reset}"

      parted $target -- mkpart primary ${fstype} ${start} ${end}
      if [[ "$UNIX_MKFS" == *"${fstype}"* ]]; then
        mkfs.${fstype} -L ${label} $target$suffix$NB_PART
      elif [[ "$FAT_MKFS" == *"${fstype}"* ]]; then
        mkfs.${fstype} -F 32 -n ${label} $target$suffix$NB_PART
      elif [[ "${fstype}" == "linux-swap" ]]; then
        mkswap -L ${label} $target$suffix$NB_PART
      fi
    '';

    create_encrypted_lvm_partition = { start, end }: let
      keyfile = config.base.secrets.store.luks_encryption.dest;
    in ''
      echo -e "${colors.fg.secondary}Encrypted LVM partitions${colors.reset}"
      echo -e "${colors.fg.tertiary}======================================================${colors.reset}"

      echo "Start: ${builtins.toString start}, end: ${builtins.toString end}"

      NB_PART=$((NB_PART+1))
      parted $target -- mkpart primary ${builtins.toString start} ${builtins.toString end}
      cryptsetup luksFormat -d ${keyfile} $target$suffix$NB_PART
      cryptsetup luksOpen -d ${keyfile} $target$suffix$NB_PART encpart

      pvcreate /dev/mapper/encpart
      vgcreate vg /dev/mapper/encpart
      lvcreate -L ${builtins.toString cfg.swapsize}G -n swap vg
      lvcreate -l '100%FREE' -n '${cfg.root_part_label}' vg
      mkfs.ext4 -L ${cfg.root_part_label} /dev/vg/${cfg.root_part_label}
      mkswap -L swap /dev/vg/swap
      echo -e "${colors.fg.tertiary}======================================================${colors.reset}"
    '';
    
    create_add_parts = start: (builtins.foldl' (state: part: let
        new_mib_used = state.mib_used + (get_addpart_size part);
      in
      {
        mib_used = new_mib_used;
        script = state.script + "\n" + (
          create_partition part.label (start+state.mib_used) (start + new_mib_used) part.fstype
        );
      }) { mib_used = 0; script = ""; } cfg.add_partition
    ).script;
  in
  {
    base.secrets.store.luks_encryption = libdata.set_secret "root" ["disk_encryption" config.base.hostname] {};
    environment.systemPackages = [
      pkgs.cryptsetup
      pkgs.lvm2
      pkgs.parted
      build_script
    ];
  };
}
