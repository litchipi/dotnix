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
    add_parts_sz = builtins.foldl' (acc: sz: acc + sz) 0 (builtins.map get_addpart_size cfg.add_partition);

    disp_disks = ''lsblk|grep disk --color=none|'' +
      ''awk '{print "\tDevice ${colors.fg.primary}"$1"${colors.reset} '' +
      ''of size ${colors.fg.secondary_color}"$4"${colors.reset}"}' '';

    build_script = pkgs.writeShellScriptBin "diskfmt" (''
      set -e
      while true; do
        echo -e "${colors.fg.primary}Disks:${colors.reset}"
        ${disp_disks}
        echo -e -n "${colors.fg.secondary_color}Choose on what disk to install NixOS${colors.reset}: "
        read target
        if lsblk|grep disk|grep -w $target 1>/dev/null; then
          break;
        else
          echo -e "${colors.fg.tertiary_color}$target${colors.reset} is ${colors.bad}not a valid${colors.reset} disk"
        fi
      done
      
      target=/dev/$target

      UNIX_MKFS="ext2 ext3 ext4 ntfs"
      FAT_MKFS="msdos fat vfat"

      NB_PART=0
    '' + (if cfg.use_uefi then build_script_uefi else build_script_legacy));

    root_end = -(add_parts_sz+(cfg.swapsize*1024)+2);

    build_script_uefi = (
      create_table "gpt" +
      (
        if cfg.disk_encryption then
          (create_encrypted_lvm_partition { start=512; end=-add_parts_sz; })
        else (
          create_partition cfg.root_part_label 512 root_end "ext4"
          create_partition "swap" root_end (-(add_parts_sz+1)) "linux-swap"
        )
      ) + ''
        NB_PART=$((NB_PART+1))
        parted $target -- mkpart ESP fat32 1MiB 512MiB
        parted $target -- set 3 esp on
        mkfs.fat -F 32 -n boot $target$NB_PART
      '' + (create_add_parts (-(add_parts_sz+1)))
    );

    build_script_legacy = (
      create_table "msdos" +
      (
        if cfg.disk_encryption then
          (create_encrypted_lvm_partition { start=1; end=-add_parts_sz; })
        else (
          create_partition cfg.root_part_label 1 root_end "ext4"
          create_partition "swap" root_end (-(add_parts_sz+1)) "linux-swap"
        )
      ) + (create_add_parts (-(add_parts_sz+1)))
    );

    create_table = type: ''
      echo -e -n "${colors.fg.secondary_color}Creating table${colors.reset} "
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
      echo -e -n "${colors.fg.secondary_color}$NB_PART - ${label}|   \t${colors.reset}"
      echo -e -n "partition of type ${colors.fg.tertiary_color}${fstype}${colors.reset},"
      echo -e "from ${colors.fg.tertiary_color}${start}${colors.reset} to ${colors.fg.tertiary_color}${end}${colors.reset}"

      parted $target -- mkpart primary ${fstype} ${start} ${end}
      if [[ "$UNIX_MKFS" == *"${fstype}"* ]]; then
        mkfs.${fstype} -L ${label} $target$NB_PART
      elif [[ "$FAT_MKFS" == *"${fstype}"* ]]; then
        mkfs.${fstype} -F 32 -n ${label} $target$NB_PART
      elif [[ "${fstype}" == "linux-swap" ]]; then
        mkswap -L ${label} $target$NB_PART
        swapon $target$NB_PART
      fi
    '';

    #TODO Encryption
    create_encrypted_lvm_partition = parts:
      ''
      echo -e "${colors.secondary_color}Encrypted LVM partitions${colors.reset}"
      echo -e "${colors.tertiary_color}===========================${colors.reset}"
    '' + (lib.strings.concatStringsSep "\n" (builtins.map (part:
      create_partition part.label part.start part.end part.fstype
    ) parts)) + ''
      echo -e "${colors.tertiary_color}===========================${colors.reset}"
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
    boot.postBootCommands = ''
      set -e
      echo "POSTBOOTCOMMAND"
      diskfmt
      install_nixos
      set +e
    '';
    environment.systemPackages = [
      pkgs.cryptsetup
      pkgs.parted
      build_script
    ];
  };
}
