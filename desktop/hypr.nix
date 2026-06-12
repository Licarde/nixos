
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    waybar
    eww
    dunst
    libnotify
    nautilus
    wl-clipboard
    hyprpolkitagent
    hyprlauncher
  ];
}
