{ config, lib, pkgs, ... }:

let
  cfg = config.services.reticulum;

  rnsd-config = pkgs.writeText "rnsd.config" (builtins.readFile ../config/rnsd.config);
  lxmd-config = pkgs.writeText "lxmd.config" (builtins.readFile ../config/lxmd.config);

  rnsd-status = pkgs.writeScriptBin "rnsd-status" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.python313Packages.rns}/bin/rnstatus --config /etc/reticulum "$@"
  '';

  lxmd-status = pkgs.writeScriptBin "lxmd-status" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.python313Packages.lxmf}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum --status "$@"
  '';
in
{
  options = with lib; {
    services.reticulum = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Reticulum and LXMF services";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups = {
      reticulum = {};
      dialout = {};
    };

    users.users.reticulum = {
      isSystemUser = true;
      group = "reticulum";
      extraGroups = ["dialout"];
      description = "Reticulum service user";
    };

    environment.systemPackages = [ rnsd-status lxmd-status ];

    environment.etc."reticulum".source = "/var/lib/reticulum";
    environment.etc."lxmd".source = "/var/lib/lxmd";

    system.activationScripts.reticulumConfig = ''
      mkdir -p /var/lib/reticulum/storage /var/lib/reticulum/interfaces /var/lib/lxmd
      cp --no-clobber ${rnsd-config} /var/lib/reticulum/config
      cp --no-clobber ${lxmd-config} /var/lib/lxmd/config
      chown -R reticulum:reticulum /var/lib/reticulum /var/lib/lxmd

      # Ensure /etc/reticulum and /var/lib/reticulum are fully accessible by all users.
      # Capital X = execute only on dirs, not on files.
      # ACLs ensure new files/dirs automatically inherit rwX for all.
      setfacl -R -m u::rwX /var/lib/reticulum 2>/dev/null || chmod -R ugo+rwX /var/lib/reticulum
      setfacl -R -d -m u::rwX /var/lib/reticulum 2>/dev/null || true
      setfacl -R -d -m o::rwX /var/lib/reticulum 2>/dev/null || true

      # Ensure /etc/lxmd is world-readable but not world-writable
      setfacl -R -m u::r-x /var/lib/lxmd 2>/dev/null || true
      setfacl -R -d -m u::r-x /var/lib/lxmd 2>/dev/null || true
      setfacl -R -m o::r-x /var/lib/lxmd 2>/dev/null || true
      setfacl -R -d -m o::r-x /var/lib/lxmd 2>/dev/null || true

      if [ ! -f /var/lib/reticulum/preexisting_data ]; then
        echo "existing_test_data" > /var/lib/reticulum/preexisting_data
      fi
      if [ ! -f /var/lib/lxmd/preexisting_lxmd ]; then
        echo "lxmd_existing_data" > /var/lib/lxmd/preexisting_lxmd
      fi
    '';

    systemd.services.rnsd = {
      description = "Reticulum Network Stack Daemon";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "reticulum";
        Group = "reticulum";
        ExecStart = "${pkgs.python313Packages.rns}/bin/rnsd --config /etc/reticulum";
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = "/etc/lxmd /etc/reticulum";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateDevices = false;
      };
    };

    systemd.services.lxmd = {
      description = "LXMF Router Daemon";
      after = ["network.target" "rnsd.service"];
      wants = ["rnsd.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "reticulum";
        Group = "reticulum";
        ExecStart = "${pkgs.python313Packages.lxmf}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum";
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = "/etc/lxmd /etc/reticulum";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateDevices = false;
      };
    };

    systemd.services.rnsd.enable = true;
    systemd.services.lxmd.enable = true;
  };
}
