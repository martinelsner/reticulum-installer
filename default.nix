{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

{
  imports = [ ./nixos ];
}