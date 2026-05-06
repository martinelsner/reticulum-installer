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
      boot.kernelParams = [ "console=ttyS0" "loglevel=7" ];

      networking.hostName = "test-vm";

      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
      };

      services.journald.extraConfig = "RateLimitBurst=0";
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("multi-user.target")

    machine.succeed("uname -a")
    machine.succeed("cat /etc/os-release")

    print("=== Running User & Group checks ===")
    machine.succeed("getent group reticulum")
    machine.succeed("id reticulum")
    machine.succeed("id -nG reticulum | grep -qw dialout")

    print("=== Checking Wrapper Scripts ===")
    machine.succeed("test -x /run/current-system/sw/bin/rnsd-status")
    machine.succeed("test -x /run/current-system/sw/bin/lxmd-status")

    print("=== Checking Configuration ===")
    machine.succeed("test -f /etc/reticulum/config")
    machine.succeed("test -f /etc/lxmd/config")
    machine.succeed("grep -q 'enable_transport = yes' /etc/reticulum/config")
    machine.succeed("grep -q 'enable_node = yes' /etc/lxmd/config")

    print("=== Checking Data Preservation ===")
    machine.succeed("test -f /var/lib/reticulum/preexisting_data")
    machine.succeed("grep -q 'existing_test_data' /var/lib/reticulum/preexisting_data")
    machine.succeed("test -f /var/lib/lxmd/preexisting_lxmd")
    machine.succeed("grep -q 'lxmd_existing_data' /var/lib/lxmd/preexisting_lxmd")

    print("=== Checking Permissions ===")
    machine.succeed("test \"$(stat -c %a /var/lib/reticulum)\" = \"777\" -o \"$(stat -c %a /var/lib/reticulum)\" = \"775\"")
    machine.succeed("test \"$(stat -c %a /var/lib/reticulum/storage)\" = \"777\" -o \"$(stat -c %a /var/lib/reticulum/storage)\" = \"775\"")
    machine.succeed("test \"$(stat -c %a /var/lib/reticulum/interfaces)\" = \"777\" -o \"$(stat -c %a /var/lib/reticulum/interfaces)\" = \"775\"")
    machine.succeed("touch /var/lib/reticulum/test_file && chmod 644 /var/lib/reticulum/test_file")
    machine.succeed("test -r /var/lib/reticulum/test_file")
    machine.succeed("mkdir -p /var/lib/reticulum/test_dir && chmod 755 /var/lib/reticulum/test_dir")
    machine.succeed("test -d /var/lib/reticulum/test_dir")

    print("=== Checking Systemd Units ===")
    machine.succeed("test -f /etc/systemd/system/rnsd.service")
    machine.succeed("test -f /etc/systemd/system/lxmd.service")
    machine.succeed("systemctl is-enabled rnsd.service")
    machine.succeed("systemctl is-enabled lxmd.service")

    print("=== Checking Service Status ===")
    machine.succeed("systemctl is-active rnsd.service")
    machine.succeed("systemctl is-active lxmd.service")
    machine.succeed("pgrep -u reticulum -f rnsd")
    machine.succeed("pgrep -u reticulum -f lxmd")

    print("=== Service Logs ===")
    machine.succeed("journalctl -u rnsd.service --no-pager || true")
    machine.succeed("journalctl -u lxmd.service --no-pager || true")

    print("ALL TESTS PASSED")
  '';
}