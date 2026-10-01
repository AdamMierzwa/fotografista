object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Fotografista'
  ClientHeight = 543
  ClientWidth = 900
  Color = clBtnFace
  DoubleBuffered = True
  ParentFont = True
  Menu = MainMenu
  Position = poScreenCenter
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  OnResize = FormResize
  TextHeight = 15
  object StatusBar: TStatusBar
    Left = 0
    Top = 521
    Width = 900
    Height = 22
    Panels = <
      item
        Width = 300
      end
      item
        Width = 110
      end
      item
        Width = 70
      end
      item
        Width = 55
      end
      item
        Width = -1
      end
      item
        Width = 450
      end
      item
        Width = 80
      end>
  end
  object ScrollBox: TScrollBox
    Left = 0
    Top = 30
    Width = 900
    Height = 491
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 1
    OnMouseDown = ScrollBoxMouseDown
    OnMouseMove = ScrollBoxMouseMove
    OnMouseUp = ScrollBoxMouseUp
    OnMouseWheelDown = ScrollBoxMouseWheelDown
    OnMouseWheelUp = ScrollBoxMouseWheelUp
    object PaintBox: TPaintBox
      Left = 0
      Top = 0
      Width = 900
      Height = 578
      OnMouseDown = PaintBoxMouseDown
      OnMouseMove = PaintBoxMouseMove
      OnMouseUp = PaintBoxMouseUp
      OnPaint = PaintBoxPaint
    end
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 16
    object mnuFile: TMenuItem
      Caption = 'File'
      object mnuFileOpen: TMenuItem
        Caption = 'Open...'
        Hint = 'Open an image file'
        ShortCut = 16463
        OnClick = mnuFileOpenClick
      end
      object mnuFileSaveAs: TMenuItem
        Caption = 'Save as...'
        Hint = 'Save image under a new name'
        ShortCut = 16467
        OnClick = mnuFileSaveAsClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object mnuFileExportPDF: TMenuItem
        Caption = 'Export PDF...'
        Hint = 'Export image to PDF file'
        OnClick = mnuFileExportPDFClick
      end
      object mnuFileExportComparison: TMenuItem
        Caption = 'Export comparison...'
        Hint = 'Export image comparison '#8212' side-by-side with original'
        OnClick = mnuFileExportComparisonClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object mnuFileInfo: TMenuItem
        Caption = 'Image info'
        Hint = 'Show image details'
        OnClick = mnuFileInfoClick
      end
      object mnuFileSepRecent: TMenuItem
        Caption = '-'
      end
      object mnuFileClose: TMenuItem
        Caption = 'Close'
        Hint = 'Close current image'
        ShortCut = 16471
        OnClick = mnuFileCloseClick
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object mnuFileExit: TMenuItem
        Caption = 'Quit'
        Hint = 'Quit the program'
        ShortCut = 16465
        OnClick = mnuFileExitClick
      end
    end
    object mnuEdit: TMenuItem
      Caption = 'Edit'
      object mnuEditUndo: TMenuItem
        Caption = 'Undo'
        Hint = 'Undo last operation'
        ShortCut = 16474
        OnClick = mnuEditUndoClick
      end
      object mnuEditRedo: TMenuItem
        Caption = 'Redo'
        Hint = 'Redo undone operation'
        ShortCut = 16473
        OnClick = mnuEditRedoClick
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object mnuEditCopy: TMenuItem
        Caption = 'Copy'
        Hint = 'Copy image to clipboard'
        ShortCut = 16451
        OnClick = mnuEditCopyClick
      end
      object mnuEditPaste: TMenuItem
        Caption = 'Paste'
        Hint = 'Paste image from clipboard as new layer'
        ShortCut = 16470
        OnClick = mnuEditPasteClick
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object mnuEditRevert: TMenuItem
        Caption = 'Revert to original'
        Hint = 'Restore image to original state'
        OnClick = mnuEditRevertClick
      end
      object mnuEditClearHistory: TMenuItem
        Caption = 'Clear history'
        Hint = 'Clear operation history - irreversible'
        OnClick = mnuEditClearHistoryClick
      end
    end
    object mnuView: TMenuItem
      Caption = 'View'
      object mnuViewZoomIn: TMenuItem
        Caption = 'Zoom in'
        Hint = 'Zoom in view'
        ShortCut = 16464
        OnClick = mnuViewZoomInClick
      end
      object mnuViewZoomOut: TMenuItem
        Caption = 'Zoom out'
        Hint = 'Zoom out view'
        ShortCut = 16461
        OnClick = mnuViewZoomOutClick
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object mnuViewFit: TMenuItem
        Caption = 'Fit to window'
        Hint = 'Fit image to window'
        ShortCut = 16432
        OnClick = mnuViewFitClick
      end
      object mnuView100: TMenuItem
        Caption = '100%'
        Hint = 'View at 1:1 scale'
        ShortCut = 16433
        OnClick = mnuView100Click
      end
      object mnuView50: TMenuItem
        Caption = '50%'
        Hint = 'View at 50% scale'
        OnClick = mnuView50Click
      end
      object mnuView25: TMenuItem
        Caption = '25%'
        Hint = 'View at 25% scale'
        OnClick = mnuView25Click
      end
      object mnuView200: TMenuItem
        Caption = '200%'
        Hint = 'View at 200% scale'
        OnClick = mnuView200Click
      end
      object mnuView400: TMenuItem
        Caption = '400%'
        Hint = 'View at 400% scale'
        OnClick = mnuView400Click
      end
    end
    object mnuCorrector: TMenuItem
      Caption = 'Adjust'
      object mnuFlipH: TMenuItem
        Caption = 'Mirror horizontally'
        Hint = 'Flip image horizontally'
        OnClick = mnuFlipHClick
      end
      object mnuFlipV: TMenuItem
        Caption = 'Mirror vertically'
        Hint = 'Flip image vertically'
        OnClick = mnuFlipVClick
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object mnuRotateLeft: TMenuItem
        Caption = 'Rotate left'
        Hint = 'Rotate image 90 degrees left'
        OnClick = mnuRotateLeftClick
      end
      object mnuRotateRight: TMenuItem
        Caption = 'Rotate right'
        Hint = 'Rotate image 90 degrees right'
        OnClick = mnuRotateRightClick
      end
      object mnuRotate180: TMenuItem
        Caption = 'Rotate 180'
        Hint = 'Rotate image 180 degrees'
        OnClick = mnuRotate180Click
      end
      object mnuStraighten: TMenuItem
        Caption = 'Straighten scan...'
        Hint = 'Straighten scan - rotate up to +/- 10 degrees with auto-crop'
        OnClick = mnuStraightenClick
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object mnuHistogram: TMenuItem
        Caption = 'Histogram...'
        Hint = 'Show color histogram'
        OnClick = mnuHistogramClick
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object mnuContrast: TMenuItem
        Caption = 'Contrast...'
        Hint = 'Adjust contrast'
        OnClick = mnuContrastClick
      end
      object mnuBrightness: TMenuItem
        Caption = 'Brightness...'
        Hint = 'Adjust brightness'
        OnClick = mnuBrightnessClick
      end
      object mnuGamma: TMenuItem
        Caption = 'Gamma correction...'
        Hint = 'Gamma correction'
        OnClick = mnuGammaClick
      end
      object mnuLevels: TMenuItem
        Caption = 'Levels...'
        Hint = 'Set black point, gamma and white point - full tonal control'
        OnClick = mnuLevelsClick
      end
      object mnuWB: TMenuItem
        Caption = 'White balance...'
        Hint = 'White balance - color temperature correction'
        OnClick = mnuWBClick
      end
      object mnuHSB: TMenuItem
        Caption = 'HSB balance...'
        Hint = 'Adjust brightness, saturation and hue'
        OnClick = mnuHSBClick
      end
      object mnuSharpen: TMenuItem
        Caption = 'Sharpen...'
        Hint = 'Sharpen image'
        OnClick = mnuSharpenClick
      end
      object N11: TMenuItem
        Caption = '-'
      end
      object mnuHDR1: TMenuItem
        Caption = 'Vivid...'
        Hint = 'Vivid - saturated, vibrant colours'
        OnClick = mnuHDR1Click
      end
      object mnuHDR2: TMenuItem
        Caption = 'Photo enhancement...'
        Hint = 'Photo enhancement (Multiply)'
        OnClick = mnuHDR2Click
      end
      object mnuEmergo: TMenuItem
        Caption = 'Emergo...'
        Hint = 'Emergo '#8212' intelligent shadow detail recovery'
        OnClick = mnuEmergoClick
      end
      object N13: TMenuItem
        Caption = '-'
      end
      object mnuResize: TMenuItem
        Caption = 'Resize...'
        Hint = 'Resize image'
        OnClick = mnuResizeClick
      end
      object mnuResizeCrop: TMenuItem
        Caption = 'Fit to size with crop...'
        Hint = 'Scale image to target size, cropping excess'
        OnClick = mnuResizeCropClick
      end
    end
    object mnuEffects: TMenuItem
      Caption = 'Effects'
      object mnuProcesy: TMenuItem
        Caption = 'Photographic processes'
        object mnuTint: TMenuItem
          Caption = 'Colorize...'
          Hint = 'Tint image with selected color'
          OnClick = mnuTintClick
        end
        object mnuDuotone: TMenuItem
          Caption = 'Duotone...'
          Hint = 'Two-color effect - shadows and highlights'
          OnClick = mnuDuotoneClick
        end
        object mnuTritone: TMenuItem
          Caption = 'Tritone...'
          Hint = 'Tritone'
          OnClick = mnuTritoneClick
        end
        object mnuQuadtone: TMenuItem
          Caption = 'Quad-tone...'
          Hint = 'Quad-tone'
          OnClick = mnuQuadtoneClick
        end
        object mnuSepia: TMenuItem
          Caption = 'Sepia...'
          Hint = 'Sepia - warm brown monochrome'
          OnClick = mnuSepiaClick
        end
        object mnuCyanotype: TMenuItem
          Caption = 'Cyanotype'
          Hint = 'Cyanotype - blue monochrome'
          OnClick = mnuCyanotypeClick
        end
        object mnuSaltprint: TMenuItem
          Caption = 'Salt print'
          Hint = 'Salt print - warm brown'
          OnClick = mnuSaltprintClick
        end
        object mnuXray: TMenuItem
          Caption = 'X-Ray'
          Hint = 'X-Ray - inverted colors'
          OnClick = mnuXrayClick
        end
        object mnuFalseIR: TMenuItem
          Caption = 'False-color infrared'
          Hint = 'False-color IR - channel swap, red plants, blue sky'
          OnClick = mnuFalseIRClick
        end
        object mnuNightVision: TMenuItem
          Caption = 'Night vision'
          Hint = 'Night vision - grayscale + green phosphor'
          OnClick = mnuNightVisionClick
        end
        object mnuThermal: TMenuItem
          Caption = 'Thermal'
          Hint = 'Thermal - false-color view'
          OnClick = mnuThermalClick
        end
        object mnuCrossProcess: TMenuItem
          Caption = 'Incorrect development...'
          Hint = 'Incorrect development '#8212' E-6/C-41 simulation'
          OnClick = mnuCrossProcessClick
        end
        object mnuOrton: TMenuItem
          Caption = 'Orton'
          Hint = 'Orton - blurred glow, dreamy mood'
          OnClick = mnuOrtonClick
        end
        object mnuFilmGrain: TMenuItem
          Caption = 'Film grain...'
          Hint = 'Add film grain - random noise'
          OnClick = mnuFilmGrainClick
        end
        object mnuSolarize: TMenuItem
          Caption = 'Solarize...'
          Hint = 'Solarize - invert bright tones'
          OnClick = mnuSolarizeClick
        end
        object mnuGray: TMenuItem
          Caption = 'Grayscale'
          Hint = 'Convert to grayscale'
          OnClick = mnuGrayClick
        end
        object mnuInvert: TMenuItem
          Caption = 'Negative'
          Hint = 'Invert colors - negative'
          OnClick = mnuInvertClick
        end
      end
      object mnuArtystyczne: TMenuItem
        Caption = 'Artistic'
        object mnuBW: TMenuItem
          Caption = 'Black & white...'
          Hint = 'Convert to B&W with dither option'
          OnClick = mnuBWClick
        end
        object mnuOleo: TMenuItem
          Caption = 'Oil paint...'
          Hint = 'Oil paint - brush simulation'
          OnClick = mnuOleoClick
        end
        object mnuCharcoal: TMenuItem
          Caption = 'Charcoal...'
          Hint = 'Charcoal - charcoal drawing simulation'
          OnClick = mnuCharcoalClick
        end
        object mnuObrys: TMenuItem
          Caption = 'Outline...'
          Hint = 'Outline'
          OnClick = mnuObrysClick
        end
        object mnuEdge: TMenuItem
          Caption = 'Edge detection...'
          Hint = 'Edge detection - sketch effect'
          OnClick = mnuEdgeClick
        end
        object mnuBlur: TMenuItem
          Caption = 'Blur...'
          Hint = 'Blur image'
          OnClick = mnuBlurClick
        end
        object mnuEmboss: TMenuItem
          Caption = 'Emboss...'
          Hint = 'Emboss - relief'
          OnClick = mnuEmbossClick
        end
        object mnuRelief: TMenuItem
          Caption = 'Relief...'
          Hint = 'Material bas-relief from image luminance'
          OnClick = mnuReliefClick
        end
        object mnuGlow: TMenuItem
          Caption = 'Glow...'
          Hint = 'Glow...'
          OnClick = mnuGlowClick
        end
        object mnuQuantize: TMenuItem
          Caption = 'Posterize...'
          Hint = 'Posterize - reduce color count'
          OnClick = mnuQuantizeClick
        end
        object mnuPixelate: TMenuItem
          Caption = 'Pixelate...'
          Hint = 'Pixelate - mosaic effect'
          OnClick = mnuPixelateClick
        end
        object mnuVignette: TMenuItem
          Caption = 'Vignette...'
          Hint = 'Vignette - darken edges'
          OnClick = mnuVignetteClick
        end
        object mnuBokeh: TMenuItem
          Caption = 'Fake bokeh...'
          Hint = 'Artificial bokeh'
          OnClick = mnuBokehClick
        end
        object mnuMakieta: TMenuItem
          Caption = 'Tilt-shift (miniature)...'
          Hint = 'Graduated blur'
          OnClick = mnuMakietaClick
        end
        object mnuGlitch: TMenuItem
          Caption = 'Glitch...'
          Hint = 
            'Digital image distortion '#8212' RGB shift, noise, horizontal slice sh' +
            'ift'
          OnClick = mnuGlitchClick
        end
      end
      object mnuDistort: TMenuItem
        Caption = 'Distortions'
        object mnuBarrel: TMenuItem
          Caption = 'Barrel distortion...'
          Hint = 'Barrel / pincushion distortion'
          OnClick = mnuBarrelClick
        end
        object mnuArc: TMenuItem
          Caption = 'Arc distortion...'
          Hint = 'Arc distortion - bend image'
          OnClick = mnuArcClick
        end
        object mnuSwirl: TMenuItem
          Caption = 'Swirl...'
          Hint = 'Swirl - twist image'
          OnClick = mnuSwirlClick
        end
        object mnuWaterRipple: TMenuItem
          Caption = 'Water ripple...'
          Hint = 'Water ripple effect'
          OnClick = mnuWaterRippleClick
        end
        object mnuPolar: TMenuItem
          Caption = 'Polar distortion...'
          Hint = 'Polar distortion - tunnel, fisheye'
          OnClick = mnuPolarClick
        end
      end
      object N15: TMenuItem
        Caption = '-'
      end
      object mnuBlend: TMenuItem
        Caption = 'Effect Blend...'
        Hint = 'Blend two effects with a slider'
        OnClick = mnuBlendClick
      end
    end
    object mnuPrint: TMenuItem
      Caption = 'Print'
      object mnuCMYK: TMenuItem
        Caption = 'CMYK misregistration...'
        Hint = 'CMYK misregistration'
        OnClick = mnuCMYKClick
      end
      object N16: TMenuItem
        Caption = '-'
      end
      object mnuLinocut: TMenuItem
        Caption = 'Linocut...'
        Hint = 'Linocut - sharp B&W contrast'
        OnClick = mnuLinocutClick
      end
      object N17: TMenuItem
        Caption = '-'
      end
      object mnuStencil: TMenuItem
        Caption = 'Mimeograph...'
        Hint = 'Mimeograph '#8212' ink edges on white background'
        OnClick = mnuStencilClick
      end
      object N18: TMenuItem
        Caption = '-'
      end
      object mnuEngraving: TMenuItem
        Caption = 'Engraving...'
        Hint = 'Engraving - line engraving simulation'
        OnClick = mnuEngravingClick
      end
      object mnuCrosshatch: TMenuItem
        Caption = 'Crosshatch...'
        Hint = 'Crosshatch lines at two angles'
        OnClick = mnuCrosshatchClick
      end
      object mnuHalftone: TMenuItem
        Caption = 'Halftone...'
        Hint = 'Halftone - growing dots based on brightness'
        OnClick = mnuHalftoneClick
      end
      object mnuStipple: TMenuItem
        Caption = 'Stipple...'
        Hint = 'Stipple - dot density based on brightness'
        OnClick = mnuStippleClick
      end
      object mnuDice: TMenuItem
        Caption = 'Dice...'
        Hint = 'Dice - dice eyes pattern'
        OnClick = mnuDiceClick
      end
      object N19: TMenuItem
        Caption = '-'
      end
      object mnuScreenPrint: TMenuItem
        Caption = 'Screen print...'
        Hint = 'Single-color screen print - grayscale + halftone on background'
        OnClick = mnuScreenPrintClick
      end
      object mnuRiso: TMenuItem
        Caption = 'Risograph v1...'
        Hint = 'Risograph - layered print with color offset'
        OnClick = mnuRisoClick
      end
      object mnuRisoV2: TMenuItem
        Caption = 'Risograph v2...'
        Hint = 'Risograph - layered print with color offset'
        OnClick = mnuRisoV2Click
      end
      object mnuRisoV3: TMenuItem
        Caption = 'Risograph v3...'
        Hint = 'Risograph - layered print with color offset'
        OnClick = mnuRisoV3Click
      end
      object mnuTshirt: TMenuItem
        Caption = 'T-Shirt Design...'
        Hint = 'Simulate screenprint raster'
        OnClick = mnuTshirtClick
      end
      object mnuRastrCMYK: TMenuItem
        Caption = 'Raster CMYK...'
        OnClick = mnuRastrCMYKClick
      end
    end
    object mnuMacro: TMenuItem
      Caption = 'Macro'
      object mnuMacroStart: TMenuItem
        Caption = 'Start recording'
        Hint = 'Start recording a macro'
        OnClick = mnuMacroStartClick
      end
      object mnuMacroStop: TMenuItem
        Caption = 'Stop and save'
        Enabled = False
        Hint = 'Stop recording and save the macro'
        OnClick = mnuMacroStopClick
      end
      object mnuMacroCancel: TMenuItem
        Caption = 'Cancel recording'
        Enabled = False
        Hint = 'Cancel recording without saving'
        OnClick = mnuMacroCancelClick
      end
      object N20: TMenuItem
        Caption = '-'
      end
      object mnuBatch: TMenuItem
        Caption = 'Batch processing...'
        Hint = 'Apply a saved macro to all images in a folder'
        OnClick = mnuBatchClick
      end
      object mnuMacroManage: TMenuItem
        Caption = 'Manage macros...'
        Hint = 'Play, rename or delete macros'
        OnClick = mnuMacroManageClick
      end
    end
    object mnuTools: TMenuItem
      Caption = 'Tools'
      object mnuSelPanel: TMenuItem
        Caption = 'Selection...'
        OnClick = mnuSelPanelClick
      end
      object mnuSelSize: TMenuItem
        Caption = 'Selection size...'
        Hint = 'Selection size'
        ShortCut = 24658
        OnClick = mnuSelSizeClick
      end
      object mnuCropToSel: TMenuItem
        Caption = 'Crop to selection'
        Hint = 'Crop to selection'
        ShortCut = 16472
        OnClick = mnuCropToSelClick
      end
      object N23: TMenuItem
        Caption = '-'
      end
      object mnuTimelapse: TMenuItem
        Caption = 'Timelapse...'
        OnClick = mnuTimelapseClick
      end
      object mnuTiles: TMenuItem
        Caption = 'Tiling...'
        Hint = 'Tile image to fill target dimensions'
        OnClick = mnuTilesClick
      end
      object mnuStereogram: TMenuItem
        Caption = 'Stereogram...'
        OnClick = mnuStereogramClick
      end
      object mnuRemoveBackground: TMenuItem
        Caption = 'Remove background...'
        OnClick = mnuRemoveBackgroundClick
      end
      object mnuToolsPanel: TMenuItem
        Caption = 'Retouch...'
        OnClick = mnuToolsPanelClick
      end
      object N24: TMenuItem
        Caption = '-'
      end
      object mnuProtMask: TMenuItem
        Caption = 'Protection mask'
        object mnuProtFromSel: TMenuItem
          Caption = 'Protect selection'
          Hint = 'Protect the selected area from effects'
          OnClick = mnuProtFromSelClick
        end
        object mnuProtUnprotSel: TMenuItem
          Caption = 'Unprotect selection'
          Hint = 'Remove protection from the selected area'
          OnClick = mnuProtUnprotSelClick
        end
        object N28: TMenuItem
          Caption = '-'
        end
        object mnuProtShow: TMenuItem
          Caption = 'Show protection mask'
          Hint = 'Shows protected areas with diagonal red overlay'
          OnClick = mnuProtShowClick
        end
        object mnuProtClear: TMenuItem
          Caption = 'Clear protection mask'
          Hint = 'Remove all protected areas'
          OnClick = mnuProtClearClick
        end
      end
    end
    object mnuAmiga: TMenuItem
      Caption = 'Amiga'
      object mnuWB1: TMenuItem
        Caption = 'Workbench 1.x palette (OCS)'
        Hint = '4-color palette - Workbench 1.x (OCS)'
        OnClick = mnuWB1Click
      end
      object mnuWB2: TMenuItem
        Caption = 'Workbench 2.x/3.x palette'
        Hint = '4-color palette - Workbench 2.x/3.x'
        OnClick = mnuWB2Click
      end
      object mnuOCS32: TMenuItem
        Caption = 'OCS 32-color palette...'
        Hint = '32-color palette (4x4x2) - OCS'
        OnClick = mnuOCS32Click
      end
      object mnuEHB: TMenuItem
        Caption = 'EHB 64-color palette...'
        Hint = '64-color palette (4x4x4) - EHB'
        OnClick = mnuEHBClick
      end
      object mnuAGA256: TMenuItem
        Caption = 'AGA 256-color palette...'
        Hint = '256-color palette - AGA'
        OnClick = mnuAGA256Click
      end
      object mnuWB256: TMenuItem
        Caption = 'Workbench 256-color palette...'
        Hint = '256-color palette - Workbench 3.x'
        OnClick = mnuWB256Click
      end
      object mnuMagicWB: TMenuItem
        Caption = 'MagicWB palette (8 colors)...'
        Hint = '8-color palette - MagicWB (MUI)'
        OnClick = mnuMagicWBClick
      end
      object mnuHAM6: TMenuItem
        Caption = 'HAM6 - 16 colors + Hold-Modify'
        Hint = 'HAM6 simulation (16 base colors with hold-modify modes)'
        OnClick = mnuHAM6Click
      end
      object mnuHAM8: TMenuItem
        Caption = 'HAM8 - 64 colors + Hold-Modify'
        Hint = 'HAM8 simulation (64 base colors with hold-modify modes)'
        OnClick = mnuHAM8Click
      end
      object mnuAmigaGradient: TMenuItem
        Caption = 'Amiga gradient...'
        Hint = 'Amiga-style copper gradient overlay'
        OnClick = mnuAmigaGradientClick
      end
      object mnuAmigaGradientAgony: TMenuItem
        Caption = 'Amiga gradient (Agony)...'
        Hint = 'Agony-style copper gradient'
        OnClick = mnuAmigaGradientAgonyClick
      end
      object mnuAmigaBG: TMenuItem
        Caption = 'Amiga Background...'
        Hint = 'Amiga Background...'
        OnClick = mnuAmigaBGClick
      end
      object mnuAmigaBGS: TMenuItem
        Caption = 'Amiga Background (stretched, MagicWB)...'
        Hint = 'Scale image to Amiga resolution with stretched edge fill'
        OnClick = mnuAmigaBGSClick
      end
    end
    object mnuRetro: TMenuItem
      Caption = 'Other retro computers'
      object mnuC64: TMenuItem
        Caption = 'C64 '#8212' Pepto / Colodore...'
        Hint = 'Map to Commodore 64 palette with dithering'
        OnClick = mnuC64Click
      end
      object mnuZXSpectrum: TMenuItem
        Caption = 'ZX Spectrum...'
        Hint = 'Map to ZX Spectrum palette with dithering'
        OnClick = mnuZXSpectrumClick
      end
      object mnuGameBoy: TMenuItem
        Caption = 'Game Boy '#8212' DMG / Pocket...'
        Hint = 'Map to Game Boy palette with dithering'
        OnClick = mnuGameBoyClick
      end
      object mnuNES: TMenuItem
        Caption = 'NES (Nestopia)...'
        Hint = 'Map to NES Nestopia palette with dithering'
        OnClick = mnuNESClick
      end
    end
    object mnuSettings: TMenuItem
      Caption = 'Settings'
      object mnuSettingsLang: TMenuItem
        Caption = 'Language...'
        Hint = 'Change application language'
        OnClick = mnuSettingsLangClick
      end
      object mnuSettingsQuality: TMenuItem
        Caption = 'Export quality...'
        Hint = 'Set JPEG, JPEG 2000 and TIFF export quality'
        OnClick = mnuSettingsQualityClick
      end
      object mnuSettingsInterface: TMenuItem
        Tag = 1
        Caption = 'Interface...'
        Hint = 'Interface settings'
        OnClick = mnuSettingsInterfaceClick
      end
      object mnuSettingsPerformance: TMenuItem
        Caption = 'Performance...'
        Hint = 'Performance and maximum working resolution'
        OnClick = mnuSettingsPerformanceClick
      end
    end
    object mnuHelp: TMenuItem
      Caption = 'Help'
      object mnuLauncher: TMenuItem
        Caption = 'Launcher'
        Hint = 'Quick action launcher'
        ShortCut = 87
        OnClick = mnuLauncherClick
      end
      object mnuHelpAbout: TMenuItem
        Caption = 'About'
        Hint = 'About Fotografista'
        OnClick = mnuHelpAboutClick
      end
      object N25: TMenuItem
        Caption = '-'
      end
      object mnuHelpShortcuts: TMenuItem
        Caption = 'Keyboard shortcuts'
        Hint = 'Show keyboard shortcuts'
        OnClick = mnuHelpShortcutsClick
      end
      object N26: TMenuItem
        Caption = '-'
      end
      object mnuHelpBenchmark: TMenuItem
        Caption = 'Performance measurement'
        Hint = 'Measure the performance of graphic effects'
        OnClick = mnuHelpBenchmarkClick
      end
      object N27: TMenuItem
        Caption = '-'
      end
      object mnuHelpOnlineDocs: TMenuItem
        Caption = 'Online documentation'
        Hint = 'Open the Fotografista website in your web browser'
        OnClick = mnuHelpOnlineDocsClick
      end
    end
  end
end
