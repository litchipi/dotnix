{ config, lib, ... }: {
  config = {
    # services.getty.autologinUser = config.base.user;
    setup.is_vm = true;
    virtualisation = {
      qemu.options = [
        "-cpu host"
        "-machine accel=kvm"
      ];
      cores = 8;
      memorySize = 1024*4;
      diskSize = 1024*40;
      forwardPorts = lib.attrsets.mapAttrsToList (_: value: value) config.base.networking.vm_forward_ports;
    };

    users = {
      users.nixos = {
        group = "nixos-default";
        isNormalUser = true;
        password = "nixos";
      };
      groups.nixos-default = {};
    };
  };
}
