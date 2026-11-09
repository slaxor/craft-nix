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
}
