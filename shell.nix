{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz") { },
}:

pkgs.mkShell {
  LC_ALL = "C";

  packages = with pkgs; [
    nfpm
    git
    gnumake
    zsh
  ];

  shellHook = ''
    exec zsh
  '';

}
