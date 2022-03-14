{ config, lib, pkgs, ... }:
let
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};

  cfg = config.cmn.infosec;
in
conf_lib.create_common_confs [
  {
    name = "infosec";
    parents = ["software"];

    chain_enable_opts = {
      internet = ["web" "pwd_crack" "network" "malware"];
      software = ["forensics" "malware"];
      hardware = [];
      wireless = ["rtl" "wifi" "pwd_crack"];
      all = ["web" "pwd_crack" "network" "forensics" "malware" "rtl" "wifi"];
    };

    cfg = {
      cmn.software.basic.enable = true;
      cmn.software.tui.enable = true;
    };

    add_pkgs = with pkgs; [
      # Scripting
      python39Full
      python39Packages.scapy

      # Tools
      dos2unix
    ];
  }

  ## GUI
  {
    name = "gui";
    parents = ["software" "infosec" ];
    default_enable = config.cmn.wm.enable;
    add_pkgs = with pkgs; [
      # Note taking
      cherrytree
    ];
  }

  ## WEB
  {
    name = "web";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Enumeration
      gobuster

      # Database attacks
      sqlmap
    ];
  }

  ## PWD CRACK
  {
    name = "pwd_crack";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Password cracking
      john
      hashcat
      hashcat-utils
      thc-hydra
      hcxtools

      # Wordlist generation
      crunch
    ];
  }

  ## NETWORK
  {
    name = "network";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Scanning
      nmap
      tcpdump
      ngrep
      rustscan
      sniffglue
    ];
  }

  ## FORENSICS
  {
    name = "forensics";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Binary analysis
      binwalk
      radare2
    ];
  }

  ## MALWARE
  {
    name = "malware";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Malware creation
      snowcrash
      metasploit
    ];
  }

  ## RTL
  {
    name = "rtl";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      gnuradio
    ];
  }

  ## WIFI
  {
    name = "wifi";
    parents = ["software" "infosec" ];
    add_pkgs = with pkgs; [
      # Wifi cracking
      wifite2
      aircrack-ng

      # 802.15.4 sniff
      whsniff
    ];
  }
]
