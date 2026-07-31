{ config, pkgs, ... }:

{
  /*
   * Hardware-specific configuration generated during installation.
   */
  imports = [
    ./hardware-configuration.nix
  ];

  /*
   * Required later for Spotify, Discord, Obsidian
   * and Microsoft's VS Code build.
   */
  nixpkgs.config.allowUnfree = true;

  /*
   * Boot configuration
   */
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  /*
   * Use the newest kernel available in the current channel.
   */
  boot.kernelPackages = pkgs.linuxPackages_latest;

  /*
   * Graphics and Mesa support.
   *
   * Added to repair Firefox's EGL/Mesa graphics errors.
   */
  hardware.graphics.enable = true;

  /*
   * Network configuration
   */
  networking.hostName = "nix01";
  networking.networkmanager.enable = true;

  /*
   * Regional settings
   */
  time.timeZone = "Europe/Berlin";

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

  /*
   * German keyboard for the console.
   *
   * Hyprland's keyboard layout remains configured separately
   * in ~/.config/hypr/hyprland.lua.
   */
  console.keyMap = "de";

  /*
   * User account
   */
  users.users.labadmin = {
    isNormalUser = true;
    description = "Lab Administrator";

    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  /*
   * Desktop fonts
   */
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      dejavu_fonts
      font-awesome
      liberation_ttf
      noto-fonts
      noto-fonts-color-emoji
    ];

    fontconfig.defaultFonts = {
      sansSerif = [
        "Noto Sans"
        "DejaVu Sans"
      ];

      serif = [
        "Noto Serif"
        "DejaVu Serif"
      ];

      monospace = [
        "DejaVu Sans Mono"
      ];
    };
  };

  /*
   * Audio through PipeWire
   */
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    pulse.enable = true;
  };

  /*
   * Proxmox virtual-machine integration
   */
  services.qemuGuest.enable = true;

  /*
   * Remote administration
   */
  services.openssh.enable = true;

  /*
   * Hyprland and UWSM
   */
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.uwsm.enable = true;

  /*
   * Desktop infrastructure
   */
  security.polkit.enable = true;
  services.dbus.enable = true;

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  /*
   * Prefer native Wayland for Electron and Chromium applications.
   */
  environment.sessionVariables = {
  # Native Wayland for Electron apps such as Discord and Obsidian.
  NIXOS_OZONE_WL = "1";

  # Firefox workaround: use XWayland because native Wayland
  # currently renders parts of the browser interface incorrectly.
  MOZ_ENABLE_WAYLAND = "0";
};

  /*
   * Packages installed system-wide.
   *
   * Keep exactly one environment.systemPackages block.
   */
  environment.systemPackages = with pkgs; [
    curl
    fastfetch
    firefox
    fuzzel
    git
    hyprpaper
    kitty
    obsidian
    quickshell
    spotify
    thunar
    vim
    vscode
    waybar
    wget
  ];

  /*
   * Compatibility version from the original installation.
   * Do not change this during normal upgrades.
   */
  system.stateVersion = "26.05";
}
