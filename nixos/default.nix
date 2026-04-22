{ config, lib, pkgs, ... }:

let
  cfg = config.services.reticulum;
  python3Packages = pkgs.python3Packages or pkgs.python3.pkgs;

  rnsd-config = pkgs.writeText "rnsd.config" ''
    # Reticulum Network Stack configuration

    [reticulum]

      enable_transport = yes
      share_instance = yes
      instance_name = default


    [logging]

      loglevel = 4


    [interfaces]

      [[Default Interface]]
        type = AutoInterface
        interface_enabled = True

      [[TCP Server Interface]]
        type = TCPServerInterface
        interface_enabled = False
        listen_ip = 0.0.0.0
        listen_port = 4242
  '';

  lxmd-config = pkgs.writeText "lxmd.config" ''
    # LXMF Daemon configuration — Propagation Node

    [propagation]

      enable_node = yes
      announce_at_start = yes
      announce_interval = 360
      autopeer = yes
      autopeer_maxdepth = 6
      auth_required = no


    [lxmf]

      display_name = LXMF Propagation Node
      announce_at_start = yes
      delivery_transfer_max_accepted_size = 1000


    [logging]

      loglevel = 4
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
    };

    users.users.reticulum = {
      isSystemUser = true;
      group = "reticulum";
      groups = ["dialout"];
      description = "Reticulum service user";
      home = "/var/lib/reticulum";
      createHome = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/reticulum 0750 root root -"
      "d /var/lib/reticulum/lxmd 0750 reticulum reticulum -"
    ];

    environment.etc = {
      "reticulum/config".source = "${rnsd-config}";
    };

    system.activationScripts.reticulumConfig = ''
      if [ ! -f /var/lib/reticulum/lxmd/config ]; then
        cp ${lxmd-config} /var/lib/reticulum/lxmd/config
        chown reticulum:reticulum /var/lib/reticulum/lxmd/config
        chmod 644 /var/lib/reticulum/lxmd/config
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
        ExecStart = "${python3Packages.rns}/bin/rnsd --config /etc/reticulum/config";
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = "/var/lib/reticulum";
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
        ExecStart = "${python3Packages.lxmf}/bin/lxmd --config /var/lib/reticulum/lxmd --rnsconfig /etc/reticulum";
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = "/var/lib/reticulum";
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
