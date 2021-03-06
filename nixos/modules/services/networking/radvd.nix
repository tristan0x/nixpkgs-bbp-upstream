# Module for the IPv6 Router Advertisement Daemon.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.radvd;

  confFile = pkgs.writeText "radvd.conf" cfg.config;

in

{

  ###### interface

  options = {

    services.radvd.enable = mkOption {
      default = false;
      description =
        ''
          Whether to enable the Router Advertisement Daemon
          (<command>radvd</command>), which provides link-local
          advertisements of IPv6 router addresses and prefixes using
          the Neighbor Discovery Protocol (NDP).  This enables
          stateless address autoconfiguration in IPv6 clients on the
          network.
        '';
    };

    services.radvd.config = mkOption {
      example =
        ''
          interface eth0 {
            AdvSendAdvert on;
            prefix 2001:db8:1234:5678::/64 { };
          };
        '';
      description =
        ''
          The contents of the radvd configuration file.
        '';
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.extraUsers.radvd =
      { uid = config.ids.uids.radvd;
        description = "Router Advertisement Daemon User";
      };

    systemd.services.radvd =
      { description = "IPv6 Router Advertisement Daemon";

        wantedBy = [ "multi-user.target" ];

        after = [ "network.target" ];

        path = [ pkgs.radvd ];

        preStart = ''
          mkdir -m 755 -p /run/radvd
          chown radvd /run/radvd
        '';

        serviceConfig =
          { ExecStart = "@${pkgs.radvd}/sbin/radvd radvd"
              + " -p /run/radvd/radvd.pid -m syslog -u radvd -C ${confFile}";
            Restart = "always";
            Type = "forking";
            PIDFile = "/run/radvd/radvd.pid";
          };
      };

  };

}
