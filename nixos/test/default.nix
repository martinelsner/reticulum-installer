{ system ? "x86_64-linux" }:

let
  pkgs = import <nixpkgs> { inherit system; };
  lib = pkgs.lib;
in

pkgs.testers.nixosTest {
  name = "reticulum-installer";

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [
        ../default.nix
      ];

      services.reticulum.enable = true;

      boot.loader.grub.device = "/dev/sda";
      fileSystems."/" = { device = "/dev/sda1"; fsType = "ext4"; };

      networking.hostName = "test-vm";

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    # --- User & Group ---
    machine.succeed("getent group reticulum")
    machine.succeed("id reticulum")
    machine.succeed("id -nG reticulum | grep -qw dialout")

    # --- Wrapper Scripts in systemPackages ---
    machine.succeed("test -x /run/current-system/sw/bin/rnsd-status")
    machine.succeed("test -x /run/current-system/sw/bin/lxmd-status")

    # --- Configuration ---
    machine.succeed("test -f /etc/reticulum/config")
    machine.succeed("test -f /etc/lxmd/config")
    machine.succeed("grep -q 'enable_transport = yes' /etc/reticulum/config")
    machine.succeed("grep -q 'enable_node = yes' /etc/lxmd/config")

    # --- Data Preservation ---
    machine.succeed("test -f /var/lib/reticulum/preexisting_data")
    machine.succeed("grep -q 'existing_test_data' /var/lib/reticulum/preexisting_data")
    machine.succeed("test -f /var/lib/lxmd/preexisting_lxmd")
    machine.succeed("grep -q 'lxmd_existing_data' /var/lib/lxmd/preexisting_lxmd")

    # --- Systemd Units ---
    machine.succeed("test -f /etc/systemd/system/rnsd.service")
    machine.succeed("test -f /etc/systemd/system/lxmd.service")
    machine.succeed("systemctl is-enabled rnsd.service")
    machine.succeed("systemctl is-enabled lxmd.service")

    # --- Service Status ---
    machine.succeed("systemctl is-active rnsd.service")
    machine.succeed("systemctl is-active lxmd.service")
    machine.succeed("pgrep -u reticulum -f rnsd")
    machine.succeed("pgrep -u reticulum -f lxmd")

    print("ALL TESTS PASSED")
  '';
}