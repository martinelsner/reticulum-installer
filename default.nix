{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

lib.evalModules {
  modules = [ ./nixos ];
}