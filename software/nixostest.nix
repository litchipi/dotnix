{ config, lib, pkgs, ... }: {
  imports = [
  ];

  # The name of the main user of the system
  base.user = "nx";
  base.hostname = "nixostest";
}
