flake: { config, lib, pkgs, ... }:

with lib;

let

  formats = (import ./formats.nix) { inherit lib; inherit pkgs; }; # withGlobalSection

  cfg = config.services.i2pd;

  settingsFormat = formats.ini { withGlobalSection = true; };
  i2pdConf = settingsFormat.generate "i2pd.conf" {
    globalSection = if hasAttr "global" cfg.settings then cfg.settings.global else { };
    sections = removeAttrs cfg.settings [ "global" ];
  };

  tunnelsFormat = formats.ini { };
  tunnelsConf = tunnelsFormat.generate "tunnels.conf" cfg.tunnels;

  i2pdFlags = concatStringsSep " " [
    "--service"
    ("--conf=" + i2pdConf)
    ("--tunconf=" + tunnelsConf)
  ];

  workingDir = "/var/lib/i2pd";

in

{

  options = {

    services.i2pd = {

      enable = mkEnableOption (lib.mdDoc "i2pd");

      package = mkOption {
        type = types.package;
        default = pkgs.i2pd;
        defaultText = literalExpression "pkgs.i2pd";
        description = lib.mdDoc ''
          i2pd package to use.
        '';
      };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = settingsFormat.type;
        };
        default = { };
        description = lib.mdDoc ''
          Configuration for i2pd. See
          <http://i2pd.readthedocs.io/en/latest/user-guide/configuration/>
          for available options.
        '';
      };

      tunnels = lib.mkOption {
        type = lib.types.submodule {
          freeformType = tunnelsFormat.type;
        };
        default = { };
        description = lib.mdDoc ''
          Tunnel specifications for i2pd. See
          <http://i2pd.readthedocs.io/en/latest/user-guide/tunnels/>
          for available options.
        '';
      };

    };

  };

  config = mkIf cfg.enable {
    systemd.services.i2pd = {
      description = "Full-featured I2P client";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "i2pd";
        WorkingDirectory = workingDir;
        RuntimeDirectory = "i2pd";
        Restart = "on-failure";
        ExecStart = "${cfg.package}/bin/i2pd ${i2pdFlags}";
      };
    };
  };

}
