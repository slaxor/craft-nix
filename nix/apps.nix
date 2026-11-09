pkgs: {
  pdfcraft = {
    displayName = "PdfCraft";
    description = "Read, organize, combine, split and secure PDFs";
  };
  vectorcraft = {
    displayName = "VectorCraft";
    description = "Draw and edit vector illustrations, SVG and PDF";
  };
  photocraft = {
    displayName = "PhotoCraft";
    description = "Edit photos and layered PSD documents";
  };
  lightcraft = {
    displayName = "LightCraft";
    description = "Organise photos and develop raw files, non-destructively";
  };
  soundcraft = {
    displayName = "SoundCraft";
    description = "Record, edit and mix audio and MIDI";
    fonts = false;
    buildInputs = [ pkgs.alsa-lib ];
  };
  designcraft = {
    displayName = "DesignCraft";
    description = "Lay out magazines, books and print documents";
  };
  figcraft = {
    displayName = "FigCraft";
    description = "Design and prototype user interfaces";
    buildInputs = [ pkgs.fontconfig ];
    runtimeLibs = [ pkgs.fontconfig ];
  };
  filmcraft = {
    displayName = "FilmCraft";
    description = "Edit video, color and sound";
    buildInputs = [ pkgs.alsa-lib ];
  };
  deckcraft = {
    displayName = "DeckCraft";
    description = "Create and present slide decks";
    buildInputs = [ pkgs.alsa-lib ];
  };
  cadcraft = {
    displayName = "CadCraft";
    description = "Draft, dimension and plot 2D drawings";
  };
  wordcraft = {
    displayName = "WordCraft";
    description = "Write and design documents; open and save Word files";
    i18n = true;
    buildInputs = [ pkgs.fontconfig ];
    runtimeLibs = [ pkgs.fontconfig ];
  };
  gridcraft = {
    displayName = "GridCraft";
    description = "Calculate, analyse and chart data in workbooks";
  };
  effectcraft = {
    displayName = "EffectCraft";
    description = "Motion graphics and visual effects compositor";
    fonts = false;
    buildInputs = [ pkgs.alsa-lib ];
  };
  materialcraft = {
    displayName = "MaterialCraft";
    description = "Design procedural PBR materials with node graphs";
    fonts = false;
  };
  texturecraft = {
    displayName = "TextureCraft";
    description = "Paint PBR textures directly on 3D meshes";
  };
}
