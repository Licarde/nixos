{ ... }:
let
  # cache.soopy.moe は T2 Mac 向け（linux-t2 カーネルなど）。
  # 残りは各 flake が自前で用意しているキャッシュで、無いと
  # noctalia は quickshell 一式、nvf は Neovim プラグイン群を
  # ローカルでビルドすることになる。
  substituters = [
    "https://cache.soopy.moe"
    "https://noctalia.cachix.org"
    "https://nvf.cachix.org"
    "https://niri.cachix.org"
  ];
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
    trusted-public-keys = [
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "nvf.cachix.org-1:GMQWiUhZ6ux9D5CvFFMwnc2nFrUHTeGaXRlVBXo+naI="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };
}
