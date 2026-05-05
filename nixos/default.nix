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
      "d /etc/reticulum 0755 root reticulum -"
      "d /etc/lxmd 0755 root reticulum -"
    ];

    environment.etc = {
      "reticulum/config".source = "${rnsd-config}";
    };

    system.activationScripts.reticulumConfig = ''
      if [ ! -f /etc/lxmd/config ]; then
        mkdir -p /etc/lxmd
        cp ${lxmd-config} /etc/lxmd/config
      fi
      chown reticulum:reticulum /etc/lxmd/config
      chmod 644 /etc/lxmd/config

      chown -R reticulum:reticulum /etc/lxmd
      chmod -R o+rX /etc/lxmd

      mkdir -p /etc/reticulum/storage
      chown -R reticulum:reticulum /etc/reticulum/storage
      chmod -R o+rX /etc/reticulum/storage
      chmod 755 /etc/reticulum/storage
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