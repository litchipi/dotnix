{ lib, pkgs, config, ... }: {
  base.hostname = "bertha";
  powerManagement.cpuFreqGovernor = "performance";

  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
    vaapiVdpau
    libvdpau-va-gl
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  boot = if config.setup.is_vm then {} else {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };

    # TODO  Put initrd configs
  };

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;


  # TODO  Put disks setup
}
