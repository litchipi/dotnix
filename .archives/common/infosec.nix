{ config, pkgs, ... }@args:
let
  libsoft = import ../../lib/software/package_set.nix args;

  cfg = config.software.infosec;

  all_packages_sets = with pkgs; {
    gui = [
      cherrytree
    ];
    web = [
      gobuster
      sqlmap
    ];
    pwd_crack = [
      john
      hashcat
      hashcat-utils
      thc-hydra
      hcxtools
      crunch
    ];
    network = [
      nmap
      tcpdump
      ngrep
      rustscan
      sniffglue
    ];
    forensics = [
      binwalk
      radare2
    ];
    malware = [
      snowcrash
      metasploit
    ];
    rtl = [ gnuradio ];
    wifi = [
      wifite2
      aircrack-ng
      whsniff
    ];
  };
in
  {
    import = [
      ./basic.nix
      ../shell/tui.nix
      ../shell/dev.nix
    ];
    options = {
      package_sets = libsoft.mkPackageSetsOptions all_packages_sets;
    };
    config = {
      environment.systemPackages = with pkgs; [
        # Scripting
        python310Full
        python310Packages.scapy

        # Tools
        dos2unix
      ] ++ (libsoft.mkPackageSetsConfig cfg.package_sets all_packages_sets);

      software.dev.scripts.enable = true;
    };
  }
