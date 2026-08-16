# Apple T2 Mac の音声。
#
# T2 固有の部分は自分で書く必要がない。nixos-hardware の apple-t2 モジュールが
# kekrby/t2-better-audio を取り込んでいて、次を宣言的に用意している:
#
#   - /etc/udev/rules.d/91-audio-custom.rules
#     カード名（/proc/asound/cards の AppleT2x2）から PULSE_PROFILE_SET と
#     ACP_PROFILE_SET を決めるルール。上流の install.sh は /usr/bin/sed を
#     直書きするが、モジュール側は substituteInPlace で store の sed に
#     差し替えている。
#   - profile-sets と paths を仕込んだ pipewire / wireplumber
#     services.pipewire.package ごと差し替わる。スピーカー・ヘッドホン・
#     内蔵マイク・ヘッドセットマイクが別デバイスとして出るのはこれのおかげ。
#   - boot.kernelParams の intel_iommu=on / iommu=pt / pm_async=off
#     音声とサスペンドの両方に効く。intel_iommu と iommu はモジュール任せに
#     している（重ねて書くと /proc/cmdline に 2 回並ぶだけなので）。
#
# したがって t2-better-audio の install.sh を手で実行する必要はない。
# NixOS の udev は /usr/lib/udev/rules.d を読まないので、実行しても効かない。
{ ... }:

{
  # pm_async=off だけは明示的に書いておく。apple-t2 モジュールも同じものを
  # 設定していて（initial commit 当時の rev a017f5b でも確認済み）、これは
  # 意図的な重複。/proc/cmdline に 2 回並ぶが実害は無い。
  # モジュール側の都合でこれが落ちるとサスペンドが壊れるため、上流に依存せず
  # 手元でも保証しておく。
  boot.kernelParams = [ "pm_async=off" ];

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
