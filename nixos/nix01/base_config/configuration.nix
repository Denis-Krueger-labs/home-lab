{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.hostName = "nix01";
  networking.networkmanager.enable = true;

  # Regional settings
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de";

  # User account
  users.users.labadmin = {
    isNormalUser = true;
    description = "Lab Administrator";
    extraGroups = [ "wheel" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    curl
    fastfetch
    git
    vim
    wget
  ];

  # Services
  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  # Compatibility baseline established during the initial installation.
  system.stateVersion = "26.05";
}
