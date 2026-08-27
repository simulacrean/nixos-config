# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Whitelist unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "broadcom-sta"
      "facetimehd-firmware"
      "obsidian"
      "1password"
      "1password-cli"
      "bitwig-studio-unwrapped"
      "onepassword-password-manager"
    ];

  # Whitelist insecure packages
  nixpkgs.config.allowInsecurePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "broadcom-sta"
    ];

  # Wifi hardware
  boot.kernelModules = [ "wl" ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.broadcom_sta
    config.boot.kernelPackages.facetimehd
  ];

  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "brcmfmac"
    "brcmsmac"
  ];

  # Camera hardware
  hardware.facetimehd.enable = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.hostName = "BIGSTRONGBOSS"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "America/New_York";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # JACK shim — required for scsynth (SuperCollider) and other JACK clients
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;

    touchpad = {
      disableWhileTyping = true;
      tapping = true;
      naturalScrolling = true;
      accelSpeed = "0.0";
      additionalOptions = ''
        Option "PalmDetection" "true"
        Option "PalmMinWidth" "8"
        Option "PalmMinZ" "100" 
      '';
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’
  users.users.cron = {
    isNormalUser = true;
    description = "cron";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
    ];
  };

  # Install zsh
  programs.zsh.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    wirelesstools
    networkmanagerapplet
    usbutils
    deskflow
    nixfmt
    direnv
    alsa-utils
    pipewire.jack
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # i3 window manager
  services.xserver.windowManager.i3.enable = true;

  # Allow audio group members to use realtime scheduling and lock memory
  # Required for low-latency audio (SuperCollider, JACK, PipeWire)
  security.pam.loginLimits = [
    # Applies realtime scheduling priority to all users in the
    # audio group
    {
      domain = "@audio";
      type = "hard";
      item = "rtprio";
      # max priority level (99 is kernel-level)
      value = "95";
    }
    {
      domain = "@audio";
      type = "soft";
      item = "rtprio";
      value = "95";
    }
    # memory locking (prevents swapping audio buffers)
    {
      domain = "@audio";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "@audio";
      type = "soft";
      item = "memlock";
      value = "unlimited";
    }
  ];

  systemd.user.extraConfig = ''
    DefaultLimitRTPRIO=95                                                                                                                   
    DefaultLimitMEMLOCK=infinity                                                                                                            
  '';

  # Key remapping
  services.keyd = {
    enable = true;

    keyboards = {

      default = {
        ids = [ "*" ];

        settings = {

          main = {
            leftmeta = "leftcontrol";
            leftcontrol = "leftmeta";
          };
        };
      };
    };
  };

  # Stay awake with the lid closed while docked: AC power + a real keyboard and mouse
  systemd.services.docked-lid-inhibit = {
    description = "Hold a lid-switch inhibitor while docked";

    serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=handle-lid-switch --who=docked-lid --why='External keyboard, mouse and AC power present' --mode=block ${pkgs.coreutils}/bin/sleep infinity";
  };

  # Re-evaluated by udev whenever an input device or the power supply changes
  systemd.services.docked-lid-check = {
    description = "Start or stop the docked lid inhibitor based on AC and input devices";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      systemd
      coreutils
      gnugrep
    ];

    serviceConfig.Type = "oneshot";

    script = ''
      kbd=0
      mouse=0

      for dev in /sys/class/input/event*; do
        props=$(udevadm info --query=property --path="$dev" 2>/dev/null) || continue

        # Ignore uinput devices (keyd, deskflow) and the built-in Apple keyboard/trackpad.
        # Bluetooth peripherals live under /devices/virtual/misc/uhid and still count.
        if echo "$props" | grep -qE '^(DEVPATH=/devices/virtual/input/|ID_MODEL=Apple_Internal_Keyboard___Trackpad$)'; then
          continue
        fi

        if echo "$props" | grep -q '^ID_INPUT_KEYBOARD=1$'; then kbd=1; fi
        if echo "$props" | grep -q '^ID_INPUT_MOUSE=1$'; then mouse=1; fi
      done

      ac=0
      for online in /sys/class/power_supply/*/online; do
        if [ "$(cat "$online")" = 1 ]; then ac=1; fi
      done

      if [ "$kbd$mouse$ac" = 111 ]; then
        systemctl start docked-lid-inhibit.service
      else
        systemctl stop docked-lid-inhibit.service
      fi
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ACTION=="add|remove", TAG+="systemd", ENV{SYSTEMD_WANTS}+="docked-lid-check.service"
    SUBSYSTEM=="power_supply", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="docked-lid-check.service"
  '';
}
