{
  self,
  app,
  displayName,
  src,
}:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.${app};

  desktopId = "ai.storyteller.${app}.desktop";

  supportedMimeTypes =
    let
      lines = lib.splitString "\n" (builtins.readFile "${src}/packaging/linux/${desktopId}");
      mimeLines = builtins.filter (m: m != null) (map (builtins.match "MimeType=(.*)") lines);
    in
    lib.concatMap (m: builtins.filter (t: t != "") (lib.splitString ";" (builtins.head m))) mimeLines;

  unsupported = lib.subtractLists supportedMimeTypes cfg.defaultFor;
in
{
  options.programs.${app} = {
    enable = lib.mkEnableOption displayName;

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.${app};
      defaultText = lib.literalExpression "craft-nix.packages.\${pkgs.stdenv.hostPlatform.system}.${app}";
      description = "The ${displayName} package to install.";
    };

    defaultFor = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.take 2 supportedMimeTypes;
      description = ''
        MIME types ${displayName} opens by default (xdg.mimeApps). Any of the types its desktop
        entry lists: ${lib.concatStringsSep ", " supportedMimeTypes}.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = unsupported == [ ];
        message = "programs.${app}.defaultFor: ${displayName} doesn't open ${lib.concatStringsSep ", " unsupported}";
      }
    ];

    home.packages = [ cfg.package ];

    xdg.mimeApps = lib.mkIf (cfg.defaultFor != [ ]) {
      enable = true;
      defaultApplications = lib.genAttrs cfg.defaultFor (_: [ desktopId ]);
    };
  };
}
