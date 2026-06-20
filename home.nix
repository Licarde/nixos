{ config, pkgs, ... }:

{
  home.username = "riorio";
  home.homeDirectory = "/home/riorio";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;
}
