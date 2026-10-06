# Fotografista

**Version 1.1** · professional graphics editor · 100% native VCL / Object Pascal

A high-performance desktop image editor written entirely in Object Pascal, with
direct access to the rendering pipeline and no web-framework overhead.

![Fotografista](screenshot.png)

---

## Requirements

| | |
|---|---|
| IDE | Embarcadero RAD Studio **13.1** (Delphi 13.1) |
| Framework | VCL |
| Platform | Win64 (no external runtime required) |

Building requires no extra downloads. The one external dependency, Graphics32,
is included in this repository and is already on the project's unit search path.

---

## Building

1. Clone or download this repository.
2. Open Fotografista.dproj in RAD Studio.
3. Select the **Win64** platform.
4. Build and run (F9).

The project uses only relative paths, so it builds correctly wherever the repository is placed.
The unit search path already contains .\Lib\Graphics32\Source, which is the only path the project adds to the IDE defaults. Do not remove it.

> **Note:** Fotografista.dproj carries <ProjectVersion>20.3</ProjectVersion>
> from an older IDE generation. This is stale metadata; the project builds and
> runs on RAD Studio 13.1. It is left untouched to avoid unrelated churn.

---

## Usage

1. **Open an image** — File › Open... (Ctrl+O), or drop a file onto the
   window. On read the editor accepts BMP, JPEG, PNG, GIF, TIFF, WebP, HEIC,
   HEIF, AVIF and IFF ILBM (Amiga).
2. **Edit** — colour and geometry live under **Adjust**, effects under
   **Effects**. The W Launcher and R Retouch panels give quick access to
   zoom, undo and the painting, cloning, dodging, focusing and masking brushes.
3. **Select and crop** — open the **Selection** panel from **Tools**, drag a
   rectangular (or elliptical, lasso or magic-wand) selection on the canvas,
   then crop to it with Ctrl+X.
4. **Save or export** — File › Save as... (Ctrl+S) writes PNG, JPEG, BMP,
   GIF, TIFF or WebP; **Export PDF**, **Export comparison** and **Timelapse**
   produce the additional outputs described under Capabilities.

---

## What is in here

`	ext
Fotografista.dpr / .dproj   project entry point and configuration
*.pas                       103 units (application code, excluding Lib/)
*.dfm                       77 forms
uI18n.pas                   generated translation unit (do not edit by hand)
i18n/                       9 translation catalogues (.tsv source, .txt compiled)
Styles/                     35 Embarcadero VCL theme files, loaded at runtime
Lib/Graphics32/             the single external dependency
tools/                      translation and QA scripts (PowerShell)
vendor/                     pinned dependency versions
CHANGELOG.md                change history
`

### Capabilities

Every entry below is a menu command in the running program.

Three commands open non-modal panels that stay on top of the main window: **Launcher** (W) and **Retouch** (R) toggle open and closed when invoked again, while **Selection** opens its panel (or raises it if already open). They gather the controls used constantly while editing — the Launcher holds quick toolbar, zoom and edit buttons, and the Retouch panel holds the painting, cloning, retouching and masking brushes.

**File** — open, save as, export PDF (the image is scaled to fill an A4 page as far as it can, ignoring DPI — useful when the system or printer adds unwanted margins), export comparison (the original image next to the current one, separated by a divider line and saved as a PNG), image info, recent files, close, quit.

**Edit** — undo, redo, copy, paste, revert to original, clear history.

**View** — zoom in, zoom out, fit to window, and fixed steps 25%, 50%, 100%, 200%, 400%.

**Adjust** — straightening scans, histogram, contrast, brightness, gamma, levels, white balance, HSB balance, sharpen, Vivid, photo enhancement, Emergo, resize, fit to size with crop, mirror horizontally and vertically, rotate left, right and by 180°.

**Effects › Photographic processes** — colourise, duotone, tritone, quad-tone (with saveable presets), sepia, cyanotype, salt print, X-Ray, false-colour infrared, night vision, thermal, incorrect development (C-41/E-6), Orton, film grain, solarize, grayscale, negative.

**Effects › Artistic** — black & white, oil paint, charcoal, outline, edge detection, blur, emboss, relief, glow, posterize, pixelate, vignette, fake bokeh, tilt-shift, glitch.

**Effects › Distortions** — barrel, arc, swirl, water ripple, polar distortion. Polar offers twelve modes including full and half angle, ring, smooth, tunnel, fisheye, outer stretch, inverted tunnel and 30° slice.

**Effects › Blend** — applies two chosen effects and mixes between the two results with a single 0–100 slider.

**Print** — CMYK misregistration, raster CMYK, linocut, mimeograph, engraving, crosshatch, halftone, stipple, dice, screen print, a risograph-inspired halftone in three versions (v1, v2, and a multi-layer v3 where each layer gets its own ink colour), and T-Shirt Design — which reproduces the preparation of a screen-printed garment image in four stages: posterization, mapping the colours onto inks, removing stray detail, and rendering the screenprint raster.

