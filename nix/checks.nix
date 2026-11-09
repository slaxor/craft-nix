{
  pkgs,
  self,
  apps,
  srcs,
}:

let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;

  homeManagerStub = {
    options = {
      assertions = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
      };
      home.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
      xdg.mimeApps = {
        enable = lib.mkEnableOption "mimeapps.list";
        defaultApplications = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
        };
      };
    };
  };

  configWith =
    app: settings:
    (lib.evalModules {
      modules = [
        homeManagerStub
        self.homeModules.${app}
        { programs.${app} = settings; }
      ];
      specialArgs = { inherit pkgs; };
    }).config;

  packageNames = config: map lib.getName config.home.packages;
  failedAssertions = config: map (a: a.message) (builtins.filter (a: !a.assertion) config.assertions);

  hmExpectations =
    app: displayName:
    let
      desktopId = "ai.storyteller.${app}.desktop";
      disabled = configWith app { };
      installed = configWith app { enable = true; };
      mime = "${app}/does-not-exist";
      typo = configWith app {
        enable = true;
        defaultFor = [ mime ];
      };
      supported =
        (lib.evalModules {
          modules = [
            homeManagerStub
            self.homeModules.${app}
          ];
          specialArgs = { inherit pkgs; };
        }).options.programs.${app}.defaultFor.example;
      chosen = configWith app {
        enable = true;
        defaultFor = supported;
      };
      declaresTypes = lib.hasInfix "\nMimeType=" (
        builtins.readFile "${srcs.${app}}/packaging/linux/${desktopId}"
      );
    in
    {
      "desktop entry ${desktopId} exists" =
        builtins.pathExists "${srcs.${app}}/packaging/linux/${desktopId}";
      "disabled installs nothing" = disabled.home.packages == [ ];
      "enable installs ${app}" = packageNames installed == [ app ];
      "enable alone leaves mimeapps alone" =
        !installed.xdg.mimeApps.enable && installed.xdg.mimeApps.defaultApplications == { };
      "supported types pass the assertion" = failedAssertions chosen == [ ];
      "an unsupported type fails the assertion by name" =
        failedAssertions typo == [ "programs.${app}.defaultFor: ${displayName} doesn't open ${mime}" ];
    }
    // (
      if declaresTypes then
        {
          "defaultFor maps exactly the listed types" =
            supported != [ ]
            && chosen.xdg.mimeApps.enable
            && chosen.xdg.mimeApps.defaultApplications == lib.genAttrs supported (_: [ desktopId ]);
        }
      else
        {
          "no MimeType= in the desktop entry, so defaultFor offers no types" = supported == [ ];
        }
    );

  packageExpectations =
    app: spec:
    let
      package = self.packages.${system}.${app};
      flag = "${lib.toUpper app}_UPDATES_MANAGED_EXTERNALLY";
    in
    {
      "built with ${flag}" = (package.${flag} or null) == "1";
      "builds bundled C libraries like upstream's releases" = package.dontCargoUseSystemLibs or false;
      "carries the update patch" =
        map baseNameOf package.patches == [ "${app}-updates-managed-externally.patch" ];
    }
    // lib.optionalAttrs (app == "pdfcraft" || spec.i18n or false) {
      "built with the pinned translations" =
        (package.CRAFT_I18N_REQUIRED or null) == "1"
        && lib.hasInfix "craft-i18n-" (package.CRAFT_I18N_DIR or "");
    }
    // lib.optionalAttrs (app != "pdfcraft" && spec.fonts or true) {
      "built with the release's craft-fonts" =
        (package.CRAFT_FONTS_REQUIRED or null) == "1"
        && lib.hasInfix "craft-fonts-" (package.CRAFT_FONTS_DIR or "");
    };

  checkThat =
    name: expected:
    let
      failed = lib.attrNames (lib.filterAttrs (_: ok: !ok) expected);
    in
    assert lib.assertMsg (failed == [ ]) "${name}: failed: ${lib.concatStringsSep ", " failed}";
    pkgs.runCommand "${name}-check" { } "touch $out";
in
lib.concatMapAttrs (app: spec: {
  "hm-${app}" = checkThat "hm-${app}" (hmExpectations app spec.displayName);
  "package-${app}" = checkThat "package-${app}" (packageExpectations app spec);
}) apps
