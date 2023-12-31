flake: { config, lib, pkgs, ... }:

let
  cfg = config.services.dendrite;
  settingsFormat = pkgs.formats.yaml { };
  configurationYaml = settingsFormat.generate "dendrite.yaml" cfg.settings;
  workingDir = "/var/lib/dendrite";
in
{
  options.services.dendrite = {
    enable = lib.mkEnableOption (lib.mdDoc "matrix.org dendrite");
    httpPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = 8008;
      description = lib.mdDoc ''
        The port to listen for HTTP requests on.
      '';
    };
    httpsPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = lib.mdDoc ''
        The port to listen for HTTPS requests on.
      '';
    };
    tlsCert = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      example = "/var/lib/dendrite/server.cert";
      default = null;
      description = lib.mdDoc ''
        The path to the TLS certificate.

        ```
          nix-shell -p dendrite --command "generate-keys --tls-cert server.crt --tls-key server.key"
        ```
      '';
    };
    tlsKey = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      example = "/var/lib/dendrite/server.key";
      default = null;
      description = lib.mdDoc ''
        The path to the TLS key.

        ```
          nix-shell -p dendrite --command "generate-keys --tls-cert server.crt --tls-key server.key"
        ```
      '';
    };
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      example = "/var/lib/dendrite/registration_secret";
      default = null;
      description = lib.mdDoc ''
        Environment file as defined in {manpage}`systemd.exec(5)`.
        Secrets may be passed to the service without adding them to the world-readable
        Nix store, by specifying placeholder variables as the option value in Nix and
        setting these variables accordingly in the environment file. Currently only used
        for the registration secret to allow secure registration when
        client_api.registration_disabled is true.

        ```
          # snippet of dendrite-related config
          services.dendrite.settings.client_api.registration_shared_secret = "$REGISTRATION_SHARED_SECRET";
        ```

        ```
          # content of the environment file
          REGISTRATION_SHARED_SECRET=verysecretpassword
        ```

        Note that this file needs to be available on the host on which
        `dendrite` is running.
      '';
    };
    loadCredential = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "private_key:/path/to/my_private_key" ];
      description = lib.mdDoc ''
        This can be used to pass secrets to the systemd service without adding them to
        the nix store.
        To use the example setting, see the example of
        {option}`services.dendrite.settings.global.private_key`.
        See the LoadCredential section of systemd.exec manual for more information.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
        options.global = {
          server_name = lib.mkOption {
            type = lib.types.str;
            example = "example.com";
            default = "localhost";
            description = lib.mdDoc ''
              The domain name of the server, with optional explicit port.
              This is used by remote servers to connect to this server.
              This is also the last part of your UserID.
            '';
          };
          private_key = lib.mkOption {
            type = lib.types.either
              lib.types.path
              (lib.types.strMatching "^\\$CREDENTIALS_DIRECTORY/.+");
            example = "$CREDENTIALS_DIRECTORY/private_key";
            default = "${workingDir}/matrix_key.pem";
            description = lib.mdDoc ''
              The path to the signing private key file, used to sign
              requests and events.

              ```
                nix-shell -p dendrite --command "generate-keys --private-key matrix_key.pem"
              ```
            '';
          };
          database = {
            connection_string = lib.mkOption {
              type = lib.types.str;
              example = "postgres:///dendrite?host=/run/postgresql";
              default = "";
              description =  lib.mdDoc ''
                Connection string for global database connection
                pool. Either specify only this option and none of the
                other `connection_string` options, or omit this option
                and specify all the other `connection_string`
                options. Cannot be a SQLite database, i.e. cannot
                start with `file:`.
              '';
            };
          };
        };
        options.federation_api.database = {
          connection_string = lib.mkOption {
            type = lib.types.str;
            example = "file:dendrite_federationapi.db";
            default = "";
            description = lib.mdDoc ''
              Database for the Federation API. Do not use with
              {option}`services.dendrite.settings.global.database.connection_string`.
            '';
          };
        };
        options.key_server.database = {
          connection_string = lib.mkOption {
            type = lib.types.str;
            example = "file:dendrite_keyserver.db";
            default = "";
            description = lib.mdDoc ''
              Database for the Key Server (for end-to-end
              encryption). Do not use with
              {option}`services.dendrite.settings.global.database.connection_string`.
            '';
          };
        };
        options.media_api = {
          database = {
            connection_string = lib.mkOption {
              type = lib.types.str;
              example = "file:dendrite_mediaapi.db";
              default = "";
              description = lib.mdDoc ''
                Database for the Media API. Do not use with
                {option}`services.dendrite.settings.global.database.connection_string`.
              '';
            };
          };
          base_path = lib.mkOption {
            type = lib.types.str;
            default = "${workingDir}/media_store";
            description = lib.mdDoc ''
              Storage path for uploaded media.
            '';
          };
        };
        options.room_server.database = {
          connection_string = lib.mkOption {
            type = lib.types.str;
            example = "file:dendrite_roomserver.db";
            default = "";
            description = lib.mdDoc ''
              Database for the Room Server. Do not use with
              {option}`services.dendrite.settings.global.database.connection_string`.
            '';
          };
        };
        options.sync_api.database = {
          connection_string = lib.mkOption {
            type = lib.types.str;
            example = "file:dendrite_syncapi.db";
            default = "";
            description = lib.mdDoc ''
              Database for the Sync API. Do not use with
              {option}`services.dendrite.settings.global.database.connection_string`.
            '';
          };
        };
        options.user_api = {
          account_database = {
            connection_string = lib.mkOption {
              type = lib.types.str;
              example = "file:dendrite_userapi.db";
              default = "";
              description = lib.mdDoc ''
                Database for the User API, accounts. Do not use with
                {option}`services.dendrite.settings.global.database.connection_string`.
              '';
            };
          };
        };
        options.mscs = {
          database = {
            connection_string = lib.mkOption {
              type = lib.types.str;
              example = "file:dendrite_mscs.db";
              default = "";
              description = lib.mdDoc ''
                Database for exerimental MSC's. Do not use with
                {option}`services.dendrite.settings.global.database.connection_string`.
              '';
            };
          };
        };
      };
      default = { };
      description = lib.mdDoc ''
        Configuration for dendrite, see:
        <https://github.com/matrix-org/dendrite/blob/master/dendrite-config.yaml>
        for available options with which to populate settings.
      '';
    };
    extraFlags = lib.mkOption {
      default = [ ];
      example = [ "-really-enable-open-registration" ];
      type = lib.types.listOf lib.types.str;
      description = lib.mdDoc ''
        Extra arguments to use for executing dendrite.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.httpsPort != null -> (cfg.tlsCert != null && cfg.tlsKey != null);
        message = ''
          If Dendrite is configured to use https, tlsCert and tlsKey must be provided.

          nix-shell -p dendrite --command "generate-keys --tls-cert server.crt --tls-key server.key"
        '';
      }
      {
        assertion = let
          globalConn = cfg.settings.global.database.connection_string;
          apiConns = (map (api: cfg.settings."${api}".database.connection_string)
            [ "federation_api"
              "key_server"
              "media_api"
              "room_server"
              "sync_api"
              "mscs"
            ]) ++ [ cfg.settings.user_api.account_database.connection_string ];
        in globalConn == "" && builtins.all (x: x != "") apiConns
           ||
           globalConn != "" && builtins.all (x: x == "") apiConns;
        message = ''
          Either specify
          services.dendrite.settings.global.database.connection_string
          and none of the other database connection_string options, or
          do not specify
          services.dendrite.settings.global.database.connection_string
          and specify all of the other database connection_string
          options.
        '';
      }
      {
        assertion = ! lib.strings.hasPrefix "file:" cfg.settings.global.database.connection_string;
        message = "Global database cannot be a SQLite database";
      }
    ];

    systemd.services.dendrite = {
      description = "Dendrite Matrix homeserver";
      after = [
        "network.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "dendrite";
        WorkingDirectory = workingDir;
        RuntimeDirectory = "dendrite";
        RuntimeDirectoryMode = "0700";
        LimitNOFILE = 65535;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        LoadCredential = cfg.loadCredential;
        ExecStartPre = ''
          ${pkgs.envsubst}/bin/envsubst \
            -i ${configurationYaml} \
            -o /run/dendrite/dendrite.yaml
        '';
        ExecStart = lib.strings.concatStringsSep " " ([
          "${pkgs.dendrite}/bin/dendrite"
          "--config /run/dendrite/dendrite.yaml"
        ] ++ lib.optionals (cfg.httpPort != null) [
          "--http-bind-address :${builtins.toString cfg.httpPort}"
        ] ++ lib.optionals (cfg.httpsPort != null) [
          "--https-bind-address :${builtins.toString cfg.httpsPort}"
          "--tls-cert ${cfg.tlsCert}"
          "--tls-key ${cfg.tlsKey}"
        ] ++ cfg.extraFlags);
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
      };
    };
  };
  meta.maintainers = lib.teams.matrix.members;
}
