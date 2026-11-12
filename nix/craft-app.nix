{
  lib,
  writeText,
  stdenvNoCC,
  patchelf,
  rustPlatform,
  cmake,
  perl,
  pkg-config,
  makeWrapper,
  dbus,
  wayland,
  libxkbcommon,
  libGL,
  vulkan-loader,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  cups,
}:

{
  app,
  src,
  description,
  env ? { },
  buildInputs ? [ ],
  runtimeLibs ? [ ],
  extraInstall ? "",
}:

let
  cargoToml = lib.importTOML "${src}/Cargo.toml";
  desktopId = "ai.storyteller.${app}";
  unusedPatches = map (p: p.name) ((lib.importTOML "${src}/Cargo.lock").patch.unused or [ ]);
  inherit (cargoToml.workspace.package) version;

  versionChoice = {
    apps.${app}.Pinned = version;
  };
  versionsFile = writeText "${app}-versions.json" (builtins.toJSON versionChoice);

  updatesPatch = ../patches/${app}-updates-managed-externally.patch;
  patches = lib.optional (builtins.pathExists updatesPatch) updatesPatch;

  allRuntimeLibs = runtimeLibs ++ [
    dbus
    wayland
    libxkbcommon
    libGL
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
  ];

  meta = {
    inherit description;
    homepage = "https://github.com/storytold/${app}";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = app;
    platforms = lib.platforms.linux;
  };

  unwrapped = rustPlatform.buildRustPackage {
    pname = "${app}-unwrapped";
    inherit version src patches meta;

    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      allowBuiltinFetchGit = true;
    };

    nativeBuildInputs = [
      cmake
      perl
      pkg-config
    ];
    inherit buildInputs;

    postPatch = lib.optionalString (unusedPatches != [ ]) ''
      sed -i -E '/^\[patch\./,/^\[/{/^(${lib.concatStringsSep "|" unusedPatches}) = /d}' Cargo.toml
    '';

    dontUseCmakeConfigure = true;
    dontCargoUseSystemLibs = true;

    cargoBuildFlags = [
      "-p"
      app
      "-p"
      "${app}-cli"
    ];
    doCheck = false;

    env = env // lib.optionalAttrs (patches != [ ]) { "${lib.toUpper app}_UPDATES_MANAGED_EXTERNALLY" = "1"; };
  };
in
stdenvNoCC.mkDerivation {
  pname = app;
  inherit version src meta;

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${unwrapped}/bin/${app} ${unwrapped}/bin/${app}-cli -t $out/bin
    patchelf --add-rpath ${lib.makeLibraryPath allRuntimeLibs} $out/bin/${app}
    wrapProgram $out/bin/${app} \
      --suffix PATH : ${lib.getBin cups}/bin \
      --set-default CRAFT_VERSIONS_FILE ${versionsFile}
    install -Dm644 packaging/linux/${desktopId}.desktop -t $out/share/applications
    install -Dm644 packaging/linux/${desktopId}.mime.xml $out/share/mime/packages/${desktopId}.xml
    mkdir -p $out/share/icons
    cp -R assets/app-icon/hicolor $out/share/icons/
    sed -e "s/@VERSION@/$version/g" -e "s/@DATE@/$(date -u -d "@$SOURCE_DATE_EPOCH" +%Y-%m-%d)/g" \
      packaging/linux/${desktopId}.metainfo.xml.in \
      | install -Dm644 /dev/stdin $out/share/metainfo/${desktopId}.metainfo.xml
    install -Dm644 NOTICE LICENSE-MIT LICENSE-APACHE -t $out/share/doc/${app}
    if [ -d licenses ]; then cp -R licenses $out/share/doc/${app}/licenses; fi
    ${extraInstall}
    runHook postInstall
  '';

  passthru = { inherit desktopId versionChoice unwrapped; };
}
