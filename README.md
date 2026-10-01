# Fotografista

**Version 1.1** · professional graphics editor · 100% native VCL / Object Pascal

A high-performance desktop image editor written entirely in Object Pascal, with
direct access to the rendering pipeline and no web-framework overhead.

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
2. Open `Fotografista.dproj` in RAD Studio.
3. Select the **Win64** platform.
4. Build and run (`F9`).

The project uses only relative paths, so it builds correctly wherever the
repository is placed.

The unit search path already contains `.\Lib\Graphics32\Source`, which is the
only path the project adds to the IDE defaults. Do not remove it.

> **Note:** `Fotografista.dproj` carries `<ProjectVersion>20.3</ProjectVersion>`
> from an older IDE generation. This is stale metadata; the project builds and
> runs on RAD Studio 13.1. It is left untouched to avoid unrelated churn.

---

## What is in here

```
Fotografista.dpr / .dproj   project entry point and configuration
*.pas                       103 units (application code, excluding Lib/)
*.dfm                       77 forms
uI18n.pas                   generated translation unit (do not edit by hand)
i18n/                       9 translation catalogues (.tsv source, .txt compiled)
Styles/                     35 Embarcadero VCL theme files, loaded at runtime
Lib/Graphics32/             the single external dependency
obrazki/                    interface artwork
tools/                      translation and QA scripts (PowerShell)
vendor/                     pinned dependency versions
CHANGELOG.md                change history
```

### Capabilities

Organised by the units that implement them:

- **Adjustments** - brightness, contrast, gamma, levels, curves, HSB, sepia,
  solarize, BW, sharpening, blur, edge, emboss
- **Print and process simulation** - risograph (two engines), halftone,
  engraving, linocut, lithograph, screen print, stencil, crosshatch, stipple,
  CMYK separation, Agony, Amiga Deluxe Paint-style backgrounds and gradients
- **Filters and stylisation** - duotone, colourise, quantise, glow, bokeh,
  vignette, film grain, glitch, chromatic aberration, pixelate, tile, tileable
- **Geometry** - rotate, straighten, flip, crop, resize, perspective
  corrections, mip-mapped preview
- **Retouching** - selection tools, local brush, clone, watermark, cut-out
- **Colour** - palette extraction and mapping, batch colour conversion
- **Depth effects** - bas-relief from image luminance, stereogram
- **Document** - undo/redo history, macro recording and playback, PDF export,
  video frame output
- **Interface** - 35 VCL themes, 9 interface languages, resizable UI

### Translations

Nine languages are present: Afrikaans, Czech, English, French, German,
Italian, Polish, Portuguese, Spanish.

`i18n/*.tsv` are the sources. `tools\gen_i18n.ps1` regenerates `uI18n.pas` from
them. `uI18n.pas` is generated output and should not be edited directly.

### Interface themes

`fMain.pas` loads every `Styles\*.vsf` at startup. If the folder is missing
the application still runs, but no themes will be offered.

---

## Third-party components

| Component | License |
|---|---|
| Graphics32 3.0 | MPL 1.1 (dual MPL 1.1 / LGPL 2.1; MPL chosen) |
| fpdf | MIT |

Full details, including the third-party code bundled *inside* Graphics32, are
in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Pinned dependency
versions are in [`vendor/VERSIONS.md`](vendor/VERSIONS.md).

---

## License

**This is not an open-source project.** No open-source license applies.

The Fotografista code is proprietary and source-available: you may read it and
build it locally for personal evaluation. You may not copy, modify,
redistribute, publish, sublicense, sell, or fork it. See [`LICENSE`](LICENSE).

The bundled third-party components are excluded from that license and remain
governed by their own terms.

---

## Change history

See [`CHANGELOG.md`](CHANGELOG.md).