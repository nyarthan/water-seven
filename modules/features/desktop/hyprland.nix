{ config, lib, ... }:
let
  username = config.waterSeven.username;
  checkout = "/home/${username}/${config.waterSeven.projectsDirectory}/water-seven";
in
{
  flake.modules.nixos.platform-nixos =
    { pkgs, ... }:
    let
      session = pkgs.writeShellApplication {
        name = "start-water-seven-hyprland";
        text = ''
          export HYPRLAND_CONFIG=/home/${username}/.config/hypr/hyprland.conf
          exec ${pkgs.hyprland}/bin/start-hyprland "$@"
        '';
      };
    in
    {
      programs = {
        dconf.enable = true;
        hyprland = {
          enable = true;
          withUWSM = true;
        };
        hyprlock.enable = true;
      };

      services = {
        dbus.enable = true;
        displayManager.defaultSession = "hyprland-uwsm";
        greetd = {
          enable = true;
          settings.default_session = {
            command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd ${lib.getExe session}";
            user = "greeter";
          };
        };
        pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
        upower.enable = true;
      };

      security = {
        polkit.enable = true;
        rtkit.enable = true;
      };

      hardware.graphics.enable = true;

      fonts.packages = [ pkgs.iosevka ];

      environment.systemPackages = with pkgs; [
        session
        brightnessctl
        fuzzel
        grim
        hypridle
        hyprpolkitagent
        networkmanagerapplet
        playerctl
        slurp
        swaybg
        waybar
        wireplumber
        wl-clipboard
      ];
    };

  flake.modules.homeManager.platform-nixos = { config, pkgs, ... }: {
    xdg.configFile = {
      "hypr/hyprland.conf".source =
        config.lib.file.mkOutOfStoreSymlink "${checkout}/native/hypr/hyprland.conf";
      "fuzzel/fuzzel.ini".source =
        config.lib.file.mkOutOfStoreSymlink "${checkout}/native/fuzzel/fuzzel.ini";
      "hypr/hypridle.conf".text = ''
        general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
        }

        listener {
          timeout = 600
          on-timeout = loginctl lock-session
        }

        listener {
          timeout = 660
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
        }
      '';
      "hypr/hyprlock.conf".text = ''
        general {
          hide_cursor = true
          immediate_render = true
        }

        background {
          monitor =
          color = rgb(111111)
        }

        input-field {
          monitor =
          size = 320, 56
          outline_thickness = 2
          dots_center = true
          fade_on_empty = false
          placeholder_text = Password
          position = 0, -40
          halign = center
          valign = center
        }
      '';
      "waybar/config.jsonc".text = builtins.toJSON {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
        ];
        clock.format = "{:%a %d %b  %H:%M}";
        network = {
          format-wifi = "{essid} {signalStrength}%";
          format-ethernet = "ethernet";
          format-disconnected = "offline";
        };
        pulseaudio = {
          format = "vol {volume}%";
          format-muted = "muted";
        };
        battery = {
          format = "bat {capacity}%";
          format-charging = "charging {capacity}%";
        };
      };
      "waybar/style.css".text = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Iosevka;
          font-size: 13px;
        }

        window#waybar {
          background: rgba(17, 17, 17, 0.94);
          color: #dddddd;
        }

        #workspaces button,
        #clock,
        #pulseaudio,
        #network,
        #battery {
          padding: 0 10px;
        }

        #workspaces button.active {
          color: #8aadf4;
        }
      '';
      "water-seven/generated/hyprland.conf".text = ''
        # Generated Nix paths. Shared action bindings are imported separately.
        source = ~/.config/water-seven/generated/hyprland-bindings.conf
        exec-once = ${lib.getExe pkgs.hyprpolkitagent}
      '';
    };
  };
}
