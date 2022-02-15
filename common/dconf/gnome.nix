{config, lib, pkgs, hmlib, ...}:

with hmlib.gvariant;

let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  data_lib = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  bckimg_path = data_lib.get_data_path ["assets" "wallpapers" config.commonconf.wm.bck-img];
in
conf_lib.create_common_confs [
  {
    name = "gnome";
    parents = ["dconf"];
    home_cfg = {
      dconf.settings = {
        "org/gnome/desktop/background" = {
          picture-uri="file://${bckimg_path}";
          picture-options="zoom";
        };

        "org/gnome/desktop/notifications" = {
          show-banners = false;
          show-in-lock-screen = false;
        };

        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          send-events = "enabled";
          speed = 0.43321299638989164;
          tap-to-click = false;
          two-finger-scrolling-enabled = true;
        };

        "org/gnome/desktop/privacy" = {
          disable-microphone = false;
          report-technical-problems = false;
        };

        "org/gnome/desktop/screensaver" = {
          picture-uri="file://${bckimg_path}";
          lock-delay = mkUint32 0;
          picture-options = "zoom";
        };

        "org/gnome/desktop/session" = {
          idle-delay = mkUint32 300;
        };

        "org/gnome/desktop/interface" = {
          clock-show-seconds = true;
          clock-show-weekday = true;
          enable-animations = true;
          enable-hot-corners = false;
          font-antialiasing = "rgba";
          font-hinting = "full";
          font-name = "Ubuntu 11";
          show-battery-percentage = false;
        };

        "org/gnome/desktop/sound" = {
          allow-volume-above-100-percent = false;
          event-sounds = true;
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = ":close";
        };

        "org/gnome/shell/extensions/unite" = {
          autofocus-windows = false;
          desktop-name-text = "";
          extend-left-box = false;
          greyscale-tray-icons = true;
          hide-activities-button = "always";
          hide-aggregate-menu-arrow = true;
          hide-app-menu-arrow = true;
          hide-app-menu-icon = false;
          hide-dropdown-arrows = true;
          hide-window-titlebars = "never";
          reduce-panel-spacing = false;
          restrict-to-primary-screen = true;
          show-desktop-name = true;
          show-legacy-tray = false;
          show-window-buttons = "never";
          show-window-title = "never";
          window-buttons-placement = "last";
          window-buttons-theme = "default-dark";
        };

        "org/gnome/shell/extensions/runcat" = {
          sleeping-threshold = 5;
        };

        "org/gnome/shell/extensions/freon" = {
          drive-utility = "none";
          gpu-utility = "nvidia-settings";
          group-temperature = true;
          group-voltage = false;
          hot-sensors = [ "NVIDIA GeForce GTX 1650" ];
          panel-box-index = 0;
          show-decimal-value = true;
          show-fan-rpm = false;
          show-icon-on-panel = false;
          show-voltage = false;
          update-time = 2;
        };

        "org/gnome/shell/extensions/gnome-ui-tune" = {
          always-show-thumbnails = true;
          hide-search = true;
          increase-thumbnails-size = true;
          restore-thumbnails-background = true;
        };

        "org/gnome/shell/extensions/nightlightslider" = {
          brightness-sync = false;
          enable-always = true;
          show-always = true;
          show-in-submenu = false;
          show-status-icon = false;
        };

        "org/gnome/shell/extensions/bluetooth-quick-connect" = {
          bluetooth-auto-power-off = true;
          bluetooth-auto-power-on = true;
        };

        "org/gnome/shell/extensions/caffeine" = {
          show-notifications = false;
          user-enabled = true;
        };

        "org/gnome/shell/extensions/dash-to-dock" = {
          animate-show-apps = true;
          apply-custom-theme = false;
          background-color = "#000000";
          background-opacity = 0.34;
          click-action = "launch";
          custom-background-color = true;
          custom-theme-customize-running-dots = false;
          custom-theme-running-dots-border-color = "#000000";
          custom-theme-running-dots-border-width = 0;
          custom-theme-shrink = true;
          dash-max-icon-size = 48;
          dock-fixed = false;
          dock-position = "BOTTOM";
          extend-height = false;
          force-straight-corner = true;
          height-fraction = 0.75;
          hot-keys = true;
          icon-size-fixed = false;
          intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
          isolate-monitors = false;
          isolate-workspaces = true;
          multi-monitor = false;
          preferred-monitor = 0;
          pressure-threshold = 100.0;
          require-pressure-to-show = true;
          running-indicator-dominant-color = true;
          running-indicator-style = "DOTS";
          scroll-action = "switch-workspace";
          shortcut = [ "<Super>q" ];
          shortcut-text = "<Super>q";
          shortcut-timeout = 1.15;
          show-apps-at-top = true;
          show-favorites = true;
          show-mounts = true;
          show-running = true;
          show-show-apps-button = true;
          show-trash = false;
          show-windows-preview = false;
          transparency-mode = "FIXED";
          unity-backlit-items = false;
        };

        "org/gnome/shell" = {
          enabled-extensions = [
            "caffeine@patapon.info"
            "bluetooth-quick-connect@bjarosze.gmail.com"
            "freon@UshakovVasilii_Github.yahoo.com"
            "disconnect-wifi@kgshank.net"
            "runcat@kolesnikov.se"
            "BringOutSubmenuOfPowerOffLogoutButton@pratap.fastmail.fm"
            "Hide_Activities@shay.shayel.org"
            "night-light-slider.timur@linux.com"
            "trayIconsReloaded@selfmade.pl"
            "unite@hardpixel.eu"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "gnome-ui-tune@itstime.tech"
          ];
          had-bluetooth-devices-setup = true;
          remember-mount-password = true;
          welcome-dialog-last-shown-version = "40.5";
        };

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-timeout = 3600;
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = false;
          night-light-schedule-automatic = false;
          night-light-schedule-from = 5.0;
          night-light-schedule-to = 17.0;
          night-light-temperature = mkUint32 2173;
        };

        "org/gnome/desktop/input-sources" = {
          per-window = false;
          sources = [ (mkTuple [ "xkb" "fr+oss" ]) ];
        };

        "org/gnome/desktop/calendar" = {
          show-weekdate = false;
        };

        "org/gnome/desktop/applications/terminal" = {
          exec="${lib.strings.getName config.commonconf.software.default_terminal_app}";
        };
      };
    };
  }

  {
    name = "gnome_keyboard_shortcuts";
    parents = ["dconf"];
    home_cfg.dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Primary><Alt>Return";
        command = "${config.commonconf.software.terminal_cmd} \"bash\"";
        name = "terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>m";
        command = "${config.commonconf.software.terminal_cmd} \"mocp\"";
        name = "mocp";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Primary><Shift><Alt>Return";
        command = "${config.commonconf.software.terminal_cmd} \"tmux\"";
        name = "tmux";
      };
    };
  }
]
