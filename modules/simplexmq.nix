flake: { config, lib, pkgs, ... }:

let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) simplexmq;
  cfg = config.services.simplexmq;
  workingDir = "/var/lib/simplexmq";
  configFile = pkgs.writeText "smp-server.ini" (lib.generators.toINI {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString = v: let
        u = lib.generators.mkValueStringDefault {} v;
      in if u == "true" then "on" else (if u == "false" then "off" else u);
    } ": ";
  } (lib.attrsets.recursiveUpdate cfg.settings (if cfg.passwordFile != null then { AUTH.create_password = "$PASSWORD"; } else {})));
in
{

  options.services.simplexmq = {
    enable = lib.mkEnableOption (lib.mdDoc "SimpleXMQ message queue server");
    package = lib.mkOption {
      type = lib.types.package;
      default = simplexmq;
      defaultText = lib.literalExpression "pkgs.simplexmq";
      description = lib.mdDoc "SimpleXMQ package to use";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "simplexmq";
      description = lib.mdDoc ''
        User to run simplexmq as.
      '';
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "simplexmq";
      description = lib.mdDoc ''
        Group to run simplexmq as.
      '';
    };
    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing a password required to create new
        messaging queues. The password should be used as part of
        server address in client configuration:

        ```smp://fingerprint:password@host1,host2```

        The password will not be shared with the connecting contacts,
        you must share it only with the users who you want to allow
        creating messaging queues on your server.
      '';
      example = "/path/to/password_file";
    };
    settings = lib.mkOption {
      description = lib.mdDoc ''
        Free-form settings written directly to the `smp-server.ini` file.
      '';
      default = { };
      type = lib.types.submodule {
        freeformType = (pkgs.formats.ini { }).type;
        options = {
          STORE_LOG = {
            enable = lib.mkOption {
              type = lib.types.bool;
              description = lib.mdDoc ''
                The server uses STM memory for persistence, that will
                be lost on restart (e.g., as with redis). This option
                enables saving memory to append only log, and
                restoring it when the server is started. Log is
                compacted on start (deleted objects are removed).
              '';
              default = true;
            };
            restore_messages = lib.mkOption {
              type = lib.types.bool;
              description = lib.mdDoc ''
                Undelivered messages are optionally saved and restored
                when the server restarts, they are preserved in the
                .bak file until the next restart.
              '';
              default = true;
            };
            log_stats = lib.mkOption {
              type = lib.types.bool;
              description = lib.mdDoc ''
                Log daily server statistics to CSV file
              '';
              default = true;
            };
          };
          AUTH = {
            new_queues = lib.mkOption {
              type = lib.types.bool;
              description = lib.mdDoc ''
                Disable to completely prohibit creating new messaging
                queues. This can be useful when you want to
                decommission the server, but not all connections are
                switched yet.
              '';
              default = true;
            };
          };
          TRANSPORT = {
            host = lib.mkOption {
              type = lib.types.str;
              description = lib.mdDoc "Only used to print server address on start";
              default = config.networking.hostName;
            };
            port = lib.mkOption {
              type = lib.types.int;
              default = 5223;
            };
            log_tls_errors = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            websockets = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
          INACTIVE_CLIENTS = {
            disconnect = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            # ttl = lib.mkOption {
            #   type = lib.types.int;
            #   example = 86400;
            # };
            # check_interval = lib.mkOption {
            #   type = lib.types.int;
            #   example = 43200;
            # };
          };
        };
      };
    };
  };

  config = let
    configDir = "${workingDir}/config";
    logDir = "${workingDir}/log";
  in lib.mkIf cfg.enable {

    systemd.services = {
      simplexmq = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          [ ! -f "${configDir}/server.key" ] && (yes | ${cfg.package}/bin/smp-server init)
          PASSWORD=$(cat ''${CREDENTIALS_DIRECTORY}/password_file 2>/dev/null) \
          ${pkgs.envsubst}/bin/envsubst -i ${configFile} -o ${configDir}/smp-server.ini
          ${cfg.package}/bin/smp-server start
        '';
        serviceConfig = {
          User = "simplexmq";
          Group = "simplexmq";
          WorkingDirectory = workingDir;
          StateDirectory = builtins.baseNameOf workingDir;
          RuntimeDirectory = builtins.baseNameOf workingDir;
          Restart = "on-failure";
          Environment = [
            "SIMPLEXMQ_CONFIG=${configDir}"
            "SIMPLEXMQ_LOG=${logDir}"
          ];
          LoadCredential = lib.mkIf (cfg.passwordFile != null) ("password_file:" + builtins.toString cfg.passwordFile);
        };
      };
    };

    users.groups.simplexmq = {};
    users.users.simplexmq = {
      isSystemUser = true;
      description = "simplexmq user";
      group = "simplexmq";
    };

  };

}
