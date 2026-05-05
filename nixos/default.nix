{ config, lib, pkgs, ... }:

let
  cfg = config.services.reticulum;
  python3Packages = pkgs.python3Packages or pkgs.python3.pkgs;

  rnsd-config = pkgs.writeText "rnsd.config" (builtins.readFile ../config/rnsd.config);
  lxmd-config = pkgs.writeText "lxmd.config" (builtins.readFile ../config/lxmd.config);

  rnsd-status = pkgs.writeScriptBin "rnsd-status" ''
    #!${pkgs.bash}/bin/bash
    exec ${python3Packages.rns}/bin/rnstatus --config /etc/reticulum "$@"
  '';

  lxmd-status = pkgs.writeScriptBin "lxmd-status" ''
    #!${pkgs.bash}/bin/bash
    exec ${python3Packages.lxmf}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum --status "$@"
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

    systemd.tmpfiles.rules = [
      "d /var/lib/reticulum 0755 root reticulum -"
      "d /var/lib/lxmd 0755 root reticulum -"
    ];

    environment.etc."reticulum".source = "/var/lib/reticulum";
    environment.etc."lxmd".source = "/var/lib/lxmd";

    system.activationScripts.reticulumConfig = ''
      if [ ! -f /var/lib/reticulum ]; then
        cp --no-clobber ${rnsd-config} /var/lib/reticulum/config
        chown reticulum:reticulum /var/lib/reticulum
        chmod 644 /var/lib/reticulum
      fi

      if [ ! -f /var/lib/lxmd ]; then
        mkdir -p /var/lib/lxmd
        cp --no-clobber ${lxmd-config} /var/lib/lxmd/config
        chown reticulum:reticulum /var/lib/lxmd
        chmod 644 /var/lib/lxmd
      fi

      mkdir -p /var/lib/reticulum/storage
      chown -R reticulum:reticulum /var/lib/reticulum/storage
      chmod -R o+rX /var/lib/reticulum/storage
      chmod 755 /var/lib/reticulum/storage
    '';

    systemd.services.rnsd = {
      description = "Reticulum Network Stack Daemon";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "reticulum";
        Group = "reticulum";
        ExecStart = "${python3Packages.rns}/bin/rnsd --config /etc/reticulum";
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
        ExecStart = "${python3Packages.lxmf}/bin/lxmd --config /etc/lxmd --rnsconfig /etc/reticulum";
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