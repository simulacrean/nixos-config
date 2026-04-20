{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  # Private personal data (emails, real names) lives outside this repo
  imports = [ inputs.nixos-private.homeModule ];

  # Active GNOME extensions
  dconf.settings = {

    "org/gnome/shell" = {

      enabled_extensions = [
        "Vitals@CoreCoding.com"
      ];
    };
  };

  # Install and configure programs
  programs.thunderbird = {
    enable = true;

    profiles.default = {
      isDefault = true;
    };
  };

  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "cron";

      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        onepassword-password-manager
      ];

      settings = {
        # Enable extensions automatically
        "extensions.autoDisableScopes" = 0;
      };

      bookmarks = {
        force = true;

        settings = [
          {
            name = "Music / Events";
            toolbar = true;

            bookmarks = [
              {
                name = "Freakscene";
                url = "https://freakscene.us/";
              }
              {
                name = "Subvert.FM";
                url = "https://subvert.fm/";
              }
              {
                name = "electroanarchy";
                url = "https://electronarchy.org/";
              }
              {
                name = "nyc noise";
                url = "https://nyc-noise.com/";
              }
            ];
          }
        ];
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
    shellAliases = {
      scide = "pw-jack scide";
    };
    initContent = ''
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      fastfetch

      # Rebuild system; commit & push /etc/nixos on success
      nix-switch() {
        sudo nixos-rebuild switch --flake /etc/nixos#BIGSTRONGBOSS "$@" || return $?
        local repo=/etc/nixos
        [[ -z $(git -C $repo status --porcelain) ]] && return 0
        git -C $repo add -A
        git -C $repo commit -m "rebuild: $(date +%F\ %H:%M)"
        git -C $repo push
      }
    '';

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
        "z"
        "sudo"
        "history"
        "docker"
        "npm"
        "node"
        "python"
        "colored-man-pages"
      ];
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];
  };

  programs.kitty = {
    enable = true;

    settings = {
      # Styles to make it look more like X11
      linux_display_server = "x11";
      hide_window_decorations = false;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      active_tab_background = "#4a4a4a";
      active_tab_foreground = "#ffffff";
      inactive_tab_background = "#3a3a3a";
      inactive_tab_foreground = "#aaaaaa";
      tab_bar_background = "#333333";
      window_padding_width = 8;
      background = "#1e1e1e";
      foreground = "#d4d4d4";
    };
  };

  # Git identity
  programs.git = {
    enable = true;
    settings.user = {
      name = "Cron";
      email = "cron@simulacrean.info";
    };
  };

  # Install packages
  home.packages = with pkgs; [
    deskflow
    nerd-fonts.meslo-lg
    obsidian
    _1password-gui
    _1password-cli
    libreoffice
    gnomeExtensions.vitals
    protonmail-bridge
    gh
    pre-commit
    gitleaks
    fastfetch
    signal-desktop
    bitwig-studio
    soundthread
    qpwgraph
    (supercollider-with-plugins.override {
      plugins = with supercolliderPlugins; [
        sc3-plugins
      ];
    })
    inputs.linear-linux.packages.${pkgs.system}.default
  ];

  # Fastfetch config
  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {

    logo = {
      type = "auto"; # ascii logo, auto-detect distro
    };

    display = {
      separator = ": ";
    };

    modules = [
      "title"
      "separator"
      {
        type = "os";
        key = "OS";
        format = "{2} {9}";
      } # distro long + arch
      {
        type = "host";
        key = "Host";
      }
      {
        type = "kernel";
        key = "Kernel";
        format = "{2}";
      } # shorthand
      {
        type = "uptime";
        key = "Uptime";
      }
      {
        type = "packages";
        key = "Packages";
      }
      {
        type = "shell";
        key = "Shell";
        format = "{1} {4}";
      } # name + version
      {
        type = "de";
        key = "DE";
      }
      {
        type = "wm";
        key = "WM";
      }
      {
        type = "terminal";
        key = "Terminal";
      }
      {
        type = "cpu";
        key = "CPU";
      }
      {
        type = "gpu";
        key = "GPU";
      }
      {
        type = "memory";
        key = "Memory";
        format = "{1} / {2} ({3})";
      } # used/total (percent)
      {
        type = "disk";
        key = "Disk";
      }
      "colors"
    ];
  };

  # Set up i3
  xsession.windowManager.i3 = {
    enable = true;

    config = {
      modifier = "Mod4";
    };
  };

  # Add email accounts
  accounts.email.accounts."cron@simulacrean.info" = {
    address = "cron@simulacrean.info";
    realName = "cron";
    primary = true;
    userName = "cron@simulacrean.info";

    imap = {
      host = "127.0.0.1";
      port = 1143;
      tls.enable = true;
      tls.useStartTls = true;
    };

    smtp = {
      host = "127.0.0.1";
      port = 1025;
      tls.enable = true;
      tls.useStartTls = true;
    };

    passwordCommand = "secret-tool lookup service protonmail-bridge";

    thunderbird = {
      enable = true;
      profiles = [ "default" ];

      settings = id: {
        "mail.server.server_${id}.authMethod" = 3; # 3 is normal password
        "mail.smtpserver.smtp_${id}.authMethod" = 3; # 3 is normal password
      };
    };
  };

  # Auto-apply saved Pipewire connections on login
  systemd.user.services.qpwgraph = {
    Install.WantedBy = [ "default.target" ];
    Unit = {
      Description = "qpwgraph patchbay";
      After = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = "${pkgs.qpwgraph}/bin/qpwgraph --activated";
    };
  };

  # Auto-start Proton mail bridge
  systemd.user.services.protonmail-bridge = {
    Install.WantedBy = [ "default.target" ];

    Unit = {
      Description = "Proton Mail Bridge";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Set default apps
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };

  # Route SuperCollider IDE launches through PipeWire's JACK shim
  xdg.desktopEntries.SuperColliderIDE = {
    name = "SuperCollider IDE";
    genericName = "SuperCollider IDE";
    comment = "IDE for the SuperCollider audio synthesis language";
    exec = "pw-jack scide %F";
    icon = "sc_ide";
    type = "Application";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
      "Development"
      "IDE"
    ];
    mimeType = [ "text/x-sc" ];
    settings.StartupWMClass = "scide";
  };

  # Linear ships only a 1024×1024 icon, outside GNOME's scanned sizes
  # — point Icon= at the PNG directly to force resolution.
  xdg.desktopEntries.linear-linux = {
    name = "Linear";
    comment = "Linux support for linear.app";
    exec = "linear-linux --no-sandbox %U";
    icon = "${
      inputs.linear-linux.packages.${pkgs.system}.default
    }/share/icons/hicolor/1024x1024/apps/linear-linux.png";
    type = "Application";
    terminal = false;
    categories = [ "Utility" ];
    settings.StartupWMClass = "Linear";
  };

  # This must always match the NixOS version
  home.stateVersion = "25.11";

}
