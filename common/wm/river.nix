{ config, lib, pkgs, ... }:
let 
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
in
conf_lib.create_common_confs [
  {
    name = "river";
    cfg = {
    };
    home_cfg = user: {
      home.packages = with pkgs; [
        river
        swayidle
        wofi
        # wlopm
        wlr-randr
        # start-river
        # stacktile
      ];
    };

      # home.file.".config/river/init".source =
      #   config.lib.file.mkOutOfStoreSymlink (data_lib.get_data_path [ "wm" "river" "river-init.sh" ]);
      # home.file.".config/wofi/style.css" = { source = data_lib.get_data_path [ "wm" "river" "wofi.css" ]; };

      # TODO Place background from data file into somewhere in the store
      # systemd.user.services.background = buildService {
      #   name = "swaybg";
      #   description = "Simple background drawing";
      #   command =
      #     "${pkgs.swaybg}/bin/swaybg --mode fill --image /home/vector/Documents/wallpapers/anime/alice-marisa-sakuya.jpg";
      # };

      # TODO Place background from data file into somewhere in the store
      # systemd.user.services.locker = buildService {
      #   name = "swayidle";
      #   description = "Automatic screen locker";
      #   command = let
      #     lockCommand =
      #       "${pkgs.swaylock}/bin/swaylock -f --image ~/Documents/wallpapers/video-games/ivara-sniper.jpg";
      #   in ''
      #     ${pkgs.swayidle}/bin/swayidle -w \
      #       timeout 300 '${lockCommand}' \
      #       before-sleep '${lockCommand}' \
      #       timeout 360 'brightnessctl --save; brightnessctl set 0' \
      #       resume 'brightnessctl --restore' \
      #       lock '${lockCommand}' '';
      # };

  #     systemd.user.targets.river-session = {
  #       Unit = {
  #         Description = "river session";
  #         Documentation = [ "man:systemd.special(7)" ];
  #         BindsTo = [ "graphical-session.target" ];
  #         Wants = [ "graphical-session-pre.target" ];
  #         After = [ "graphical-session-pre.target" ];
  #       };
  #     };
  #   };
  }
]
