{ config, pkgs, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Pacotes comuns para todos os hosts
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    google-chrome
    # Adicione mais pacotes comuns aqui
    # Wayland essentials
    waybar
    wofi
    wlroots
    wl-clipboard
    mako
    grim
    slurp
    swaylock
    swayidle
    # Extra utilities
    kitty
    rofi
    dunst
    brightnessctl
    pamixer
    playerctl
    networkmanagerapplet
    # System utilities
    pciutils
    usbutils
    file
    killall
    # Bluetooth
    bluez
    bluez-tools
    # Network
    networkmanagerapplet
    # Audio
    pavucontrol
    # Archiving
    zip
    unzip
    p7zip
  ];

  # Configurações comuns do sistema
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";

  # Configuração do usuário
  users.users.huggyturd = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "nixos]";
    home = "/home/huggyturd";
    shell = pkgs.bash;
  };

  # Habilitar sudo
  security.sudo = {
    enable = true;
    extraRules = [{
      users = [ "huggyturd" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];
  };

  # Bootloader configuration
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false;  # Disable editing kernel params during boot for security
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      timeout = 5;
    };
  };

  # Wayland/Hyprland configs
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Enable dbus
  services.dbus.enable = true;

  # Core System Services
  services = {
    # Display Manager
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };

    # Printing
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
    };

    # Bluetooth
    bluetooth.enable = true;
  };

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Network
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Liberation Sans" ];
        monospace = [ "Fira Code" ];
      };
    };
  };

  # Input methods
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  # Systemd services
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # Home Manager Integration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.huggyturd = { pkgs, ... }: {
    home.stateVersion = "23.11";
    
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
      };
      git = {
        enable = true;
        userName = "huggyturd";
        userEmail = "your.email@example.com";
      };
    };

    home.file.".config/hypr" = {
      source = inputs.end4-dots + "/hypr";
      recursive = true;
    };
  };
}