**Macro** — start recording, stop and save, cancel, batch processing over a source folder, manage macros.

**Tools** — selection panel with outline and mask tolerance, set selection size numerically, crop to selection, tiling to fill target dimensions, stereogram (including anaglyph for red-cyan glasses), remove background from a chosen corner with tolerance, timelapse with video export, retouch panel, protection mask (protect and unprotect selection, show, clear).

**Retouch panel** — eraser and brushes for painting, cloning, brightness, focus, colour replacement, bucket fill and colour sampling (eyedropper), plus a protection mask brush that covers or uncovers areas so edits skip them. Each takes a brush size, strength and tolerance, with a fill and replacement colour. R shows or hides the panel.

Keyboard shortcuts: W launcher, R retouch panel, Ctrl+O open, Ctrl+S save as, Ctrl+W close, Ctrl+Q quit, Ctrl+Z undo, Ctrl+Y redo, Ctrl+C copy, Ctrl+V paste, Ctrl+X crop to selection, Ctrl+Shift+R set selection size, Ctrl+P zoom in, Ctrl+M zoom out, Ctrl+0 fit to window, Ctrl+1 actual size.

**Amiga** — Workbench 1.x (OCS) and 2.x/3.x palettes, OCS 32, EHB 64, AGA 256, Workbench 256 and MagicWB 8 palettes, HAM6 and HAM8, Amiga gradient, Amiga gradient in Agony style, Amiga background, and a stretched background using MagicWB.

**Other retro computers** — C64 (Pepto / Colodore), ZX Spectrum, Game Boy (DMG / Pocket), NES (Nestopia).

**Settings** — language, export quality, interface (canvas background colour, interface font size 8–12 pt, number of recent files, theme, remember window size and position), performance.

**Help** — launcher, about, keyboard shortcuts, performance measurement, online documentation.

Formats on read: BMP, JPEG, PNG, GIF, TIFF, WebP, HEIC, HEIF, AVIF. Formats on write: PNG, JPEG, BMP, GIF, TIFF and WebP. Timelapse export writes an MP4 video using H.264 (it falls back to WMV3 in a .wmv file only if the system has no H.264 encoder).

The interface ships with 35 Embarcadero VCL themes, loaded at startup from the Styles folder, and is available in 9 languages: Afrikaans, Czech, English, French, German, Italian, Polish, Portuguese and Spanish.

### Translations

i18n/*.tsv are the sources. 	ools\gen_i18n.ps1 regenerates uI18n.pas from them. uI18n.pas is generated output and should not be edited directly.

### Interface themes

Main.pas loads every Styles\*.vsf at startup. If the folder is missing the application still runs, but no themes will be offered.

---

## Third-party components

| Component | License |
|---|---|
| Graphics32 3.0 | MPL 1.1 (dual MPL 1.1 / LGPL 2.1; MPL chosen) |
| fpdf | MIT |

Full details, including the third-party code bundled *inside* Graphics32, are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Pinned dependency versions are in [endor/VERSIONS.md](vendor/VERSIONS.md).

---

## License

**This is not an open-source project.** No open-source license applies.

The Fotografista code is proprietary and source-available: you may read it and build it locally for personal evaluation. You may not copy, modify, redistribute, publish, sublicense, sell, or fork it. See [LICENSE](LICENSE).

The bundled third-party components are excluded from that license and remain governed by their own terms.

---

## Change history

See [CHANGELOG.md](CHANGELOG.md).

## Technikalia

Fotografista to edytor graficzny napisany w całości w Object Pascal (Delphi 13.1) przy użyciu VCL.

### Architektura

- **Renderer:** 24-bitowe bitmapy, rendering bezpośredni do kanwy, zoptymalizowany pod Win64.
- **Biblioteki:** Graphics32 (własna modyfikacja w repozytorium) + własne moduły.
- **Obsługa obrazów:** JPEG, PNG, BMP, GIF, TIFF, WebP, HEIC/HEIF, AVIF, IFF ILBM (Amiga).
- **Podwójne buforowanie:** minimalizuje migotanie podczas operacji na płótnie.

### Cechy techniczne

- Pełna obsługa selekcji (prostokąt, elipsa, lasso, magic wand), warstwy oraz maski.
- Zakres korekcji kolorów: jasność/kontrast, gamma, poziomy, krzywe, balans bieli, hue/saturation, kolorowanie.
- Efekty obrazowe oraz funkcje retuszu (klonowanie, rozmycie, wyostrzanie, wymazywanie).
- Timelapse: eksport sekwencji do MP4 (fallback WMV3).
- Eksport do PDF, porównanie przed/po, podgląd na żywo.

Projekt jest w pełni natywny - nie korzysta z Electron/WebView, dzięki czemu ma niewielkie zużycie zasobów i natywną responsywność.