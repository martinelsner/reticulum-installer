{ pkgs ? import <nixpkgs> {}, lib ? pkgs.lib }:

# Root composition point: imports the NixOS module so the entire
# installer can be evaluated with `nix-build` from the project root.
{
  imports = [ ./nixos ];
}