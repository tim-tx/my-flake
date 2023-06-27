flake: { config, lib, pkgs, ... }:

let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) strfry;
  cfg = config.services.strfry;
  strfryConf = let
    mkAtom = key: val: lib.generators.mkKeyValueDefault {
      mkValueString = v:
        if builtins.isString v then ''"${v}"''
        else lib.generators.mkValueStringDefault {} v;
    } " = " key val;
    mkSection = key: val: [
      "${key} {"
      (map (x: "    " + x) (mkSectionsAndAtoms val))
      "}"
    ];
    mkSectionOrAtom = key: val:
      if builtins.isAttrs val then
        mkSection key val
      else
        mkAtom key val;
    mkSectionsAndAtoms = attrs: lib.lists.flatten (lib.mapAttrsToList mkSectionOrAtom attrs);
  in pkgs.writeText "strfry.conf" (
    lib.lists.foldl (x: y: x + y + "\n") "" (mkSectionsAndAtoms cfg.settings)
  );
in
{

  options.services.strfry = {
    enable = lib.mkEnableOption (lib.mdDoc "strfry nostr relay");
    user = lib.mkOption {
      type = lib.types.str;
      default = "strfry";
      description = lib.mdDoc ''
        User to run strfry as.
      '';
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "strfry";
      description = lib.mdDoc ''
        Group to run strfry as.
      '';
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.lazyAttrsOf (lib.types.uniq lib.types.unspecified);
        options.db = lib.mkOption {
          type = lib.types.str;
          default = "./strfry-db/";
          description = lib.mdDoc ''
            Directory that contains the strfry LMDB database. If this
            is a relative path, the directory will be created in the
            service working directory (/var/lib/strfry) prior to
            launching.
          '';
        };
        options.relay = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.lazyAttrsOf (lib.types.uniq lib.types.unspecified);
            options.nofiles = lib.mkOption {
              type = lib.types.int;
              default = 65536;
              description = lib.mdDoc ''
                Set OS-limit on maximum number of open files/sockets.
              '';
            };
          };
          default = { };
        };
      };
      default = { };
      description = lib.mdDoc ''
        Configuration for strfry. See sample configuration
        <https://github.com/hoytech/strfry/blob/master/strfry.conf>
        for available options.
      '';
    };
  };

  config = let
    workingDir = "/var/lib/strfry";
    dbIsRelative = builtins.substring 0 1 cfg.settings.db != "/";
    dbDir = if dbIsRelative then "${workingDir}/${cfg.settings.db}" else cfg.settings.db;
  in lib.mkIf cfg.enable {

    systemd.services.strfry = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "strfry";
        Group = "strfry";
        WorkingDirectory = workingDir;
        StateDirectory = builtins.baseNameOf workingDir;
        Restart = "on-failure";
        ExecStart = "${strfry}/bin/strfry --config=${strfryConf} relay";
        # LimitNOFILE = cfg.settings.relay.nofiles;
      };
    };

    systemd.tmpfiles.rules = [ "d ${dbDir} 0750 strfry strfry -" ];

    users.groups.strfry = {};
    users.users.strfry = {
      isSystemUser = true;
      description = "strfry user";
      group = "strfry";
    };

  };

}
