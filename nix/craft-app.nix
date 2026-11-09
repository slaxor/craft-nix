{
  lib,
  rustPlatform,
  cmake,
  perl,
  pkg-config,
  makeWrapper,
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
  updatesFlag,
  env ? { },
  extraInstall ? "",
}:

let
  cargoToml = lib.importTOML "${src}/Cargo.toml";
  desktopId = "ai.storyteller.${app}";

  runtimeLibs = [
    wayland
    libxkbcommon
    libGL
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
  ];
in
rustPlatform.buildRustPackage {
  pname = app;
  inherit (cargoToml.workspace.package) version;
  inherit src;

  patches = [ ../patches/${app}-updates-managed-externally.patch ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = [
    cmake
    perl
    pkg-config
    makeWrapper
  ];

  postPatch = ''
    sed -i -E '/^(egui_demo_lib|egui_inspection|egui_system_font_provider) = /d' Cargo.toml
  '';

  dontUseCmakeConfigure = true;

  cargoBuildFlags = [
    "-p"
    app
    "-p"
    "${app}-cli"
  ];
  doCheck = false;

  env = env // {
    ${updatesFlag} = "1";
  };

  postInstall = ''
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
  '';

  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeLibs} $out/bin/${app}
    wrapProgram $out/bin/${app} --suffix PATH : ${lib.getBin cups}/bin
  '';

  passthru = { inherit desktopId; };

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
}
