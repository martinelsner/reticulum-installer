let
  pkgs = import <nixpkgs> {};
in
{
  nixos = import ./nixos { inherit pkgs; lib = pkgs.lib; };
}