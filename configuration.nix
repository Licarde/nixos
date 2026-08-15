{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportRoot =false;
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "hakkaa"; # Define your hostname.
  networking.hostId = "02dc5b26";
  # nix の設定
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    experimental-features = [ "nix-command" "flakes" ];
  };


  # Broadcom Wi-Fi のファームウェア

  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = ./firmware.tar;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        tar -xf ${final.src} -C $out/lib/firmware/brcm
      '';
    }))
  ];

  # 注意: `options brcmfmac feature_disable=0x82000` は削除した。6.18 の
  # ドライバにこのパラメータは存在せず、起動ログに
  # "brcmfmac: unknown parameter 'feature' ignored" が出ていた。
  # /sys/module/brcmfmac/parameters にあるのは alternative_fw_path と
  # debug と roamoff だけで、この設定は効いていなかった。
  boot.blacklistedKernelModules = [ "hci_bcm4377" ];

  # ネットワーク接続は nmcli / nmtui で対話的に設定する。
  networking.wireless = {
    # wpa_supplicant は使わず iwd を使う
    enable = false;
    iwd.enable = true;
  };
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.riorio = {
    isNormalUser = true;
    # dialout はマイコンボードのシリアルポート（/dev/ttyUSB* /dev/ttyACM*）用。
    # 追加後は一度ログインし直さないと反映されない。
    extraGroups = [ "wheel" "networkmanager" "dialout" ]; # sudo / NetworkManager / シリアル
    packages = with pkgs; [
    ];
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";




  # Select internationalisation properties.
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    ipafont
  ];

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        # JIS 固有キーを US 配列で使えるように潰す
        main = {
          ro = "grave";
          yen = "backslash";
          # Apple JIS の 英数 は HID の LANG2 で、Linux では KEY_HANJA として
          # 飛ぶ。これを無変換に付け替えて mozc の SwitchKanaType
          # （ひらがな → カタカナ → 半角カナ）に使う。IME の ON/OFF は
          # かな（KEY_HANGEUL）1 つに寄せた。home.nix の fcitx5 側と対。
          hanja = "muhenkan";
        };
      };
    };
  };
  systemd.services.keyd.wantedBy = [ "multi-user.target" ];

  i18n.defaultLocale = "ja_JP.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkb.options in tty.
  };


  # X11。LightDM を使うために必要
  services.xserver.enable = true;

  

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "pm_async=off"
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # マイコンボードを非 root で扱うための udev ルール。
  # 開発環境自体は ~/Arduino_nyuumon の devShell 側にある。
  services.udev.packages = [ pkgs.platformio-core.udev ];

  # 電池残量。noctalia のバッテリーウィジェットは sysfs を直接読まず
  # org.freedesktop.UPower の D-Bus だけを見ており、デバイスが 1 つも
  # 返らないとウィジェット自体を非表示にする。upower を上げないと
  # /sys/class/power_supply/BAT0 があってもバーに何も出ない。
  services.upower.enable = true;


  # Hyprland の設定
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  hardware = {
    graphics.enable = true;
  };
  # polkit 認証エージェントは home.nix 側で設定している。
  # services.hyprpolkitagent は NixOS 側に存在せず home-manager 専用。
  # security.polkit 自体は programs.hyprland が有効にする。

  programs.niri.enable = true;
  programs.mango.enable = true;




  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
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

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

