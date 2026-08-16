# Apple T2 Mac（BCM4377/4）の Wi-Fi まわり。
#
# firmware.tar は macOS から抽出したもので linux-firmware にも nixpkgs にも
# 無く、壊すと再取得できない。12MB あってもリポジトリから外さないこと。
{ pkgs, ... }:

{
  # tar を展開して lib/firmware/brcm に置くだけの派生。NixOS 側がこれを
  # zstd 圧縮して /run/current-system/firmware に集約し、
  # /sys/module/firmware_class/parameters/path をそこへ向ける。
  # つまり /lib/firmware に手でコピーする必要はない。
  #
  # 展開先の中身は 163 ファイル。Apple のボード名（fiji / formosa / tahiti /
  # ekans …）付きで、linux-firmware 側と同名のファイルは無いので衝突しない。
  # このマシンの chip は BCM4377/4 = apple,fiji。
  #
  # 起動ログに出る
  #   Direct firmware load for ...apple,fiji-SPPR-m-3.1-X3.bin failed with error -2
  # は異常ではない。ドライバが具体的な名前から順に探して最後に
  # apple,fiji.bin に当たる仕様で、途中の -2 は正常なフォールバック。
  hardware.firmware = [
    (pkgs.runCommandLocal "brcm-firmware" { } ''
      mkdir -p $out/lib/firmware/brcm
      tar -xf ${./firmware.tar} -C $out/lib/firmware/brcm
    '')
  ];

  # Bluetooth 用のファームウェアも tar に入っているが使っていない。
  boot.blacklistedKernelModules = [ "hci_bcm4377" ];

  # 注意: `options brcmfmac feature_disable=0x82000` は削除した。6.18 の
  # ドライバにこのパラメータは存在せず、起動ログに
  # "brcmfmac: unknown parameter 'feature' ignored" が出ていた。
  # /sys/module/brcmfmac/parameters にあるのは alternative_fw_path と
  # debug と roamoff だけで、この設定は効いていなかった。

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
}
