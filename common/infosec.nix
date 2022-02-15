{ config, lib, pkgs, ... }:
let
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "infosec";
    cfg = {
      commonconf.software.basic.enable = true;
      commonconf.software.tui_tools.enable = true;
    };
    add_pkgs = with pkgs; [
      # Scripting
      python39Full
      python39Packages.scapy

      # Scanning
      nmap
      tcpdump
      ngrep

      # Enumeration
      gobuster

      # Password cracking
      john
      hashcat
      hashcat-utils
      hcxtools

      # Wordlist generation
      crunch

      # Malware creation
      snowcrash
      metasploit

      # Database attacks
      sqlmap
    ];
  }
]
