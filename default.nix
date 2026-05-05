{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:
{
  nixos = import ./nixos { inherit pkgs lib; };
}