{ config, lib, pkgs, ... }:
let
  data_lib = import ../lib/manage_data.nix {inherit config lib pkgs;};
  conf_lib = import ../lib/commonconf.nix {inherit config lib pkgs;};

  infosec_cfg = config.commonconf.infosec;
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

      # Tools
      dos2unix
    ];
  }

  ## GUI
  {
    name = "gui";
    parents = [ "infosec" ];
    add_pkgs = with pkgs; [
      # Note taking
      cherrytree
    ];
  }

  ## WEB
  {
    name = "web";
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
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
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
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
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
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
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
    add_pkgs = with pkgs; [
      # Binary analysis
      binwalk
      radare2
    ];
  }

  ## MALWARE
  {
    name = "malware";
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
    add_pkgs = with pkgs; [
      # Malware creation
      snowcrash
      metasploit
    ];
  }

  ## RTL
  {
    name = "rtl";
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
    add_pkgs = with pkgs; [
      gnuradio
    ];
  }

  ## WIFI
  {
    name = "wifi";
    parents = [ "infosec" ];
    default_enabled = if infosec_cfg.enable then true else false;
    add_pkgs = with pkgs; [
      # Wifi cracking
      wifite2
      aircrack-ng

      # 802.15.4 sniff
      whsniff
    ];
  }
]
