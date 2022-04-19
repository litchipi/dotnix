{ config, lib, pkgs, ... }:
{
  config.base.is_vm = true;
  config.virtualisation = {
    qemu.options = [
      "-cpu host"
      "-machine accel=kvm"
    ];
    cores = 4;
    memorySize = 2048;
    diskSize = 1024*10;
  };
}
