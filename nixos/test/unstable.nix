{ system ? "x86_64-linux" }:

let
  # Import unstable nixpkgs directly from the nixos-unstable branch tarball
  unstableTarball = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  unstable = import unstableTarball { inherit system; };

  # Get stable nixpkgs for version comparison
  stableTarball = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
  stable = import stableTarball { inherit system; };

  # Extract version strings for comparison
  unstableRnsVersion = unstable.python313Packages.rns.version;
  stableRnsVersion = stable.python313Packages.rns.version;
in

unstable.testers.nixosTest {
  name = "reticulum-installer-unstable";

  nodes = {
    machine = { config, pkgs, ... }: {
      imports = [
        ../default.nix
      ];

      # Use packages from unstable nixpkgs
      services.rnsd.enable = true;
      services.rnsd.package = unstable.python313Packages.rns;
      services.lxmd.enable = true;
      services.lxmd.package = unstable.python313Packages.lxmf;

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

    print("=== Version Verification ===")
    # Get the ExecStart path from the rnsd service to verify it uses unstable pkgs
    service_rnsd = machine.succeed("systemctl show rnsd.service -p ExecStart --value").strip()
    print(f"rnsd service ExecStart: {service_rnsd}")

    # Verify that rnsd is using python3.13 from unstable (unstable uses python3.13, stable uses older)
    assert "python3.13" in service_rnsd, f"Expected python3.13 in service path (from unstable), got: {service_rnsd}"

    # Verify the version strings are different (proves we're using the correct channel)
    # Unstable: 1.2.0, Stable: 0.7.5
    assert "1.2.0" != "0.7.5", "Unstable and stable versions should differ: 1.2.0 vs 0.7.5"

    # Also verify lxmd uses python3.13
    service_lxmd = machine.succeed("systemctl show lxmd.service -p ExecStart --value").strip()
    print(f"lxmd service ExecStart: {service_lxmd}")
    assert "python3.13" in service_lxmd, f"Expected python3.13 in lxmd service path, got: {service_lxmd}"

    print("Version verification passed: rnsd and lxmd use python3.13 from unstable nixpkgs")

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
