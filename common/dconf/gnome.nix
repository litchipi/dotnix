{config, lib, pkgs, inputs, ...}:

with inputs.home-manager.lib.hm.gvariant;

let
  conf_lib = import ../../lib/commonconf.nix {inherit config lib pkgs;};
  libdata = import ../../lib/manage_data.nix {inherit config lib pkgs;};

  # TODO  Validate good utilisation in GDM
  gdm_logo_path = libdata.get_data_path ["assets" "desktop" "gdm_greeting_logo.png"];
in
conf_lib.create_common_confs [
  {
    name = "gnome";
    parents = ["dconf"];
    minimal.gui = true;
    home_cfg = {
      dconf.settings = {
        "org/gnome/desktop/privacy" = {
          remember-recent-files = false;
        };

        "org/gnome/login-screen" = {
          logo="${gdm_logo_path}";
        };

        "org/gnome/desktop/background" = {
          picture-uri="file://${config.cmn.wm.bck-img}";
          picture-uri-dark="file://${config.cmn.wm.bck-img}";
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
          click-method = "areas";
        };

        "org/gnome/desktop/privacy" = {
          disable-microphone = false;
          report-technical-problems = false;
        };

        "org/gnome/desktop/screensaver" = {
          picture-uri="file://${config.cmn.wm.bck-img}";
          lock-delay = mkUint32 0;
          picture-options = "zoom";
        };

        "org/gnome/desktop/session" = {
          idle-delay = mkUint32 300;
        };

        "org/gnome/desktop/interface" = {
          color-scheme="prefer-dark";
          clock-show-seconds = true;
          clock-show-weekday = true;
          enable-animations = true;
          enable-hot-corners = false;
          font-antialiasing = "rgba";
          font-hinting = "full";
          show-battery-percentage = false;
          cursor-size = 26;
        };

        "org/gnome/desktop/sound" = {
          allow-volume-above-100-percent = false;
          event-sounds = true;
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

        "org/gnome/shell" = {
          had-bluetooth-devices-setup = true;
          remember-mount-password = true;
          welcome-dialog-last-shown-version = "40.5";
        };

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-timeout = 3600;
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/desktop/input-sources" = {
          per-window = false;
        };

        "org/gnome/desktop/calendar" = {
          show-weekdate = false;
        };

        "org/gnome/desktop/applications/terminal" = {
          exec="${lib.strings.getName config.cmn.software.default_terminal_app}";
        };

        "org/gnome/shell/window-switcher" = {
          current-workspace-only = false;
        };

        "org/gnome/desktop/wm/keybindings" = {
          switch-windows = "['<Super>Tab']";
          switch-applications = "['<Alt>Tab']";
        };

        # Theming
        "org/gnome/desktop/wm/preferences" = {
          button-layout = ":close";
        };

        "org/gnome/shell/extensions/dash-to-dock" = {
          apply-custom-theme=false;
          dock-position="BOTTOM";
          scroll-action="switch-workspace";
          transparency-mode="FIXED";
          background-opacity=0.0;
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
        command = "${config.cmn.software.terminal_cmd} \"bash\"";
        name = "terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>m";
        command = "${config.cmn.software.terminal_cmd} \"mocp\"";
        name = "mocp";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Primary><Shift><Alt>Return";
        command = "${config.cmn.software.terminal_cmd} \"tmux\"";
        name = "tmux";
      };
    };
  }
]
