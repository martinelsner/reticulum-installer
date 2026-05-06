{ config, lib, pkgs, ... }:

let
  cfg.rnsd = config.services.rnsd;
  cfg.lxmd = config.services.lxmd;
  sharedCfg = config.services.reticulum;
in
{
  options = with lib; {
    services.reticulum = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable shared configuration for Reticulum and LXMF";
      };
    };

    services.rnsd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Reticulum Network Stack Daemon";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.python313Packages.rns;
        description = "Reticulum package to use";
      };
    };

    services.lxmd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable LXMF Router Daemon";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.python313Packages.lxmf;
        description = "LXMF package to use";
      };
    };
  };

  config = lib.mkIf (sharedCfg.enable || cfg.rnsd.enable || cfg.lxmd.enable) {
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

    environment.etc."reticulum".source = "/var/lib/reticulum";
    environment.etc."lxmd".source = "/var/lib/lxmd";

    system.activationScripts.reticulumConfig = ''
      mkdir -p /var/lib/reticulum/storage /var/lib/reticulum/interfaces /var/lib/lxmd
      cp --no-clobber ${pkgs.writeText "rnsd.config" (builtins.readFile ../config/rnsd.config)} /var/lib/reticulum/config
      cp --no-clobber ${pkgs.writeText "lxmd.config" (builtins.readFile ../config/lxmd.config)} /var/lib/lxmd/config
      chown -R reticulum:reticulum /var/lib/reticulum /var/lib/lxmd

      setfacl -R -m u::rwX /var/lib/reticulum 2>/dev/null || chmod -R ugo+rwX /var/lib/reticulum
      setfacl -R -d -m u::rwX /var/lib/reticulum 2>/dev/null || true
      setfacl -R -d -m o::rwX /var/lib/reticulum 2>/dev/null || true

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

    systemd.services.rnsd = lib.mkIf cfg.rnsd.enable {
      description = "Reticulum Network Stack Daemon";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "reticulum";
        Group = "reticulum";
        ExecStart = "${cfg.rnsd.package}/bin/rnsd --config /etc/reticulum";
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

    systemd.services.lxmd = lib.mkIf cfg.lxmd.enable {
      description = "LXMF Router Daemon";
      after = ["network.target" "rnsd.service"];
      wants = ["rnsd.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "reticulum";
        Group = "reticulum";
        ExecStart = "${cfg.lxmd.package}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum";
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

    environment.systemPackages = lib.optionals cfg.rnsd.enable [
      (pkgs.writeScriptBin "rnsd-status" ''
        #!${pkgs.bash}/bin/bash
        exec ${cfg.rnsd.package}/bin/rnstatus --config /etc/reticulum "$@"
      '')
    ] ++ lib.optionals cfg.lxmd.enable [
      (pkgs.writeScriptBin "lxmd-status" ''
        #!${pkgs.bash}/bin/bash
        exec ${cfg.lxmd.package}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum --status "$@"
      '')
    ];
  };
}
