{ ... }:
let
  substituters = [ "https://cache.soopy.moe" ];
in
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # nixos は cache.nixos.org を末尾に自動で足すので明示しなくてよい。
    # 他のシステムではそれを上書きしないよう extra-substituters を使う。
    inherit substituters;
    trusted-substituters = substituters;
    trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };
}
