unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.GDIPUTIL,
  System.SysUtils, System.Classes, System.Math, System.UITypes, System.Diagnostics, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.Menus, Vcl.ComCtrls, Vcl.Clipbrd, Vcl.AppEvnts,
   Vcl.StdCtrls, Vcl.Imaging.jpeg, Vcl.Themes, fpdf, uImageIO, uPrefs, uTransform, uUndo, frmInterfaceDlg, frmFileInfoDlg, frmKolorowanieDlg, uI18n, frmLanguageDlg,
  frmQualityDlg, frmPerformanceDlg, frmStraightenDlg, frmHistogramDlg, frmContrastDlg,
  frmCmykDlg,
  frmLinocutDlg,
  frmStencilDlg,
  frmEngravingDlg,
  frmCrosshatchDlg,
  frmHalftoneDlg,
  frmStippleDlg,
  frmDiceDlg,
  frmScreenPrintDlg,
  frmRastrCmykDlg,
  frmBatchDlg,
  frmTimelapseDlg,
  uQuantize, uRiso, uRastrCMYK, frmRisoDlg, frmRisoV3Dlg,
  uTshirt, frmTshirtDlg,
  frmBrightnessDlg, frmGammaDlg, frmLevelsDlg, frmWBDlg, frmHSBDlg,
   frmSharpenDlg, frmHDR1Dlg, frmWzmocnienieDlg, frmEmergoDlg,
   uSelection, frmSelSizeDlg, uAmiga, frmResizeDlg, frmResizeCropDlg,
    frmTileDlg, AboutBoxUnit, uDuotone, frmDuotoneDlg, frmSepiaDlg,
    frmSolarizeDlg, frmBWDlg, frmFilmGrainDlg, frmOleoDlg, frmCharcoalDlg, frmObrysDlg, frmBlurDlg,
     frmEmbossDlg, frmPixelateDlg, frmStereogramDlg, uStereogram, frmVignetteDlg, frmBokehDlg, frmMakietaDlg, frmEdgeDlg, frmReliefDlg, frmQuantizeDlg, frmGlowDlg, frmCrossProcessDlg, frmGlitchDlg, uConvolution, frmBlendDlg, frmPaletteDlg, GR32, uMipMap, uMacros,
     frmAmigaGradientDlg, frmAgonyDlg, frmAmigaBGDlg, frmAmigaBGSDlg,
      frmC64Dlg, frmZXSpectrumDlg, frmGameBoyDlg, frmNESDlg, uDistort, frmDistortDlg,
      frmWaterRippleDlg, frmLauncherDlg, frmShortcutsDlg, frmBenchmarkDlg, uTitleBar,
      uCanvasTools, frmToolsDlg, frmUsunTloDlg, frmSelDlg;

type
  { Narzędzia kanwy dostępne w panelu Narzędzi. Rozszerzany przy dodawaniu
    nowych narzędzi (zakraplacz, wiadro, lasso, pędzle...). }
  TToolKind = (tkSelection, tkEraser, tkEyedropper, tkBucket, tkBrush, tkProtect);

  { Tryb pędzla RGB (narzędzie tkBrush): rodzaj przekształcenia pikseli w
    dysku pędzla. Wybór mieszka w frmMain (FBrushMode), panel ma combo. }
  TBrushMode = (bmPaint, bmClone, bmDodge, bmBurn, bmSharpen, bmBlur,
    bmColorReplace);

  TfrmMain = class(TFotoForm)
    MainMenu: TMainMenu;
    StatusBar: TStatusBar;
    ScrollBox: TScrollBox;
    PaintBox: TPaintBox;

    { Plik }
    mnuFile: TMenuItem;
    mnuFileOpen: TMenuItem;
    mnuFileSaveAs: TMenuItem;
    N1: TMenuItem;
    mnuFileExportPDF: TMenuItem;
    mnuFileExportComparison: TMenuItem;
    N2: TMenuItem;
    mnuFileInfo: TMenuItem;
    mnuFileSepRecent: TMenuItem;
    mnuFileClose: TMenuItem;
    N4: TMenuItem;
    mnuFileExit: TMenuItem;

    { Edycja }
    mnuEdit: TMenuItem;
    mnuEditUndo: TMenuItem;
    mnuEditRedo: TMenuItem;
    N5: TMenuItem;
    mnuEditCopy: TMenuItem;
    mnuEditPaste: TMenuItem;
    N6: TMenuItem;
    mnuEditRevert: TMenuItem;
    mnuEditClearHistory: TMenuItem;

    { Widok }
    mnuView: TMenuItem;
    mnuViewZoomIn: TMenuItem;
    mnuViewZoomOut: TMenuItem;
    N7: TMenuItem;
    mnuViewFit: TMenuItem;
    mnuView100: TMenuItem;
    mnuView50: TMenuItem;
    mnuView25: TMenuItem;
    mnuView200: TMenuItem;
    mnuView400: TMenuItem;

    { Korektor }
    mnuCorrector: TMenuItem;
    mnuFlipH: TMenuItem;
    mnuFlipV: TMenuItem;
    N8: TMenuItem;
    mnuRotateLeft: TMenuItem;
    mnuRotateRight: TMenuItem;
    mnuRotate180: TMenuItem;
    mnuStraighten: TMenuItem;
    N9: TMenuItem;
    mnuHistogram: TMenuItem;
    N10: TMenuItem;
    mnuContrast: TMenuItem;
    mnuBrightness: TMenuItem;
    mnuGamma: TMenuItem;
    mnuLevels: TMenuItem;
    mnuWB: TMenuItem;
    mnuHSB: TMenuItem;
    mnuSharpen: TMenuItem;
    N11: TMenuItem;
    mnuHDR1: TMenuItem;
    mnuHDR2: TMenuItem;
    mnuEmergo: TMenuItem;
    mnuSelSize: TMenuItem;
    mnuCropToSel: TMenuItem;
    N13: TMenuItem;
    mnuResize: TMenuItem;
    mnuResizeCrop: TMenuItem;
    mnuTiles: TMenuItem;

    { Efekty }
    mnuEffects: TMenuItem;
    mnuProcesy: TMenuItem;
    mnuTint: TMenuItem;
    mnuDuotone: TMenuItem;
    mnuTritone: TMenuItem;
    mnuQuadtone: TMenuItem;
    mnuSepia: TMenuItem;
    mnuCyanotype: TMenuItem;
    mnuSaltprint: TMenuItem;
    mnuXray: TMenuItem;
    mnuFalseIR: TMenuItem;
    mnuNightVision: TMenuItem;
    mnuThermal: TMenuItem;
    mnuCrossProcess: TMenuItem;
    mnuOrton: TMenuItem;
    mnuFilmGrain: TMenuItem;
    mnuSolarize: TMenuItem;
    mnuGray: TMenuItem;
    mnuInvert: TMenuItem;
    mnuArtystyczne: TMenuItem;
    mnuBW: TMenuItem;
    mnuOleo: TMenuItem;
    mnuCharcoal: TMenuItem;
    mnuObrys: TMenuItem;
    mnuEdge: TMenuItem;
    mnuBlur: TMenuItem;
    mnuEmboss: TMenuItem;
    mnuRelief: TMenuItem;
    mnuGlow: TMenuItem;
    mnuQuantize: TMenuItem;
    mnuPixelate: TMenuItem;
    mnuVignette: TMenuItem;
    mnuBokeh: TMenuItem;
    mnuMakieta: TMenuItem;
    mnuGlitch: TMenuItem;
    N15: TMenuItem;
    mnuBlend: TMenuItem;

    { Druk }
    mnuPrint: TMenuItem;
    mnuCMYK: TMenuItem;
    N16: TMenuItem;
    mnuLinocut: TMenuItem;
    N17: TMenuItem;
    mnuStencil: TMenuItem;
    N18: TMenuItem;
    mnuEngraving: TMenuItem;
    mnuCrosshatch: TMenuItem;
    mnuHalftone: TMenuItem;
    mnuStipple: TMenuItem;
    mnuDice: TMenuItem;
    N19: TMenuItem;
    mnuScreenPrint: TMenuItem;
    mnuRiso: TMenuItem;
    mnuRisoV2: TMenuItem;
    mnuRisoV3: TMenuItem;
    mnuTshirt: TMenuItem;
    mnuRastrCMYK: TMenuItem;

    { Makro }
    mnuMacro: TMenuItem;
    mnuMacroStart: TMenuItem;
    mnuMacroStop: TMenuItem;
    mnuMacroCancel: TMenuItem;
    N20: TMenuItem;
    mnuBatch: TMenuItem;
    mnuMacroManage: TMenuItem;

    { Narzędzia }
    mnuTools: TMenuItem;
    mnuTimelapse: TMenuItem;
    mnuStereogram: TMenuItem;
    mnuRemoveBackground: TMenuItem;
    mnuToolsPanel: TMenuItem;
    mnuSelPanel: TMenuItem;
    mnuProtMask: TMenuItem;
    mnuProtFromSel: TMenuItem;
    mnuProtUnprotSel: TMenuItem;
    mnuProtShow: TMenuItem;
    mnuProtClear: TMenuItem;

    { Zniekształcenia }
    mnuDistort: TMenuItem;
    mnuBarrel: TMenuItem;
    mnuArc: TMenuItem;
    mnuSwirl: TMenuItem;
    mnuWaterRipple: TMenuItem;
    mnuPolar: TMenuItem;

    { Amigowe }
    mnuAmiga: TMenuItem;
    mnuWB1: TMenuItem;
    mnuWB2: TMenuItem;
    mnuOCS32: TMenuItem;
    mnuEHB: TMenuItem;
    mnuAGA256: TMenuItem;
    mnuWB256: TMenuItem;
    mnuMagicWB: TMenuItem;
    N21: TMenuItem;
    mnuHAM6: TMenuItem;
    mnuHAM8: TMenuItem;
    N22: TMenuItem;
    mnuAmigaGradient: TMenuItem;
    mnuAmigaGradientAgony: TMenuItem;
    N23: TMenuItem;
    mnuAmigaBG: TMenuItem;
    mnuAmigaBGS: TMenuItem;

    { Inne retrokomputery }
    mnuRetro: TMenuItem;
    mnuC64: TMenuItem;
    mnuZXSpectrum: TMenuItem;
    mnuGameBoy: TMenuItem;
    mnuNES: TMenuItem;

    { Ustawienia }
    mnuSettings: TMenuItem;
    mnuSettingsLang: TMenuItem;
    mnuSettingsQuality: TMenuItem;
    mnuSettingsInterface: TMenuItem;
    mnuSettingsPerformance: TMenuItem;

    { Pomoc }
    mnuHelp: TMenuItem;
    mnuLauncher: TMenuItem;
    N24: TMenuItem;
    mnuHelpAbout: TMenuItem;
    N25: TMenuItem;
    mnuHelpShortcuts: TMenuItem;
    N26: TMenuItem;
    mnuHelpBenchmark: TMenuItem;
    N27: TMenuItem;
    mnuHelpOnlineDocs: TMenuItem;

    { Form }
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure ScrollBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScrollBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ScrollBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ScrollBoxMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure ScrollBoxMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    { Plik }
    procedure mnuFileOpenClick(Sender: TObject);
    procedure mnuFileSaveAsClick(Sender: TObject);
    procedure mnuFileExportPDFClick(Sender: TObject);
    procedure mnuFileExportComparisonClick(Sender: TObject);
    procedure mnuFileInfoClick(Sender: TObject);
    procedure mnuFileCloseClick(Sender: TObject);
    procedure mnuFileExitClick(Sender: TObject);

    { Edycja }
    procedure mnuEditUndoClick(Sender: TObject);
    procedure mnuEditRedoClick(Sender: TObject);
    procedure mnuEditCopyClick(Sender: TObject);
    procedure mnuEditPasteClick(Sender: TObject);
    procedure mnuEditRevertClick(Sender: TObject);
    procedure mnuEditClearHistoryClick(Sender: TObject);

    { Widok }
    procedure mnuViewZoomInClick(Sender: TObject);
    procedure mnuViewZoomOutClick(Sender: TObject);
    procedure mnuViewFitClick(Sender: TObject);
    procedure mnuView100Click(Sender: TObject);
    procedure mnuView50Click(Sender: TObject);
    procedure mnuView25Click(Sender: TObject);
    procedure mnuView200Click(Sender: TObject);
    procedure mnuView400Click(Sender: TObject);

    { Korektor }
    procedure mnuFlipHClick(Sender: TObject);
    procedure mnuFlipVClick(Sender: TObject);
    procedure mnuRotateLeftClick(Sender: TObject);
    procedure mnuRotateRightClick(Sender: TObject);
    procedure mnuRotate180Click(Sender: TObject);
    procedure mnuStraightenClick(Sender: TObject);
    procedure mnuHistogramClick(Sender: TObject);
    procedure mnuContrastClick(Sender: TObject);
    procedure mnuBrightnessClick(Sender: TObject);
    procedure mnuGammaClick(Sender: TObject);
    procedure mnuLevelsClick(Sender: TObject);
    procedure mnuWBClick(Sender: TObject);
    procedure mnuHSBClick(Sender: TObject);
    procedure mnuSharpenClick(Sender: TObject);
    procedure mnuHDR1Click(Sender: TObject);
    procedure mnuHDR2Click(Sender: TObject);
    procedure mnuEmergoClick(Sender: TObject);
    procedure mnuSelSizeClick(Sender: TObject);
    procedure mnuCropToSelClick(Sender: TObject);
    procedure mnuResizeClick(Sender: TObject);
    procedure mnuResizeCropClick(Sender: TObject);
    procedure mnuTilesClick(Sender: TObject);
    procedure mnuTimelapseClick(Sender: TObject);
    procedure mnuToolsPanelClick(Sender: TObject);
    procedure mnuSelPanelClick(Sender: TObject);
    procedure mnuRemoveBackgroundClick(Sender: TObject);
    procedure mnuProtShowClick(Sender: TObject);
    procedure mnuProtClearClick(Sender: TObject);
    procedure mnuProtFromSelClick(Sender: TObject);
    procedure mnuProtUnprotSelClick(Sender: TObject);

    { Efekty }
    procedure mnuTintClick(Sender: TObject);
    procedure mnuDuotoneClick(Sender: TObject);
    procedure mnuTritoneClick(Sender: TObject);
    procedure mnuQuadtoneClick(Sender: TObject);
    procedure mnuSepiaClick(Sender: TObject);
    procedure mnuCyanotypeClick(Sender: TObject);
    procedure mnuSaltprintClick(Sender: TObject);
    procedure mnuXrayClick(Sender: TObject);
    procedure mnuFalseIRClick(Sender: TObject);
    procedure mnuNightVisionClick(Sender: TObject);
    procedure mnuThermalClick(Sender: TObject);
    procedure mnuOrtonClick(Sender: TObject);
    procedure mnuBWClick(Sender: TObject);
    procedure mnuGrayClick(Sender: TObject);
    procedure mnuInvertClick(Sender: TObject);
    procedure mnuSolarizeClick(Sender: TObject);
    procedure mnuFilmGrainClick(Sender: TObject);
    procedure mnuOleoClick(Sender: TObject);
    procedure mnuCharcoalClick(Sender: TObject);
    procedure mnuObrysClick(Sender: TObject);
    procedure mnuBlurClick(Sender: TObject);
    procedure mnuEmbossClick(Sender: TObject);
    procedure mnuReliefClick(Sender: TObject);
    procedure mnuPixelateClick(Sender: TObject);
    procedure mnuStereogramClick(Sender: TObject);
    procedure mnuVignetteClick(Sender: TObject);
    procedure mnuBokehClick(Sender: TObject);
    procedure mnuMakietaClick(Sender: TObject);
    procedure mnuQuantizeClick(Sender: TObject);
    procedure mnuEdgeClick(Sender: TObject);
    procedure mnuGlowClick(Sender: TObject);
    procedure mnuCrossProcessClick(Sender: TObject);
    procedure mnuGlitchClick(Sender: TObject);
    procedure mnuBlendClick(Sender: TObject);

    { Druk }
    procedure mnuCMYKClick(Sender: TObject);
    procedure mnuLinocutClick(Sender: TObject);
    procedure mnuStencilClick(Sender: TObject);
    procedure mnuEngravingClick(Sender: TObject);
    procedure mnuCrosshatchClick(Sender: TObject);
    procedure mnuHalftoneClick(Sender: TObject);
    procedure mnuStippleClick(Sender: TObject);
    procedure mnuDiceClick(Sender: TObject);
    procedure mnuScreenPrintClick(Sender: TObject);
    procedure mnuRastrCMYKClick(Sender: TObject);
    procedure mnuRisoClick(Sender: TObject);
    procedure mnuRisoV2Click(Sender: TObject);
    procedure mnuRisoV3Click(Sender: TObject);
    procedure mnuTshirtClick(Sender: TObject);

    { Makro }
    procedure mnuMacroStartClick(Sender: TObject);
    procedure mnuMacroStopClick(Sender: TObject);
    procedure mnuMacroCancelClick(Sender: TObject);
    procedure mnuBatchClick(Sender: TObject);
    procedure mnuMacroManageClick(Sender: TObject);

    { Zniekształcenia }
    procedure mnuBarrelClick(Sender: TObject);
    procedure mnuArcClick(Sender: TObject);
    procedure mnuSwirlClick(Sender: TObject);
    procedure mnuWaterRippleClick(Sender: TObject);
    procedure mnuPolarClick(Sender: TObject);

    { Amigowe }
    procedure mnuWB1Click(Sender: TObject);
    procedure mnuWB2Click(Sender: TObject);
    procedure mnuOCS32Click(Sender: TObject);
    procedure mnuEHBClick(Sender: TObject);
    procedure mnuAGA256Click(Sender: TObject);
    procedure mnuWB256Click(Sender: TObject);
    procedure mnuMagicWBClick(Sender: TObject);
    procedure mnuHAM6Click(Sender: TObject);
    procedure mnuHAM8Click(Sender: TObject);
    procedure mnuAmigaGradientClick(Sender: TObject);
    procedure mnuAmigaGradientAgonyClick(Sender: TObject);
    procedure mnuAmigaBGClick(Sender: TObject);
    procedure mnuAmigaBGSClick(Sender: TObject);

    { Inne retrokomputery }
    procedure mnuC64Click(Sender: TObject);
    procedure mnuZXSpectrumClick(Sender: TObject);
    procedure mnuGameBoyClick(Sender: TObject);
    procedure mnuNESClick(Sender: TObject);

    { Ustawienia }
    procedure mnuSettingsLangClick(Sender: TObject);
    procedure mnuSettingsQualityClick(Sender: TObject);
    procedure mnuSettingsInterfaceClick(Sender: TObject);
    procedure mnuSettingsPerformanceClick(Sender: TObject);

    { Pomoc }
    procedure mnuLauncherClick(Sender: TObject);
    procedure mnuHelpAboutClick(Sender: TObject);
    procedure mnuHelpShortcutsClick(Sender: TObject);
    procedure mnuHelpBenchmarkClick(Sender: TObject);
    procedure mnuHelpOnlineDocsClick(Sender: TObject);

    { Do paska statusu }
    procedure SetOperationInfo(const OpName: string; Seconds: Double);
    procedure EnsureMipPyramid;
    procedure BuildSmoothPreview;
    procedure BuildPlainPreview;
    procedure InvalidatePreviewCache;

  private
    FBitmap: TBitmap;
    FMipPyramid: TMipPyramid;      // pre-filter rastra: piramida mip-map, klucz: SourceHandle
    FMipLevelBmp: TBitmap;         // konwersja wybranego poziomu (TBitmap32) do TBitmap24 do StretchDraw
    FMipLevelKey: THandle;         // klucz konwersji: handle źródła
    FMipLevelIdx: Integer;         // klucz konwersji: indeks poziomu (0 = ostry FBitmap)
    FScaleCache: TBitmap;          // rozmyte+skalowane do disp (per zoom), klucz: (handle, zoom)
    FScaleCacheHandle: THandle;
    FScaleCacheZoom: Double;
    FRasterPreview: Boolean;       // podgląd = periodyczny raster (riso/sitodruk/nadruk) -> pre-blur przy zoom<100%
    FZoomFactor: Double;
    FFilePath: string;
    FDirty: Boolean;
    FWandDebounceTimer: TTimer;
    FSelecting: Boolean;
    FSelMode: string;
    FSelHandle: THitHandle;
    FSelMoveOx, FSelMoveOy: Double;
    FSelMoveW, FSelMoveH: Double;
    FLassoPts: TArray<TPoint>;     // bieżąca ścieżka lassa (koord. obrazu)
    FLassoDrawing: Boolean;        // trwa rysowanie lassa (podgląd polilinii)
    FPanning: Boolean;
    FPanOrgX, FPanOrgY: Integer;
    FPanOrgSX, FPanOrgSY: Integer;
    FMacroMgrForm: TForm;
    FMacroMgrList: TListBox;
    FMacroMgrSteps: TListBox;
    FLauncherDlg: TLauncherDlg;
    FToolsDlg: TToolsDlg;
    FRetouchBrushSize: Integer;
    FRetouchStrength: Integer;
    FRetouchTolerance: Integer;
    FBrushMode: TBrushMode;
    FReplaceColor: TColor;
    FReplaceRetainShading: Boolean;   // zamiana koloru: 0 = pelna podmiana, 1 = zachowaj modelunek cieni
    FProtectCover: Boolean;
    FForeColor: TColor;
    FActiveToolKind: TToolKind;
    FActiveTool: ICanvasTool;
    FAlphaMask: TBitmap;
    FAlphaDirtyRect: TRect;
    FProtMask: TBitmap;           // maska ochronna (255 = zakryte/chronione, 0 = wolne)
    FProtDirtyRect: TRect;        // unia rectów pędzla maski ochronnej (koord. obrazu)
    FProtCoverCount: Int64;       // liczba pikseli FProtMask = 255 (szybki NeedEffectBackup)
    FShowProtMask: Boolean;       // overlay maski widoczny (menu Narzędzia)
    FBrushCursorOn: Boolean;
    FBrushCursorX, FBrushCursorY: Integer;
    FBrushCursorRect: TRect;
    FBacking: TBitmap;         // czysty kadr PaintBoxa: obraz+szachownica+overlay, BEZ pierścienia
    FPanelErase: Boolean;
    FAppEvents: TApplicationEvents;
    FBatchAbort: Boolean;
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure FormActiveChanged(Sender: TObject);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure LoadImage(const APath: string);
    procedure SaveImage(const APath: string);
    procedure CloseImage;
    procedure HandleRecentFileClick(Sender: TObject);
    procedure InterfacePreview(AColor: TColor; AFontSize: Integer);
    procedure UpdateZoomFit;
    procedure UpdateZoom(Value: Double);
    procedure UpdateLayout;
    procedure UpdateStatusBar(const OpName: string = ''; ExecutionTimeSec: Double = 0);
    procedure StatusBarHint(Sender: TObject);
    procedure UpdateCaption;
    procedure UpdateMenuState;
    procedure FinishEffect(const OpName: string; Seconds: Double);
    procedure RunMacro(const M: TMacro);
    procedure RunMacroStep(const Step: TMacroStep);
    function ApplyMacroStep(const Step: TMacroStep; Bitmap: TBitmap): string;
    procedure BatchProcess(const Opts: TBatchOptions);
    procedure BatchAbortClick(Sender: TObject);
    procedure DoEqualize(const Mode: string);
    procedure DoFalseIR(Bitmap: TBitmap);
    procedure DoNightVision(Bitmap: TBitmap);
    procedure DoThermal(Bitmap: TBitmap);
    procedure DoOrton(Bitmap: TBitmap);
    procedure DoXray(Bitmap: TBitmap);
    procedure DoFlipH(Bitmap: TBitmap);
    procedure WandDebounceTimerProc(Sender: TObject);
    procedure DoFlipV(Bitmap: TBitmap);
    procedure DoRotateLeft(Bitmap: TBitmap);
    procedure DoRotateRight(Bitmap: TBitmap);
    procedure DoRotate180(Bitmap: TBitmap);
    procedure SelectionRepaint(Sender: TObject);
    function SelectionScreenRect: TRect;
    procedure SetSelectionShape(AShape: THitShape);
    procedure RecomputeWandFromSeed;
    function NeedEffectBackup: Boolean;
    procedure RestoreOutsideSelection(Backup: TBitmap);
    procedure InvalidatePaintRect(R: TRect);
    procedure EnsureAlphaMask;
    procedure EnsureProtMask;
    procedure RecalcProtCoverCount;
    procedure ProtFlipH;
    procedure ProtFlipV;
    procedure AlphaFlipH;
    procedure AlphaFlipV;
    procedure ProtRotateLeft;
    procedure ProtRotateRight;
    procedure ProtRotate180;
    procedure ProtCrop(const R: TRect);
    procedure ProtResize(NewW, NewH: Integer);
    procedure ProtResizeCrop(TargetW, TargetH, Corner: Integer);
    procedure ProtRotateAngle(AngleDeg: Double);
    procedure NotifyBitmapResized;
    { Maska alfa (FAlphaMask) - te same przeksztalcenia co FProtMask wyzej.
      Obie maski maja wspolne wartowniki rozmiaru przy renderze
      (DrawCheckerRect / DrawProtMaskOverlay) i przy niezgodnosci cicho koncza
      rysowanie. Brak odpowiednika dla FProtMask = cicha utrata nakladki,
      a nie widoczny blad. }
    procedure AlphaRotateAngle(AngleDeg: Double);
    procedure AlphaRotateLeft;
    procedure AlphaRotateRight;
    procedure AlphaRotate180;
    procedure AlphaCrop(const R: TRect);
    procedure AlphaResize(NewW, NewH: Integer);
    procedure AlphaResizeCrop(TargetW, TargetH, Corner: Integer);
    procedure DrawTransparencyChecker(Canvas: TCanvas);
    procedure DrawProtMaskOverlay(Canvas: TCanvas);
    procedure DrawCheckerRect(Canvas: TCanvas; ScreenR: TRect);
    procedure RedrawRingBackdrop(ARect: TRect);
    procedure DrawRing;
    procedure UpdateBrushCursor(AX, AY: Integer);
    procedure ClearBrushCursor;
    procedure DrawBrushCursor;
    function RetouchEffectiveRadius: Integer;
    procedure MacroMgrPlayClick(Sender: TObject);
    procedure MacroMgrRenameClick(Sender: TObject);
    procedure MacroMgrDeleteClick(Sender: TObject);
    procedure MacroMgrSelectClick(Sender: TObject);
    procedure MacroMgrDeleteStepClick(Sender: TObject);
    procedure UpdateMacroMenu;
    procedure MenuItemMeasure(Sender: TObject; ACanvas: TCanvas;
      var Width, Height: Integer);
    procedure AssignMenuMeasure(AItem: TMenuItem);
    procedure InitMenuMeasure;
  public
    FSelection: TSelection;
    FSelectionView: TSelectionView;
    property Bitmap: TBitmap read FBitmap;
    function ActivateTool(ATool: TToolKind): ICanvasTool;
    function GetActiveToolKind: TToolKind;
    function GetSelectionShape: THitShape;
    function GetSelectionView: TSelectionView;
    procedure SetSelectionView(AView: TSelectionView);
    procedure DebouncedWandFromSeed(ADelayMs: Integer);
    function GetRetouchEraseMode: Boolean;
    procedure SetRetouchEraseMode(AErase: Boolean);
    function GetRetouchBrushSize: Integer;
    procedure SetRetouchBrushSize(AValue: Integer);
    function GetRetouchStrength: Integer;
    procedure SetRetouchStrength(AValue: Integer);
    function GetRetouchTolerance: Integer;
    procedure SetRetouchTolerance(AValue: Integer);
    function GetRetouchBrushMode: TBrushMode;
    procedure SetRetouchBrushMode(AMode: TBrushMode);
    function GetReplaceColor: TColor;
    procedure SetReplaceColor(AColor: TColor);
    function GetRetouchProtectMode: Boolean;
    procedure SetRetouchProtectMode(ACover: Boolean);
    function GetForeColor: TColor;
    procedure SetForeColor(AColor: TColor);
    procedure DoSetSelectionShape(AShape: THitShape);
    function GetReplaceRetainShading: Boolean;
    procedure SetReplaceRetainShading(AValue: Boolean);
  protected
    function UseCustomTitleBar: Boolean; override;
  end;

var
  frmMain: TfrmMain;

implementation

type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

{$R *.dfm}

procedure ApplyThemeLabelColors(AContainer: TComponent); forward;

type
  TRetouchMode = (rmErase, rmRestore);

  { TSelectionTool — logika zaznaczenia przeniesiona BEZ zmian z dawnych
    handlerów PaintBoxMouseDown/Move/Up (fMain). Domyślne narzędzie. }

  TSelectionTool = class(TInterfacedObject, ICanvasTool)
  private
    FOwner: TfrmMain;
  public
    constructor Create(AOwner: TfrmMain);
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    function GetOptionsPanel: TWinControl;
  end;

  { TEraserTool — narzędzie Gumka: Wymaż / Przywróć. Operuje wyłącznie na
    masce alfa FAlphaMask (0 = przezroczyste, 255 = kryjące); piksele RGB
    nie są modyfikowane, a szachownicę rysuje renderer pod mask=0. Jeden
    stroke = jedno UndoPushMasked na MouseDown, commit na MouseUp.
    Tryb (erase/restore) i rozmiar pędzla pochodzą z frmMain (FPanelErase /
    FRetouchBrushSize), nie mają już własnych kontrolek. }

  TEraserTool = class(TInterfacedObject, ICanvasTool)
  private
    FOwner: TfrmMain;
    FMode: TRetouchMode;
    FBrushSize: Integer;
    FStrokeActive: Boolean;
    FPrevX, FPrevY: Integer;
    FStrokeMaskWork: TBitmap;      // robocza kopia maski; wymazanie widoczne po MouseUp
    FStrokeDirtyRect: TRect;       // unia rectów pędzla tego stroke'u (koord. obrazu)
    procedure Stamp(Cx, Cy: Integer);
    procedure DrawSegment(X1, Y1, X2, Y2: Integer);
    procedure CommitStroke;
  public
    constructor Create(AOwner: TfrmMain);
    destructor Destroy; override;
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    function GetOptionsPanel: TWinControl;
  end;

  { TProtectTool — maska ochronna: Zakryj / Odkryj. Działa na FProtMask
    (pf8bit; 255 = zakryte/chronione, 0 = wolne). Jeden stroke = jedno
    UndoPushMasked z protem (trzeci kompan). Tryb (cover/uncover) i rozmiar
    pędzla z frmMain (FProtectCover / FRetouchBrushSize). Widoczne dopiero
    po MouseUp (wzorzec pozostałych narzędzi). }

  TProtectTool = class(TInterfacedObject, ICanvasTool)
  private
    FOwner: TfrmMain;
    FBrushSize: Integer;
    FStrokeActive: Boolean;
    FPrevX, FPrevY: Integer;
    FStrokeMaskWork: TBitmap;      // robocza kopia maski; wynik widoczny po MouseUp
    FStrokeDirtyRect: TRect;       // unia rectów pędzla tego stroke'u (koord. obrazu)
    procedure Stamp(Cx, Cy: Integer);
    procedure DrawSegment(X1, Y1, X2, Y2: Integer);
    procedure CommitStroke;
  public
    constructor Create(AOwner: TfrmMain);
    destructor Destroy; override;
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    function GetOptionsPanel: TWinControl;
  end;

  { TBrushTool — klasa bazowa narzędzi malujących na pikselach RGB.
    Wzorzec jak TEraserTool, ale zamiast maski modyfikuje roboczą kopię
    bitmapy (FStrokeBmpWork) i dopiero na MouseUp podmienia FOwner.FBitmap
    (jeden UndoPush na MouseDown). Potomek nadpisuje ApplyPixel — modyfikuje
    pojedynczy piksel wewnątrz definiującego dysku pędzla. FRetouchStrength
    (0..100) dostępny przez potomka. Narzędzia fazy dalszej: klon, dodge/burn,
    wyostrzanie/rozmywanie. }

  TBrushTool = class(TInterfacedObject, ICanvasTool)
  private
    FStrokeActive: Boolean;
    FPrevX, FPrevY: Integer;
    FStrokeBmpWork: TBitmap;       // robocza kopia bitmapy; wynik widoczny po MouseUp
    FStrokeDirtyRect: TRect;       // unia rectów pędzla tego stroke'u (koord. obrazu)
    procedure StampDisk(Cx, Cy: Integer);
    procedure DrawSegment(X1, Y1, X2, Y2: Integer);
    procedure CommitStroke;
  protected
    FOwner: TfrmMain;
    FBrushSize: Integer;
    FStrokeSrc: TBitmap;   // pf24 snapshot oryginału z początku stroke'u -
    //  deterministyczne próbkowanie pędzli przekształcających (klon/dodge/burn/ostrz/rozmycie)
    procedure ApplyPixel(Work: TBitmap; X, Y: Integer); virtual; abstract;
  public
    constructor Create(AOwner: TfrmMain);
    destructor Destroy; override;
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer); virtual;   // potomek zwalnia maske po strok'u
    function GetOptionsPanel: TWinControl;
  end;

  { TEyedropperTool — zakraplacz: kliknięta próbka koloru ustawia kolor
    rysowania (FForeColor), swatch w panelu odświeżany przez SetForeColor. }
  TEyedropperTool = class(TInterfacedObject, ICanvasTool)
  private
    FOwner: TfrmMain;
  public
    constructor Create(AOwner: TfrmMain);
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    function GetOptionsPanel: TWinControl;
  end;

  { TFloodFillTool — wiaderko: zalewanie spójnego obszaru kolorem FForeColor.
    Tolerancja per-kanał liczona z FRetouchTolerance (0..100 -> 0..255),
    algorytm 4-sąsiedztwa ze stosem wg wzorca RemoveBackgroundFlood
    (frmUsunTloDlg). Jeden klik = jedno undo; bez zaznaczenia (jak gumka). }
  TFloodFillTool = class(TInterfacedObject, ICanvasTool)
  private
    FOwner: TfrmMain;
    procedure FloodFill(Bmp: TBitmap; SX, SY, SR, SG, SB, Tol: Integer;
      TargetR, TargetG, TargetB: Byte; var R: TRect);
  public
    constructor Create(AOwner: TfrmMain);
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    function GetOptionsPanel: TWinControl;
  end;

  { TRetouchBrushTool — pędzle RGB (faza 2): malowanie kolorem, klon, dodge,
    burn, wyostrzanie, rozmycie. Tryb z frmMain (FBrushMode) - jak gumka czyta
    FPanelErase. Alt+lewy klik w trybie klonu = ustalenie punktu ziarna;
    stroke kopiuje oryginał (FStrokeSrc) z przesunięciem względem początku.
    Próbkowanie deterministyczne z snapshotu, więc nakładające się stempl nie
    podwajają efektu; malowanie kumuluje krycie na roboczej kopii. }
  TRetouchBrushTool = class(TBrushTool)
  private
    FCloneSrcX, FCloneSrcY: Integer;   // punkt ziarna (Alt+klik)
    FCloneReady: Boolean;              // ziarno ustawione w tej sesji
    FCloneOffX, FCloneOffY: Integer;   // offset ziarna względem początku stroke
    FStrokeReplace: TBitmap;          // pf8bit, anty-nakładanie w jednym pociągnięciu
    function ClampByte(V: Integer): Byte;
  protected
    procedure ApplyPixel(Work: TBitmap; X, Y: Integer); override;
  public
    constructor Create(AOwner: TfrmMain);
    destructor Destroy; override;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Shift: TShiftState; X, Y: Integer); override;
  end;

{ TSelectionTool }

constructor TSelectionTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TSelectionTool.Activate;
begin
end;

procedure TSelectionTool.Deactivate;
begin
  // Porządek przy zmianie narzędzia w trakcie przeciągania: niedokończona
  // selekcja nie może zostać "sierotą" (stale FSelecting=True).
  if FOwner.FSelMode = 'lmove' then
  begin
    FOwner.FSelection.CancelRegionMove;
    FOwner.FSelMode := 'new';
    FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
  end;
  FOwner.FSelecting := False;
end;

function TSelectionTool.GetOptionsPanel: TWinControl;
begin
  Result := nil;
end;

procedure TSelectionTool.MouseDown(Shift: TShiftState; X, Y: Integer);
var
  IX, IY: Double;
  Handle: THitHandle;
  Dw, Dh: Integer;
begin
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  Dw := Round(FOwner.FBitmap.Width * FOwner.FZoomFactor);
  Dh := Round(FOwner.FBitmap.Height * FOwner.FZoomFactor);
  if (Dw < 1) or (Dh < 1) then Exit;

  IX := X / FOwner.FZoomFactor;
  IY := Y / FOwner.FZoomFactor;

  // Różdżka: klik = nowe zaznaczenie wg tolerancji (przenikanie z wiaderka),
  // bez przeciągania i bez przesuwania. Tolerancja: 0..100 -> 0..255.
  if FOwner.FSelection.Shape = hsWand then
  begin
    if FOwner.FSelecting then Exit;
    if FOwner.FSelection.Active then
      FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
    FOwner.FSelection.SetRegionFromSeed(FOwner.FBitmap, Round(IX), Round(IY),
      FOwner.FRetouchTolerance * 51 div 20);
    if FOwner.FSelection.Active then
    begin
      FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
      FOwner.UpdateStatusBar;
    end;
    Exit;
  end;

  // Lasso: LPM wewnątrz istniejącego regionu = przesuwanie, poza = nowy obrys.
  if FOwner.FSelection.Shape = hsLasso then
  begin
    if FOwner.FSelecting then Exit;
    if FOwner.FSelection.Active and FOwner.FSelection.Contains(IX, IY) then
    begin
      FOwner.FSelMode := 'lmove';
      FOwner.FSelMoveOx := IX;
      FOwner.FSelMoveOy := IY;
      FOwner.FSelection.BeginRegionMove;
      FOwner.FSelecting := True;
      Exit;
    end;
    if FOwner.FSelection.Active then
      FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
    FOwner.FSelection.Clear;
    SetLength(FOwner.FLassoPts, 1);
    FOwner.FLassoPts[0] := System.Types.Point(Round(IX), Round(IY));
    FOwner.FLassoDrawing := True;
    FOwner.FSelecting := True;
    Exit;
  end;

  if not FOwner.FSelecting then
  begin
    Handle := FOwner.FSelection.HitTest(IX, IY, FOwner.FZoomFactor);
    if Handle in [hhTL, hhTM, hhTR, hhML, hhMR, hhBL, hhBM, hhBR] then
    begin
      FOwner.FSelMode := 'resize';
      FOwner.FSelHandle := Handle;
      FOwner.FSelecting := True;
    end
    else if FOwner.FSelection.Contains(IX, IY) then
    begin
      FOwner.FSelMode := 'move';
      // Punkt zaczepienia = znormalizowany lewy-górny róg (Hollywood: nix1/niy1,
      // events.hws:563-567). Delta bazuje na surowych, nieklamowanych współrzędnych
      // kursora — punkt chwytu może być ujemny lub poza wymiarami bitmapy.
      FOwner.FSelMoveOx := Min(FOwner.FSelection.X1, FOwner.FSelection.X2) - IX;
      FOwner.FSelMoveOy := Min(FOwner.FSelection.Y1, FOwner.FSelection.Y2) - IY;
      FOwner.FSelMoveW := FOwner.FSelection.W;
      FOwner.FSelMoveH := FOwner.FSelection.H;
      FOwner.FSelecting := True;
    end
    else
    begin
      // Nowe zaznaczenie może zaczynać się poza obrazem (ujemne lub
      // przekraczające wymiary bitmapy) — zgodnie z Hollywood, bez blokady.
      // Najpierw unieważnij obszar starego zaznaczenia, potem wyczyść.
      FOwner.FSelMode := 'new';
      if FOwner.FSelection.Active then
        FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
      FOwner.FSelection.Clear;
      FOwner.FSelection.SetRect(IX, IY, IX, IY);
      FOwner.FSelecting := True;
    end;
  end;
end;

procedure TSelectionTool.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  IX, IY: Double;
  Handle: THitHandle;
  OldR, NewR: TRect;
  N, OldX, OldY: Integer;
  P: TPoint;
begin
  IX := X / FOwner.FZoomFactor;
  IY := Y / FOwner.FZoomFactor;

  // Lasso — przesuwanie zaznaczenia (podgląd: obrys w nowym położeniu).
  if FOwner.FSelecting and (FOwner.FSelMode = 'lmove') then
  begin
    OldR := FOwner.SelectionScreenRect;
    FOwner.FSelection.PreviewRegionMove(
      Round(IX - FOwner.FSelMoveOx), Round(IY - FOwner.FSelMoveOy));
    NewR := FOwner.SelectionScreenRect;
    FOwner.InvalidatePaintRect(OldR);
    FOwner.InvalidatePaintRect(NewR);
    Exit;
  end;

  // Lasso: dopisujemy punkt ścieżki i unieważniamy tylko odcinek, który doszedł.
  if FOwner.FSelecting and (FOwner.FSelection.Shape = hsLasso) then
  begin
    N := Length(FOwner.FLassoPts);
    P := System.Types.Point(Round(IX), Round(IY));
    if (N = 0) or (FOwner.FLassoPts[N - 1].X <> P.X) or (FOwner.FLassoPts[N - 1].Y <> P.Y) then
    begin
      if N > 0 then
      begin
        OldX := FOwner.FLassoPts[N - 1].X;
        OldY := FOwner.FLassoPts[N - 1].Y;
        FOwner.InvalidatePaintRect(Rect(
          Round(Min(OldX, P.X) * FOwner.FZoomFactor) - 4,
          Round(Min(OldY, P.Y) * FOwner.FZoomFactor) - 4,
          Round(Max(OldX, P.X) * FOwner.FZoomFactor) + 5,
          Round(Max(OldY, P.Y) * FOwner.FZoomFactor) + 5));
      end;
      SetLength(FOwner.FLassoPts, N + 1);
      FOwner.FLassoPts[N] := P;
    end;
    Exit;
  end;

  if FOwner.FSelecting then
  begin
    OldR := FOwner.SelectionScreenRect;
    if FOwner.FSelMode = 'move' then
    begin
      // Delta = surowe, nieklamowane współrzędne kursora względem punktu chwytu
      // (Hollywood: sel_x1 = nx + ox; sel_x2 = sel_x1 + w). Cały prostokąt może
      // wędrować poza wymiary bitmapy — klampowanie tylko w ClampedRect (efekt/crop).
      FOwner.FSelection.SetRect(IX + FOwner.FSelMoveOx, IY + FOwner.FSelMoveOy,
        IX + FOwner.FSelMoveOx + FOwner.FSelMoveW,
        IY + FOwner.FSelMoveOy + FOwner.FSelMoveH);
    end
    else if FOwner.FSelMode = 'resize' then
    begin
      FOwner.FSelection.ResizeHandle(FOwner.FSelHandle, IX, IY, Shift);
    end
    else
    begin
      FOwner.FSelection.SetRect(FOwner.FSelection.X1, FOwner.FSelection.Y1, IX, IY);
    end;
    NewR := FOwner.SelectionScreenRect;
    // Unieważnij OBA obszary osobno: UnionRect zwraca FALSE przy rozłącznych
    // prostokątach (szybki ruch myszy) i zostawia niezdefiniowany wynik → widma.
    FOwner.InvalidatePaintRect(OldR);
    FOwner.InvalidatePaintRect(NewR);
  end
  else if FOwner.FSelection.Active then
  begin
    Handle := FOwner.FSelection.HitTest(IX, IY, FOwner.FZoomFactor);
    Screen.Cursor := FOwner.FSelection.CursorForHandle(Handle);
  end
  else
    Screen.Cursor := crDefault;
end;

procedure TSelectionTool.MouseUp(Shift: TShiftState; X, Y: Integer);
var
  W, H: Integer;
  R: TRect;
  I, MinX, MinY, MaxX, MaxY: Integer;
begin
  if not FOwner.FSelecting then Exit;

  // Lasso — zakończenie przesuwania: rasteryzacja regionu w nowym położeniu.
  if (FOwner.FSelection.Shape = hsLasso) and (FOwner.FSelMode = 'lmove') then
  begin
    R := FOwner.SelectionScreenRect;
    FOwner.FSelection.CommitRegionMove;
    FOwner.FSelecting := False;
    FOwner.FSelMode := 'new';
    FOwner.InvalidatePaintRect(R);
    FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
    FOwner.UpdateStatusBar;
    Exit;
  end;

  // Lasso: finalizacja — rasteryzacja zamkniętego wielokąta do regionu.
  if FOwner.FSelection.Shape = hsLasso then
  begin
    if Length(FOwner.FLassoPts) > 0 then
    begin
      MinX := FOwner.FLassoPts[0].X; MaxX := MinX;
      MinY := FOwner.FLassoPts[0].Y; MaxY := MinY;
      for I := 1 to High(FOwner.FLassoPts) do
      begin
        if FOwner.FLassoPts[I].X < MinX then MinX := FOwner.FLassoPts[I].X;
        if FOwner.FLassoPts[I].X > MaxX then MaxX := FOwner.FLassoPts[I].X;
        if FOwner.FLassoPts[I].Y < MinY then MinY := FOwner.FLassoPts[I].Y;
        if FOwner.FLassoPts[I].Y > MaxY then MaxY := FOwner.FLassoPts[I].Y;
      end;
      FOwner.InvalidatePaintRect(Rect(
        Round(MinX * FOwner.FZoomFactor) - 4, Round(MinY * FOwner.FZoomFactor) - 4,
        Round(MaxX * FOwner.FZoomFactor) + 5, Round(MaxY * FOwner.FZoomFactor) + 5));
    end;
    FOwner.FLassoDrawing := False;
    FOwner.FSelecting := False;
    FOwner.FSelMode := 'new';
    if Length(FOwner.FLassoPts) >= 3 then
      FOwner.FSelection.SetRegionFromPolygon(FOwner.FLassoPts,
        FOwner.FBitmap.Width, FOwner.FBitmap.Height);
    SetLength(FOwner.FLassoPts, 0);
    if FOwner.FSelection.Active and FOwner.FSelection.IsValid then
    begin
      FOwner.InvalidatePaintRect(FOwner.SelectionScreenRect);
      FOwner.UpdateStatusBar;
    end;
    Exit;
  end;

  R := FOwner.SelectionScreenRect; // obszar do odświeżenia PRZED mutacją (Clear zeruje do -1)
  FOwner.FSelMode := 'new';
  FOwner.FSelecting := False;
  W := Round(FOwner.FSelection.W);
  H := Round(FOwner.FSelection.H);
  if (W > 2) and (H > 2) then
  begin
    FOwner.FSelection.Active := True;
    FOwner.FSelection.SetRect(FOwner.FSelection.X1, FOwner.FSelection.Y1,
      FOwner.FSelection.X2, FOwner.FSelection.Y2); // restart timer
    FOwner.UpdateStatusBar;
  end
  else
    FOwner.FSelection.Clear;
  FOwner.InvalidatePaintRect(R);
end;

{ TEraserTool }

constructor TEraserTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
  FMode := rmErase;
  FBrushSize := FOwner.FRetouchBrushSize;
  FStrokeActive := False;
  FStrokeMaskWork := nil;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
end;

destructor TEraserTool.Destroy;
begin
  FStrokeMaskWork.Free;
  inherited;
end;

procedure TEraserTool.Activate;
var
  P: TPoint;
begin
  // Ukryj kursor systemowy - zamiast niego renderer rysuje kółko pędzla
  // (wzorzec Hollywood: przezroczysty okrąg zamiast wskaźnika myszy).
  FOwner.FBrushCursorOn := False;
  FOwner.PaintBox.Cursor := crNone;
  // Kółko od razu w bieżącej pozycji kursora (jeśli jest nad obrazem), żeby
  // nie było okna bez wskaźnika do pierwszego MouseMove.
  if (FOwner.FBitmap.Width > 0) and (FOwner.FBitmap.Height > 0) then
  begin
    P := FOwner.PaintBox.ScreenToClient(Mouse.CursorPos);
    if (P.X >= 0) and (P.Y >= 0) and
       (P.X < FOwner.PaintBox.Width) and (P.Y < FOwner.PaintBox.Height) then
      FOwner.UpdateBrushCursor(P.X, P.Y);
  end;
end;

procedure TEraserTool.Deactivate;
begin
  if FStrokeActive then CommitStroke;
  FOwner.ClearBrushCursor;
  FOwner.PaintBox.Cursor := crDefault;
end;

function TEraserTool.GetOptionsPanel: TWinControl;
begin
  // Panel opcji mieszka w .dfm (frmToolsDlg) - narzędzie nie ma własnego tree.
  Result := nil;
end;

procedure TEraserTool.CommitStroke;
var
  RRect: TRect;
begin
  FStrokeActive := False;
  if FStrokeMaskWork <> nil then
  begin
    FOwner.FAlphaMask.Free;
    FOwner.FAlphaMask := FStrokeMaskWork;
    FStrokeMaskWork := nil;
  end;
  // Wzorzec Hollywood: wymazanie pojawia się po puszczeniu przycisku - cały
  // stroke unieważniany raz, zamiast repaintu w pętli MouseMove.
  RRect := FStrokeDirtyRect;
  if (RRect.Right > RRect.Left) and (RRect.Bottom > RRect.Top) then
    FOwner.InvalidatePaintRect(Rect(
      Round(RRect.Left * FOwner.FZoomFactor) - 2,
      Round(RRect.Top * FOwner.FZoomFactor) - 2,
      Round(RRect.Right * FOwner.FZoomFactor) + 2,
      Round(RRect.Bottom * FOwner.FZoomFactor) + 2));
  FOwner.FDirty := True;
  FOwner.UpdateCaption;
end;

procedure TEraserTool.Stamp(Cx, Cy: Integer);
var
  W, H, R2, Dx, Dy, X, Y: Integer;
  Mask: TBitmap;
  P: PByte;
  V: Byte;
begin
  Mask := FStrokeMaskWork;
  if Mask = nil then Mask := FOwner.FAlphaMask;
  if Mask = nil then Exit;
  W := Mask.Width;
  H := Mask.Height;
  R2 := Max(1, FBrushSize div 2);
  if FMode = rmErase then
    V := 0
  else
    V := 255;
  // Mazanie rozszerza obszar oznaczony do rysowania szachownicy
  // (FAlphaDirtyRect); przywracanie nie zwęża rectu - zostaje konserwatywnie
  // (zero kosztu renderowania, gdy w rectu nie ma już mask=0).
  if FMode = rmErase then
  begin
    with FOwner.FAlphaDirtyRect do
    begin
      if (Right <= Left) or (Bottom <= Top) then
      begin
        Left := Cx - R2;
        Top := Cy - R2;
        Right := Cx + R2 + 1;
        Bottom := Cy + R2 + 1;
      end
      else
      begin
        if Cx - R2 < Left then Left := Cx - R2;
        if Cy - R2 < Top then Top := Cy - R2;
        if Cx + R2 + 1 > Right then Right := Cx + R2 + 1;
        if Cy + R2 + 1 > Bottom then Bottom := Cy + R2 + 1;
      end;
    end;
  end;
  // Unia rectów pędzla danego stroke'u - obszar invalidowany przy commicie.
  if FStrokeDirtyRect.Right <= FStrokeDirtyRect.Left then
    FStrokeDirtyRect := Rect(Cx - R2, Cy - R2, Cx + R2 + 1, Cy + R2 + 1)
  else
    with FStrokeDirtyRect do
    begin
      if Cx - R2 < Left then Left := Cx - R2;
      if Cy - R2 < Top then Top := Cy - R2;
      if Cx + R2 + 1 > Right then Right := Cx + R2 + 1;
      if Cy + R2 + 1 > Bottom then Bottom := Cy + R2 + 1;
    end;
  for Dy := -R2 to R2 do
  begin
    Y := Cy + Dy;
    if (Y < 0) or (Y >= H) then Continue;
    P := Mask.ScanLine[Y];
    for Dx := -R2 to R2 do
    begin
      if (Dx * Dx + Dy * Dy) > R2 * R2 then Continue;
      X := Cx + Dx;
      if (X < 0) or (X >= W) then Continue;
      P[X] := V;
    end;
  end;
end;

procedure TEraserTool.DrawSegment(X1, Y1, X2, Y2: Integer);
var
  R, N, I: Integer;
  Dist: Double;
begin
  R := Max(1, FBrushSize div 2);
  Dist := Hypot(X2 - X1, Y2 - Y1);
  N := Round(Dist / R);
  if N = 0 then
    Stamp(X1, Y1)
  else
    for I := 0 to N do
      Stamp(Round(X1 + (X2 - X1) * I / N), Round(Y1 + (Y2 - Y1) * I / N));
end;

procedure TEraserTool.MouseDown(Shift: TShiftState; X, Y: Integer);
begin
  if FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  if FOwner.FAlphaMask = nil then Exit;
  FStrokeActive := True;
  FBrushSize := FOwner.FRetouchBrushSize;
  if FOwner.FPanelErase then
    FMode := rmErase
  else
    FMode := rmRestore;
  // Jeden stroke = jedno undo (bitmapa + maska alfa + maska ochronna, UndoPushMasked).
  UndoPushMasked(FOwner.FBitmap, FOwner.FAlphaMask, FOwner.FProtMask);
  // Robocza kopia maski: stemplujemy do niej, a renderer pokazuje ją dopiero
  // po MouseUp. Dzięki temu podczas ruchu nie ma odświeżania wymazywania -
  // tylko kółko pędzla podąża za kursorem (wzorzec Hollywood).
  FStrokeMaskWork := TBitmap.Create;
  FStrokeMaskWork.Assign(FOwner.FAlphaMask);
  FStrokeMaskWork.PixelFormat := pf8bit;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
  FPrevX := Round(X / FOwner.FZoomFactor);
  FPrevY := Round(Y / FOwner.FZoomFactor);
  Stamp(FPrevX, FPrevY);
  FOwner.UpdateBrushCursor(X, Y);
end;

procedure TEraserTool.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Cx, Cy: Integer;
begin
  // Kółko pędzla podąża za kursorem zawsze, gdy narzędzie aktywne - nawet bez
  // pociągnięcia (repaint tylko rectu pierścienia, nie ścieżki wymazywania).
  FOwner.UpdateBrushCursor(X, Y);
  if not FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  Cx := Round(X / FOwner.FZoomFactor);
  Cy := Round(Y / FOwner.FZoomFactor);
  DrawSegment(FPrevX, FPrevY, Cx, Cy);
  FPrevX := Cx;
  FPrevY := Cy;
end;

procedure TEraserTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
  if not FStrokeActive then Exit;
  CommitStroke;
end;

{ TProtectTool }

constructor TProtectTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
  FBrushSize := FOwner.FRetouchBrushSize;
  FStrokeActive := False;
  FStrokeMaskWork := nil;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
end;

destructor TProtectTool.Destroy;
begin
  FStrokeMaskWork.Free;
  inherited;
end;

procedure TProtectTool.Activate;
var
  P: TPoint;
begin
  FOwner.FBrushCursorOn := False;
  FOwner.PaintBox.Cursor := crNone;
  if (FOwner.FBitmap.Width > 0) and (FOwner.FBitmap.Height > 0) then
  begin
    P := FOwner.PaintBox.ScreenToClient(Mouse.CursorPos);
    if (P.X >= 0) and (P.Y >= 0) and
       (P.X < FOwner.PaintBox.Width) and (P.Y < FOwner.PaintBox.Height) then
      FOwner.UpdateBrushCursor(P.X, P.Y);
  end;
end;

procedure TProtectTool.Deactivate;
begin
  if FStrokeActive then CommitStroke;
  FOwner.ClearBrushCursor;
  FOwner.PaintBox.Cursor := crDefault;
end;

function TProtectTool.GetOptionsPanel: TWinControl;
begin
  Result := nil;
end;

procedure TProtectTool.CommitStroke;
var
  RRect: TRect;
begin
  FStrokeActive := False;
  if FStrokeMaskWork <> nil then
  begin
    FOwner.FProtMask.Free;
    FOwner.FProtMask := FStrokeMaskWork;
    FStrokeMaskWork := nil;
    FOwner.RecalcProtCoverCount;
  end;
  RRect := FStrokeDirtyRect;
  if (RRect.Right > RRect.Left) and (RRect.Bottom > RRect.Top) then
    FOwner.InvalidatePaintRect(Rect(
      Round(RRect.Left * FOwner.FZoomFactor) - 2,
      Round(RRect.Top * FOwner.FZoomFactor) - 2,
      Round(RRect.Right * FOwner.FZoomFactor) + 2,
      Round(RRect.Bottom * FOwner.FZoomFactor) + 2));
  FOwner.FDirty := True;
  FOwner.UpdateCaption;
end;

procedure TProtectTool.Stamp(Cx, Cy: Integer);
var
  W, H, R2, Dx, Dy, X, Y: Integer;
  Mask: TBitmap;
  P: PByte;
  V: Byte;
begin
  Mask := FStrokeMaskWork;
  if Mask = nil then Mask := FOwner.FProtMask;
  if Mask = nil then Exit;
  W := Mask.Width;
  H := Mask.Height;
  R2 := Max(1, FBrushSize div 2);
  if FOwner.FProtectCover then
    V := 255
  else
    V := 0;
  if FStrokeDirtyRect.Right <= FStrokeDirtyRect.Left then
    FStrokeDirtyRect := Rect(Cx - R2, Cy - R2, Cx + R2 + 1, Cy + R2 + 1)
  else
    with FStrokeDirtyRect do
    begin
      if Cx - R2 < Left then Left := Cx - R2;
      if Cy - R2 < Top then Top := Cy - R2;
      if Cx + R2 + 1 > Right then Right := Cx + R2 + 1;
      if Cy + R2 + 1 > Bottom then Bottom := Cy + R2 + 1;
    end;
  for Dy := -R2 to R2 do
  begin
    Y := Cy + Dy;
    if (Y < 0) or (Y >= H) then Continue;
    P := Mask.ScanLine[Y];
    for Dx := -R2 to R2 do
    begin
      if (Dx * Dx + Dy * Dy) > R2 * R2 then Continue;
      X := Cx + Dx;
      if (X < 0) or (X >= W) then Continue;
      P[X] := V;
    end;
  end;
end;

procedure TProtectTool.DrawSegment(X1, Y1, X2, Y2: Integer);
var
  R, N, I: Integer;
  Dist: Double;
begin
  R := Max(1, FBrushSize div 2);
  Dist := Hypot(X2 - X1, Y2 - Y1);
  N := Round(Dist / R);
  if N = 0 then
    Stamp(X1, Y1)
  else
    for I := 0 to N do
      Stamp(Round(X1 + (X2 - X1) * I / N), Round(Y1 + (Y2 - Y1) * I / N));
end;

procedure TProtectTool.MouseDown(Shift: TShiftState; X, Y: Integer);
begin
  if FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  if (FOwner.FProtMask = nil) or
     (FOwner.FProtMask.Width <> FOwner.FBitmap.Width) or
     (FOwner.FProtMask.Height <> FOwner.FBitmap.Height) then
    FOwner.EnsureProtMask;
  if FOwner.FProtMask = nil then Exit;
  FStrokeActive := True;
  FBrushSize := FOwner.FRetouchBrushSize;
  UndoPushMasked(FOwner.FBitmap, FOwner.FAlphaMask, FOwner.FProtMask);
  FStrokeMaskWork := TBitmap.Create;
  FStrokeMaskWork.Assign(FOwner.FProtMask);
  FStrokeMaskWork.PixelFormat := pf8bit;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
  FPrevX := Round(X / FOwner.FZoomFactor);
  FPrevY := Round(Y / FOwner.FZoomFactor);
  Stamp(FPrevX, FPrevY);
  FOwner.UpdateBrushCursor(X, Y);
end;

procedure TProtectTool.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Cx, Cy: Integer;
begin
  FOwner.UpdateBrushCursor(X, Y);
  if not FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  Cx := Round(X / FOwner.FZoomFactor);
  Cy := Round(Y / FOwner.FZoomFactor);
  DrawSegment(FPrevX, FPrevY, Cx, Cy);
  FPrevX := Cx;
  FPrevY := Cy;
end;

procedure TProtectTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
  if not FStrokeActive then Exit;
  CommitStroke;
end;

// Maksymalny skok jasności (poziomy 0..255) jednego stempla pędzla jasności
// (dodge/burn). Ogranicza efekt nawet przy Siła=100, żeby jeden ruch nie
// wybielał/nie zacieniał całego obszaru; budowa efektu przez wielokrotne
// przeciągnięcia + akumulacja.
const
  cRetouchMaxStep = 30;

{ TBrushTool }

constructor TBrushTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
  FBrushSize := FOwner.FRetouchBrushSize;
  FStrokeActive := False;
  FStrokeBmpWork := nil;
  FStrokeSrc := nil;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
end;

destructor TBrushTool.Destroy;
begin
  FStrokeBmpWork.Free;
  FStrokeSrc.Free;
  inherited;
end;

procedure TBrushTool.Activate;
begin
  // Kursor kółka jak w gumce: renderer rysuje okrąg pędzla zamiast kursora.
  FOwner.FBrushCursorOn := False;
  FOwner.PaintBox.Cursor := crNone;
end;

procedure TBrushTool.Deactivate;
begin
  // Niewykończony stroke (zmiana narzędzia w trakcie przeciągania) commit.
  if FStrokeActive then CommitStroke;
  FOwner.ClearBrushCursor;
  FOwner.PaintBox.Cursor := crDefault;
end;

function TBrushTool.GetOptionsPanel: TWinControl;
begin
  // Opcje narzędzi mieszają w panelu frmToolsDlg - narzędzie nie ma własnego tree.
  Result := nil;
end;

procedure TBrushTool.StampDisk(Cx, Cy: Integer);
var
  W, H, R2, Dx, Dy, X, Y: Integer;
  Bmp: TBitmap;
begin
  Bmp := FStrokeBmpWork;
  if Bmp = nil then Exit;
  W := Bmp.Width;
  H := Bmp.Height;
  R2 := FOwner.RetouchEffectiveRadius;
  // Unia rectów pędzla danego stroke'u - obszar invalidowany przy commicie.
  if FStrokeDirtyRect.Right <= FStrokeDirtyRect.Left then
    FStrokeDirtyRect := Rect(Cx - R2, Cy - R2, Cx + R2 + 1, Cy + R2 + 1)
  else
    with FStrokeDirtyRect do
    begin
      if Cx - R2 < Left then Left := Cx - R2;
      if Cy - R2 < Top then Top := Cy - R2;
      if Cx + R2 + 1 > Right then Right := Cx + R2 + 1;
      if Cy + R2 + 1 > Bottom then Bottom := Cy + R2 + 1;
    end;
  for Dy := -R2 to R2 do
  begin
    Y := Cy + Dy;
    if (Y < 0) or (Y >= H) then Continue;
    for Dx := -R2 to R2 do
    begin
      if (Dx * Dx + Dy * Dy) > R2 * R2 then Continue;
      X := Cx + Dx;
      if (X < 0) or (X >= W) then Continue;
      ApplyPixel(Bmp, X, Y);
    end;
  end;
end;

procedure TBrushTool.DrawSegment(X1, Y1, X2, Y2: Integer);
var
  R, N, I: Integer;
  Dist: Double;
begin
  // Krok = faktycznie malowany promień, inaczej przy małej sile stemple byłyby
  // rozstawione szerzej niż ich średnica i ślad rozpadłby się na kropki.
  R := FOwner.RetouchEffectiveRadius;
  Dist := Hypot(X2 - X1, Y2 - Y1);
  N := Round(Dist / R);
  if N = 0 then
    StampDisk(X1, Y1)
  else
    for I := 0 to N do
      StampDisk(Round(X1 + (X2 - X1) * I / N), Round(Y1 + (Y2 - Y1) * I / N));
end;

procedure TBrushTool.MouseDown(Shift: TShiftState; X, Y: Integer);
begin
  if FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  FStrokeActive := True;
  FBrushSize := FOwner.FRetouchBrushSize;
  // Jeden stroke = jedno undo (tylko bitmapa RGB; maska alfa bez zmian).
  UndoPush(FOwner.FBitmap);
  FStrokeBmpWork := TBitmap.Create;
  FStrokeBmpWork.Assign(FOwner.FBitmap);
  FStrokeBmpWork.PixelFormat := pf24bit;
  FStrokeSrc := TBitmap.Create;
  FStrokeSrc.Assign(FOwner.FBitmap);
  FStrokeSrc.PixelFormat := pf24bit;
  FStrokeDirtyRect := Rect(0, 0, 0, 0);
  FPrevX := Round(X / FOwner.FZoomFactor);
  FPrevY := Round(Y / FOwner.FZoomFactor);
  StampDisk(FPrevX, FPrevY);
  FOwner.UpdateBrushCursor(X, Y);
end;

procedure TBrushTool.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Cx, Cy: Integer;
begin
  FOwner.UpdateBrushCursor(X, Y);
  if not FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  Cx := Round(X / FOwner.FZoomFactor);
  Cy := Round(Y / FOwner.FZoomFactor);
  DrawSegment(FPrevX, FPrevY, Cx, Cy);
  FPrevX := Cx;
  FPrevY := Cy;
end;

procedure TBrushTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
  if not FStrokeActive then Exit;
  CommitStroke;
end;

procedure TBrushTool.CommitStroke;
var
  RRect: TRect;
begin
  FStrokeActive := False;
  if FStrokeBmpWork <> nil then
  begin
    FOwner.FBitmap.Free;
    FOwner.FBitmap := FStrokeBmpWork;
    FStrokeBmpWork := nil;
  end;
  FStrokeSrc.Free;
  FStrokeSrc := nil;
  // Stroke unieważniany raz po puszczeniu przycisku (wzorzec Hollywood).
  RRect := FStrokeDirtyRect;
  if (RRect.Right > RRect.Left) and (RRect.Bottom > RRect.Top) then
    FOwner.InvalidatePaintRect(Rect(
      Round(RRect.Left * FOwner.FZoomFactor) - 2,
      Round(RRect.Top * FOwner.FZoomFactor) - 2,
      Round(RRect.Right * FOwner.FZoomFactor) + 2,
      Round(RRect.Bottom * FOwner.FZoomFactor) + 2));
  // Nowa bitmapa = nowy uchwyt -> cache próbki zoomu nieaktualny.
  FOwner.InvalidatePreviewCache;
  FOwner.FDirty := True;
  FOwner.UpdateCaption;
end;

{ TEyedropperTool }

constructor TEyedropperTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TEyedropperTool.Activate;
begin
  // Celny klik: kursor krzyżowy zamiast strzałki.
  FOwner.PaintBox.Cursor := crCross;
end;

procedure TEyedropperTool.Deactivate;
begin
  FOwner.ClearBrushCursor;
  FOwner.PaintBox.Cursor := crDefault;
end;

function TEyedropperTool.GetOptionsPanel: TWinControl;
begin
  Result := nil;
end;

procedure TEyedropperTool.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TEyedropperTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TEyedropperTool.MouseDown(Shift: TShiftState; X, Y: Integer);
var
  IX, IY: Integer;
begin
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  IX := Round(X / FOwner.FZoomFactor);
  IY := Round(Y / FOwner.FZoomFactor);
  if IX < 0 then IX := 0;
  if IY < 0 then IY := 0;
  if IX >= FOwner.FBitmap.Width then IX := FOwner.FBitmap.Width - 1;
  if IY >= FOwner.FBitmap.Height then IY := FOwner.FBitmap.Height - 1;
  // Canvas.Pixels: niezależne od PixelFormat (24/32-bit, paleta) - przy
  // pojedynczym pikselu koszt znikomy.
  FOwner.SetForeColor(FOwner.FBitmap.Canvas.Pixels[IX, IY]);
end;

{ TFloodFillTool }

constructor TFloodFillTool.Create(AOwner: TfrmMain);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TFloodFillTool.Activate;
begin
  FOwner.PaintBox.Cursor := crCross;
end;

procedure TFloodFillTool.Deactivate;
begin
  FOwner.ClearBrushCursor;
  FOwner.PaintBox.Cursor := crDefault;
end;

function TFloodFillTool.GetOptionsPanel: TWinControl;
begin
  Result := nil;
end;

procedure TFloodFillTool.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TFloodFillTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TFloodFillTool.FloodFill(Bmp: TBitmap; SX, SY, SR, SG, SB, Tol: Integer;
  TargetR, TargetG, TargetB: Byte; var R: TRect);
var
  W, H, Y, X, NX, NY, SP, Cur: Integer;
  Rows: array of PRGBTripleArray;
  Visited: array of Byte;
  Stack: array of Integer;
  MinX, MinY, MaxX, MaxY: Integer;
begin
  R := Rect(0, 0, 0, 0);
  if Bmp = nil then Exit;
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;

  SetLength(Rows, H);
  for Y := 0 to H - 1 do
    Rows[Y] := Bmp.ScanLine[Y];

  // Visited: bajt na piksel; ziarno zawsze częścią regionu.
  SetLength(Visited, W * H);
  FillChar(Visited[0], W * H, 0);
  SetLength(Stack, W * H);

  SP := 0;
  Stack[SP] := SY * W + SX;
  Inc(SP);
  Visited[SY * W + SX] := 1;
  Rows[SY][SX].R := TargetR;
  Rows[SY][SX].G := TargetG;
  Rows[SY][SX].B := TargetB;
  MinX := SX;
  MinY := SY;
  MaxX := SX;
  MaxY := SY;

  while SP > 0 do
  begin
    Dec(SP);
    Cur := Stack[SP];
    X := Cur mod W;
    Y := Cur div W;

    // Piksel pasuje (leży w regionie), gdy wszystkie kanały mieszczą się
    // w tolerancji względem ziarna (SR/SG/SB).
    if X > 0 then
    begin
      NX := X - 1;
      NY := Y;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - SR) <= Tol) and
           (Abs(Rows[NY][NX].G - SG) <= Tol) and
           (Abs(Rows[NY][NX].B - SB) <= Tol) then
        begin
          Rows[NY][NX].R := TargetR;
          Rows[NY][NX].G := TargetG;
          Rows[NY][NX].B := TargetB;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if X + 1 < W then
    begin
      NX := X + 1;
      NY := Y;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - SR) <= Tol) and
           (Abs(Rows[NY][NX].G - SG) <= Tol) and
           (Abs(Rows[NY][NX].B - SB) <= Tol) then
        begin
          Rows[NY][NX].R := TargetR;
          Rows[NY][NX].G := TargetG;
          Rows[NY][NX].B := TargetB;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if Y > 0 then
    begin
      NX := X;
      NY := Y - 1;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - SR) <= Tol) and
           (Abs(Rows[NY][NX].G - SG) <= Tol) and
           (Abs(Rows[NY][NX].B - SB) <= Tol) then
        begin
          Rows[NY][NX].R := TargetR;
          Rows[NY][NX].G := TargetG;
          Rows[NY][NX].B := TargetB;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if Y + 1 < H then
    begin
      NX := X;
      NY := Y + 1;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - SR) <= Tol) and
           (Abs(Rows[NY][NX].G - SG) <= Tol) and
           (Abs(Rows[NY][NX].B - SB) <= Tol) then
        begin
          Rows[NY][NX].R := TargetR;
          Rows[NY][NX].G := TargetG;
          Rows[NY][NX].B := TargetB;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;
  end;

  R := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

procedure TFloodFillTool.MouseDown(Shift: TShiftState; X, Y: Integer);
var
  IX, IY: Integer;
  SeedCl, TargetCl: COLORREF;
  SR, SG, SB, TR, TG, TB: Byte;
  R: TRect;
  Tol: Integer;
begin
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  IX := Round(X / FOwner.FZoomFactor);
  IY := Round(Y / FOwner.FZoomFactor);
  if IX < 0 then IX := 0;
  if IY < 0 then IY := 0;
  if IX >= FOwner.FBitmap.Width then IX := FOwner.FBitmap.Width - 1;
  if IY >= FOwner.FBitmap.Height then IY := FOwner.FBitmap.Height - 1;

  // Próbka ziarna format-niezależna (Canvas.Pixels) - bez zmiany PixelFormat.
  SeedCl := ColorToRGB(FOwner.FBitmap.Canvas.Pixels[IX, IY]);
  SR := SeedCl and $FF;
  SG := (SeedCl shr 8) and $FF;
  SB := (SeedCl shr 16) and $FF;

  TargetCl := ColorToRGB(FOwner.FForeColor);
  TR := TargetCl and $FF;
  TG := (TargetCl shr 8) and $FF;
  TB := (TargetCl shr 16) and $FF;

  // Tolerancja panelu 0..100 -> maksymalna różnica per-kanał 0..255.
  Tol := FOwner.FRetouchTolerance * 51 div 20;

  // Cel == kolor ziarna: region (piksele w tolerancji ziarna) nie zmieni
  // zawartości - bez śmieciowego wpisu w historii undo.
  if (SR = TR) and (SG = TG) and (SB = TB) then Exit;

  UndoPush(FOwner.FBitmap);
  // Ulewa wymaga TRGBTriple (3 bajty/piksel) - konwersja (np. 32->24)
  // bezstratna dla obrazu bez alfy; tylko gdy realnie coś zmieniamy.
  if FOwner.FBitmap.PixelFormat <> pf24bit then
    FOwner.FBitmap.PixelFormat := pf24bit;
  FloodFill(FOwner.FBitmap, IX, IY, SR, SG, SB, Tol, TR, TG, TB, R);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
  FOwner.InvalidatePaintRect(Rect(
    Round(R.Left * FOwner.FZoomFactor) - 2,
    Round(R.Top * FOwner.FZoomFactor) - 2,
    Round(R.Right * FOwner.FZoomFactor) + 2,
    Round(R.Bottom * FOwner.FZoomFactor) + 2));
  FOwner.InvalidatePreviewCache;
  FOwner.FDirty := True;
  FOwner.UpdateCaption;
end;

{ TRetouchBrushTool }

function TRetouchBrushTool.ClampByte(V: Integer): Byte;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := V;
end;

procedure TRetouchBrushTool.MouseDown(Shift: TShiftState; X, Y: Integer);
var
  Cx, Cy: Integer;
  Ly: Integer;
  MP: PByte;
begin
  if FStrokeActive then Exit;
  if (FOwner.FBitmap.Width = 0) or (FOwner.FBitmap.Height = 0) then Exit;
  Cx := Round(X / FOwner.FZoomFactor);
  Cy := Round(Y / FOwner.FZoomFactor);
  // Alt+klik = pobranie punktu ziarna klonu (bez malowania).
  if ssAlt in Shift then
  begin
    FCloneSrcX := Cx;
    FCloneSrcY := Cy;
    FCloneReady := True;
    Exit;
  end;
  FCloneOffX := 0;
  FCloneOffY := 0;
  if FCloneReady then
  begin
    FCloneOffX := FCloneSrcX - Cx;
    FCloneOffY := FCloneSrcY - Cy;
  end;
  // Maska anty-nakładania tylko dla zamiany koloru: piksel ma być zdecydowany
  // raz w obrębie jednego pociągnięcia. Powstaje tu, bo bazowa MouseDown
  // od razu stempluje pierwszy dysk. Ginie w MouseUp - między pociągnięciami
  // nie ma żadnego stanu, więc powtórne przejście niczego nie blokuje.
  FStrokeReplace.Free;
  FStrokeReplace := nil;
  if (FOwner.FBrushMode = bmColorReplace) and
     (FOwner.FBitmap.Width > 0) and (FOwner.FBitmap.Height > 0) then
  begin
    FStrokeReplace := TBitmap.Create;
    FStrokeReplace.PixelFormat := pf8bit;
    FStrokeReplace.Width := FOwner.FBitmap.Width;
    FStrokeReplace.Height := FOwner.FBitmap.Height;
    for Ly := 0 to FStrokeReplace.Height - 1 do
    begin
      MP := FStrokeReplace.ScanLine[Ly];
      FillChar(MP^, FStrokeReplace.Width, 0);
    end;
  end;
  inherited MouseDown(Shift, X, Y);
end;

constructor TRetouchBrushTool.Create(AOwner: TfrmMain);
begin
  inherited Create(AOwner);
  FStrokeReplace := nil;
end;

destructor TRetouchBrushTool.Destroy;
begin
  FStrokeReplace.Free;
  inherited;
end;

procedure TRetouchBrushTool.MouseUp(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Shift, X, Y);
  FStrokeReplace.Free;
  FStrokeReplace := nil;
end;

{ Odcień (0..360 stopni) i nasycenie (0..1) koloru w modelu HSL. Używane przez
  zamianę koloru z zachowaniem modelunku. }
procedure ColorToHslHS(AR, AG, AB: Integer; out AH: Double; out ASat: Double);
var
  MaxC, MinC, D: Double;
begin
  MaxC := Max(AR, Max(AG, AB));
  MinC := Min(AR, Min(AG, AB));
  D := MaxC - MinC;
  AH := 0;
  if D = 0 then
    ASat := 0
  else
  begin
    if MaxC = AR then
      AH := 60 * (AG - AB) / D
    else if MaxC = AG then
      AH := 60 * (2 + (AB - AR) / D)
    else
      AH := 60 * (4 + (AR - AG) / D);
    if AH < 0 then
      AH := AH + 360;
    ASat := D / (255 - Abs(MaxC + MinC - 255));
  end;
end;

{ HSL -> RGB. AH 0..360 stopni, ASat 0..1, AL 0..255. Jasność pochodzi z
  piksela oryginału, a odcień i nasycenie z koloru nowego - dzięki temu obiekt
  naprawdę zmienia barwę (niebieski -> żółty), a jego rozświetlenie zostaje
  oryginalne. Mnożenie przez stosunek luminancji tego nie daje: przy dużej
  różnicy jasności oryginału i nowego koloru wychodzi ciemna oliwka zamiast
  nowego koloru. }
procedure HslToRgb(AH: Double; ASat: Double; AL: Integer; out AR, AG, AB: Integer);
var
  C, X, M, Hh, Fr: Double;
  Sec: Integer;
begin
  C := (255 - Abs(2 * AL - 255)) * ASat;
  Hh := AH / 60;
  Sec := Trunc(Hh);
  Fr := Hh - Sec;
  // X = C * (1 - |(Hh mod 2) - 1|). Operator `mod` w Delphi działa tylko na
  // typach całkowitych, a Hh jest Double, więc liczymy to inaczej: dla
  // parzystego sektora Hh mod 2 = Fr, dla nieparzystego = Fr + 1, z czego
  // X = C*Fr (parzysty) albo X = C*(1-Fr) (nieparzysty).
  if (Sec mod 2) = 0 then
    X := C * Fr
  else
    X := C * (1 - Fr);
  M := AL - C / 2;
  case Sec of
    0: begin AR := Round(C); AG := Round(X); AB := 0; end;
    1: begin AR := Round(X); AG := Round(C); AB := 0; end;
    2: begin AR := 0; AG := Round(C); AB := Round(X); end;
    3: begin AR := 0; AG := Round(X); AB := Round(C); end;
    4: begin AR := Round(X); AG := 0; AB := Round(C); end;
    5: begin AR := Round(C); AG := 0; AB := Round(X); end;
  else
    AR := Round(AL); AG := Round(AL); AB := Round(AL);
  end;
  AR := AR + Round(M);
  AG := AG + Round(M);
  AB := AB + Round(M);
end;

procedure TRetouchBrushTool.ApplyPixel(Work: TBitmap; X, Y: Integer);
var
  W, H, Str, Sx, Sy, I, SumR, SumG, SumB, ColR, ColG, ColB: Integer;
  C: Cardinal;
  P, Pb: PRGBTripleArray;
  RM: PByte;                           // wiersz maski anty-nakładania (zamiana koloru)
  Neighb: array[0..8] of TRGBTriple;
  TargetC, NewC: Cardinal;
  TargetR, TargetG, TargetB, NewR, NewG, NewB, Tol, SrcLum: Integer;
  MixR, MixG, MixB: Integer;
  NewH, NewS: Double;
begin
  W := Work.Width;
  H := Work.Height;
  Str := FOwner.FRetouchStrength;
  P := Work.ScanLine[Y];
  case FOwner.FBrushMode of
    bmPaint:
      begin
        // Kumulujące krycie na roboczej kopii - nakładające się stempl
        // stopniowo dochodzą do pełnego koloru (jak spray).
        C := ColorToRGB(FOwner.FForeColor);
        ColR := C and $FF;            // TRGBTriple trzyma kanały B,G,R
        ColG := (C shr 8) and $FF;
        ColB := (C shr 16) and $FF;
        P[X].R := ClampByte((P[X].R * (100 - Str) + ColR * Str) div 100);
        P[X].G := ClampByte((P[X].G * (100 - Str) + ColG * Str) div 100);
        P[X].B := ClampByte((P[X].B * (100 - Str) + ColB * Str) div 100);
      end;
    bmClone:
      begin
        // Kopiowanie oryginału z przesunięciem (FCloneOffX/Y), mikstura z
        // aktualną treścią wg siły - baza = robocza kopia (kumulacja).
        Sx := X + FCloneOffX;
        Sy := Y + FCloneOffY;
        if Sx < 0 then Sx := 0;
        if Sy < 0 then Sy := 0;
        if Sx >= W then Sx := W - 1;
        if Sy >= H then Sy := H - 1;
        Pb := FStrokeSrc.ScanLine[Sy];
        P[X].R := ClampByte((P[X].R * (100 - Str) + Pb[Sx].R * Str) div 100);
        P[X].G := ClampByte((P[X].G * (100 - Str) + Pb[Sx].G * Str) div 100);
        P[X].B := ClampByte((P[X].B * (100 - Str) + Pb[Sx].B * Str) div 100);
      end;
    bmDodge:
      begin
        // Rozjaśnianie: przesunięcie ku 255 o siłę; kumulatywne (baza = roboczy
        // piksel P), nakładające stempl budują efekt. Skok jednego stempla
        // ograniczony cRetouchMaxStep, żeby Siła=100 nie dawała jednorazowej
        // bieli - pełnego rozjaśnienia dochodzi się kolejnymi przejściami.
        P[X].R := ClampByte(P[X].R + Min(cRetouchMaxStep, ((255 - P[X].R) * Str) div 100));
        P[X].G := ClampByte(P[X].G + Min(cRetouchMaxStep, ((255 - P[X].G) * Str) div 100));
        P[X].B := ClampByte(P[X].B + Min(cRetouchMaxStep, ((255 - P[X].B) * Str) div 100));
      end;
    bmBurn:
      begin
        // Ściemnianie: przesunięcie ku 0 o siłę; kumulatywne jak dodge,
        // skok stempla ograniczony cRetouchMaxStep.
        P[X].R := ClampByte(P[X].R - Min(cRetouchMaxStep, (P[X].R * Str) div 100));
        P[X].G := ClampByte(P[X].G - Min(cRetouchMaxStep, (P[X].G * Str) div 100));
        P[X].B := ClampByte(P[X].B - Min(cRetouchMaxStep, (P[X].B * Str) div 100));
      end;
    bmSharpen, bmBlur:
      begin
        // 3x3 z snapshotu (krawędzie klampowane) - deterministyczne.
        SumR := 0;
        SumG := 0;
        SumB := 0;
        for I := 0 to 8 do
        begin
          Sx := X + (I mod 3) - 1;
          Sy := Y + (I div 3) - 1;
          if Sx < 0 then Sx := 0;
          if Sy < 0 then Sy := 0;
          if Sx >= W then Sx := W - 1;
          if Sy >= H then Sy := H - 1;
          Pb := FStrokeSrc.ScanLine[Sy];
          Neighb[I] := Pb[Sx];
        end;
        if FOwner.FBrushMode = bmSharpen then
        begin
          // Laplacjan 4-sąsiedni: now = 5*c - (N+E+W+S), mikstura z siłą.
          SumR := Neighb[1].R + Neighb[3].R + Neighb[5].R + Neighb[7].R;
          SumG := Neighb[1].G + Neighb[3].G + Neighb[5].G + Neighb[7].G;
          SumB := Neighb[1].B + Neighb[3].B + Neighb[5].B + Neighb[7].B;
          ColR := ClampByte(5 * Neighb[4].R - SumR);
          ColG := ClampByte(5 * Neighb[4].G - SumG);
          ColB := ClampByte(5 * Neighb[4].B - SumB);
        end
        else
        begin
          // Rozmycie 3x3: średnia wszystkich dziewięciu, mikstura z siłą.
          for I := 0 to 8 do
          begin
            SumR := SumR + Neighb[I].R;
            SumG := SumG + Neighb[I].G;
            SumB := SumB + Neighb[I].B;
          end;
          ColR := SumR div 9;
          ColG := SumG div 9;
          ColB := SumB div 9;
        end;
        P[X].R := ClampByte(Neighb[4].R + ((ColR - Neighb[4].R) * Str) div 100);
        P[X].G := ClampByte(Neighb[4].G + ((ColG - Neighb[4].G) * Str) div 100);
        P[X].B := ClampByte(Neighb[4].B + ((ColB - Neighb[4].B) * Str) div 100);
      end;
    bmColorReplace:
      begin
        // Zamiana koloru: piksel porównywany z kolorem do zamiany
        // (FForeColor). Siła NIE jest kryciem, tylko zasięgiem dopasowania:
        // Tol rośnie od bazowej tolerancji do 255, czyli przy Str=100 cały
        // plam pędzla. Konwersja jest bezwzględna (P := Mix), a nie
        // przesunięciem o Str% - dzięki temu powtórne przejście daje
        // DOKŁADNIE ten sam piksel, więc farba nie kumuluje się jak
        // kolejna warstwa. Opcja FReplaceRetainShading decyduje, JAKI kolor
        // dostaje piksel: False = płaski FReplaceColor (kryjąca farba),
        // True = rekolor HSL, czyli odcień i nasycenie z FReplaceColor przy
        // jasności oryginału - obiekt naprawdę zmienia barwę, a jego
        // rozświetlenie zostaje oryginalne.
        RM := nil;
        // Siła 0 = narzędzie nic nie robi. Bez tego wyjścia piksele
        // trafiające w bazową tolerancję byłyby podmieniane w całości.
        if Str = 0 then Exit;
        // Anty-nakładanie: w obrębie jednego pociągnięcia piksel ma być
        // zdecydowany RAZ. Maska żyje od MouseDown do MouseUp, więc
        // kolejne pociągnięcia niczego nie blokują i nic nie sumują.
        if FStrokeReplace <> nil then
        begin
          RM := FStrokeReplace.ScanLine[Y];
          if RM[X] <> 0 then Exit;
        end;
        TargetC := ColorToRGB(FOwner.FForeColor);
        TargetR := TargetC and $FF;
        TargetG := (TargetC shr 8) and $FF;
        TargetB := (TargetC shr 16) and $FF;
        NewC := ColorToRGB(FOwner.FReplaceColor);
        NewR := NewC and $FF;
        NewG := (NewC shr 8) and $FF;
        NewB := (NewC shr 16) and $FF;
        if FOwner.FReplaceRetainShading then
          ColorToHslHS(NewR, NewG, NewB, NewH, NewS);
        // Pas dopasowania to wyłącznie tolerancja (0..100 -> 0..255) — siła NIE
        // rozszerza go, bo przy Str=100 dawałaby 255 i suwak tolerancji byłby
        // martwy. Siła skaluje promień malowanego dysku (RetouchEffectiveRadius).
        Tol := FOwner.FRetouchTolerance * 51 div 20;
        if (Abs(P[X].R - TargetR) <= Tol) and
           (Abs(P[X].G - TargetG) <= Tol) and
           (Abs(P[X].B - TargetB) <= Tol) then
        begin
          if FOwner.FReplaceRetainShading then
          begin
            // Jasność oryginału = środek min/max, czyli 0..255 bez wag 299/587/114.
            // Bierzemy ją z BIEŻĄCEGO piksela: przy pierwszym trafieniu w danym
            // pociągnięciu jest to Pb, a po konwersji jasność się nie zmienia,
            // więc Mix jest stabilny i powtórne przejścia nie ciemnią obrazu.
            SrcLum := (Max(P[X].R, Max(P[X].G, P[X].B)) +
              Min(P[X].R, Min(P[X].G, P[X].B))) div 2;
            HslToRgb(NewH, NewS, SrcLum, MixR, MixG, MixB);
          end
          else
          begin
            MixR := NewR;
            MixG := NewG;
            MixB := NewB;
          end;
          // Bezwzględne przypisanie: powtórne przejście daje ten sam piksel.
          P[X].R := ClampByte(MixR);
          P[X].G := ClampByte(MixG);
          P[X].B := ClampByte(MixB);
          if RM <> nil then RM[X] := Str;
        end;
      end;
  end;
end;

function TfrmMain.UseCustomTitleBar: Boolean;
begin
  Result := False;
end;

function ConfirmSaveDlg(const Msg: string): Integer;
var
  Frm: TForm;
  I: Integer;
begin
  Frm := CreateMessageDialog(Msg, mtConfirmation, [mbYes, mbNo, mbCancel]);
  try
    Frm.Caption := 'Fotografista';
    for I := 0 to Frm.ComponentCount - 1 do
      if Frm.Components[I] is TButton then
        case TButton(Frm.Components[I]).ModalResult of
          mrYes:    TButton(Frm.Components[I]).Caption := T('Yes');
          mrNo:     TButton(Frm.Components[I]).Caption := T('No');
          mrCancel: TButton(Frm.Components[I]).Caption := T('Cancel');
        end;
    Result := Frm.ShowModal;
  finally
    Frm.Free;
  end;
end;

function SaveExtSupported(const AName: string): Boolean;
var
  E: string;
begin
  E := LowerCase(ExtractFileExt(AName));
  Result := (E = '.bmp') or (E = '.jpg') or (E = '.jpeg') or (E = '.png') or
    (E = '.gif') or (E = '.tif') or (E = '.tiff') or (E = '.webp');
end;

function PixelFormatBits(pf: TPixelFormat): Integer;
begin
  case pf of
    pf1bit:  Result := 1;
    pf4bit:  Result := 4;
    pf8bit:  Result := 8;
    pf15bit: Result := 15;
    pf16bit: Result := 16;
    pf24bit: Result := 24;
    pf32bit: Result := 32;
  else
    Result := 0;
  end;
end;

procedure LoadExternalStyles;
var
  StyleDir, FileName: string;
  SR: TSearchRec;
begin
  StyleDir := ExtractFilePath(ParamStr(0)) + 'Styles\';
  if not DirectoryExists(StyleDir) then Exit;
  if FindFirst(StyleDir + '*.vsf', faAnyFile, SR) <> 0 then Exit;
  try
    repeat
      FileName := StyleDir + SR.Name;
      try
        TStyleManager.LoadFromFile(FileName);
      except
        // uszkodzony plik lub duplikat nazwy — pomiń, aplikacja startuje dalej
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

const
  ZOOM_STEPS: array[0..4] of Double = (0.25, 0.5, 1.0, 2.0, 4.0);

{ ========================================================================= }
{  Theme label colors }
{  Etykiety z usunietym seFont (StyleElements=[seClient,seBorder]) rysuja
{  tekst przez DoDrawNormalText (Vcl.StdCtrls.pas:2842), wiec motyw nie
{  nadaje koloru — zostaje czarny clWindowText. Ustawiamy kolor z motywu
{  recznie, zeby nie tracic kontroli nad rozmiarem fontu. }
{ ========================================================================= }

procedure ApplyThemeLabelColors(AContainer: TComponent);
var
  I: Integer;
  C: TComponent;
  Lbl: TLabel;
begin
  if not StyleServices.Enabled then Exit;
  for I := 0 to AContainer.ComponentCount - 1 do
  begin
    C := AContainer.Components[I];
    if C is TLabel then
    begin
      Lbl := TLabel(C);
      if (not (seFont in Lbl.StyleElements)) and (Lbl.Font.Color = clWindowText) then
        Lbl.Font.Color := StyleServices.GetStyleFontColor(sfTextLabelNormal);
    end
    else
      ApplyThemeLabelColors(C);
  end;
end;

procedure TfrmMain.FormActiveChanged(Sender: TObject);
begin
  if Screen.ActiveForm <> nil then
  begin
    ApplyThemeLabelColors(Screen.ActiveForm);
    TranslateForm(Screen.ActiveForm);
  end;
end;

{ ========================================================================= }
{  Form lifecycle }
{ ========================================================================= }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Randomize;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf24bit;
  FMipPyramid := nil;
  FMipLevelBmp := nil;
  FMipLevelIdx := -1;
  FScaleCache := nil;
  FRasterPreview := False;
  FZoomFactor := 1.0;
  FFilePath := '';
  FDirty := False;
  FSelection := TSelection.Create;
  FSelection.OnRepaintReq := SelectionRepaint;
  FSelecting := False;
  FSelMode := 'new';
  FSelHandle := hhNone;
  FPanning := False;
  FRetouchBrushSize := 10;
  FRetouchStrength := 100;
  FRetouchTolerance := 20;
  FBrushMode := bmPaint;
  FForeColor := clBlack;
  FReplaceColor := clYellow;
  FReplaceRetainShading := True;
  FActiveToolKind := tkSelection;
  FPanelErase := True;
  FBrushCursorOn := False;
  FAlphaMask := nil;
  FAlphaDirtyRect := Rect(0, 0, 0, 0);
  FActiveTool := TSelectionTool.Create(Self);
  OnCloseQuery := FormCloseQuery;
  DoubleBuffered := True;
  DragAcceptFiles(Handle, True);

  UndoInit;
  LoadPrefs;
  LoadExternalStyles;
  TStyleManager.TrySetStyle(Prefs.ThemeName);
  Screen.OnActiveFormChange := FormActiveChanged;
  if Prefs.RememberWin and (Prefs.WinLeft >= 0) then
    Position := poDesigned;
  Self.Color := Prefs.CanvasBG;
  StatusBar.UseSystemFont := False;
  StatusBar.Font.Size := Application.DefaultFont.Size;
  MainMenu.OwnerDraw := True;
  MainMenu.AutoHotkeys := maManual;
  RestoreWindowPos(Self);
  RebuildRecentMenu(mnuFile, mnuFileSepRecent, HandleRecentFileClick);
  InitMenuMeasure;
  UpdateStatusBar;
  UpdateMenuState;
  Application.OnHint := StatusBarHint;

  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnMessage := AppMessage;
end;

procedure TfrmMain.MenuItemMeasure(Sender: TObject; ACanvas: TCanvas;
  var Width, Height: Integer);
begin
  if TMenuItem(Sender).GetParentComponent is TMainMenu then Exit;
  if TMenuItem(Sender).IsLine then Exit;
  if TMenuItem(Sender).ShortCut <> scNone then Exit;
  Width := Width + 12 + MulDiv(12, Screen.PixelsPerInch, 96) - 1;
end;

procedure TfrmMain.AssignMenuMeasure(AItem: TMenuItem);
var
  I: Integer;
begin
  if AItem = nil then Exit;
  AItem.OnMeasureItem := MenuItemMeasure;
  for I := 0 to AItem.Count - 1 do
    AssignMenuMeasure(AItem[I]);
end;

procedure TfrmMain.InitMenuMeasure;
begin
  AssignMenuMeasure(MainMenu.Items);
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Res: Integer;
begin
  if not FDirty then Exit;
  Res := ConfirmSaveDlg(T('The image has not been saved.') + #13#10 +
    T('Do you want to save your changes before closing?'));
  case Res of
    mrYes:
      begin
        mnuFileSaveAsClick(Self);
        CanClose := not FDirty;
      end;
    mrNo:
      CanClose := True;
    mrCancel:
      CanClose := False;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveWindowPos(Self);
  Action := caFree;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if HandleAllocated then
    DragAcceptFiles(Handle, False);
  Application.OnHint := nil;
  FScaleCache.Free;
  FBacking.Free;
  FMipLevelBmp.Free;
  FMipPyramid.Free;
  FActiveTool := nil;
  FAlphaMask.Free;
  FProtMask.Free;
  FBitmap.Free;
  FSelection.Free;
end;

procedure TfrmMain.AppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  // W = pokaz/ukryj wyrzutnie (odpowiednik shortcut="w" z menu Hollywood).
  // Spacja jest zarezerwowana dla spacja+LPM = przewijanie obrazu, więc
  // nie jest już skrótem wyrzutni. Nie przechwytuj, gdy: otwarty modal
  // albo panning w toku.
  if (Msg.message = WM_KEYDOWN) and (Msg.wParam = Ord('W')) and
     (Application.ModalLevel = 0) and (not FPanning) then
  begin
    mnuLauncherClick(Self);
    Handled := True;
  end;
  // R = pokaz/ukryj panel Narzędzi (odpowiednik shortcut="r" z menu Hollywood).
  // Ten sam zestaw guardów co W: modal nie przechwytuje, panning nie koliduje.
  if (Msg.message = WM_KEYDOWN) and (Msg.wParam = Ord('R')) and
     (Application.ModalLevel = 0) and (not FPanning) then
  begin
    mnuToolsPanelClick(Self);
    Handled := True;
  end;
end;

procedure TfrmMain.PaintBoxPaint(Sender: TObject);
var
  DestRect, FullR: TRect;
  DispW, DispH: Integer;
  SrcRect: TRect;
  I, Pass: Integer;
begin
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then
    Exit;

  DispW := Round(FBitmap.Width * FZoomFactor);
  DispH := Round(FBitmap.Height * FZoomFactor);

  if (DispW < 1) or (DispH < 1) then
    Exit;

  // PaintBox jest ustawiony dokładnie na obrazie — współrzędne lokalne = obraz w skali.
  DestRect := Rect(0, 0, DispW, DispH);
  SrcRect := Rect(0, 0, FBitmap.Width, FBitmap.Height);
  FullR := Rect(0, 0, PaintBox.Width, PaintBox.Height);

  // FBacking = "czysty kadr" PaintBoxa (obraz + szachownica + overlay, BEZ
  // pierścienia). Pierścień w MouseMove kopiuje stare tło 1:1 z tego bufora,
  // więc każdy piksel ma DOKŁADNIE jedno źródło — koniec migotania kwadratu
  // pod pędzlem (wcześniej pierścień rysował z FBitmap/FScaleCache, a przelotny
  // repaint formy DoubleBuffered przywracał inny stan tego samego piksela).
  if FBacking = nil then
    FBacking := TBitmap.Create;
  FBacking.PixelFormat := pf24bit;
  if (FBacking.Width <> PaintBox.Width) or (FBacking.Height <> PaintBox.Height) then
    FBacking.SetSize(PaintBox.Width, PaintBox.Height);

  // Płynne skalowanie podglądu (prefs): gładkie przy pomniejszaniu, szybkie przy powiększaniu.
  // Pre-blur (piramida mip-map FMipPyramid) tylko gdy podgląd jest periodycznym rastrem
  // (FRasterPreview) — zwykłe zdjęcia rysowane ostro, bez rozmycia.
  if Prefs.SmoothPreview and (FZoomFactor < 1.0) then
  begin
    SetStretchBltMode(FBacking.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(FBacking.Canvas.Handle, 0, 0, nil);
    // Cache skalowanego podglądu także dla zwykłych zdjęć (nie tylko rastra):
    // pociągnięcie gumki nie przebudowuje pełnego HALFTONE StretchDraw całego
    // obrazka przy każdym WM_PAINT, a jedynie rysuje cache + szachownicę maski.
    // Klucz (handle, zoom); maska alfa nie unieważnia cache.
    if (FScaleCache = nil) or (FScaleCacheZoom <> FZoomFactor) or
       (FScaleCacheHandle <> FBitmap.Handle) then
    begin
      if FRasterPreview then
        BuildSmoothPreview
      else
        BuildPlainPreview;
    end;
    if FScaleCache <> nil then
      FBacking.Canvas.Draw(0, 0, FScaleCache)
    else
      FBacking.Canvas.StretchDraw(DestRect, FBitmap);
  end
  else
  begin
    SetStretchBltMode(FBacking.Canvas.Handle, COLORONCOLOR);
    FBacking.Canvas.StretchDraw(DestRect, FBitmap);
  end;

  // Szachownica jako znak przezroczystości (maska alfa); zero kosztu bez dziur.
  DrawTransparencyChecker(FBacking.Canvas);

  // Selection overlay (also drawn during drag)
  if (FSelection.W > 0) and (FSelection.H > 0) then
    FSelection.Draw(FBacking.Canvas, FZoomFactor, 0, 0,
      FSelection.Active, FBitmap.Width, FBitmap.Height);

  // Podgląd lassa w trakcie rysowania: czarna linia + biała kropkowana na wierzchu
  if FLassoDrawing and (Length(FLassoPts) >= 2) then
  begin
    FBacking.Canvas.Brush.Style := bsClear;
    FBacking.Canvas.Pen.Width := 1;
    for Pass := 0 to 1 do
    begin
      if Pass = 0 then
      begin
        FBacking.Canvas.Pen.Color := clBlack;
        FBacking.Canvas.Pen.Style := psSolid;
      end
      else
      begin
        FBacking.Canvas.Pen.Color := clWhite;
        FBacking.Canvas.Pen.Style := psDot;
      end;
      FBacking.Canvas.MoveTo(Round(FLassoPts[0].X * FZoomFactor),
        Round(FLassoPts[0].Y * FZoomFactor));
      for I := 1 to High(FLassoPts) do
        FBacking.Canvas.LineTo(Round(FLassoPts[I].X * FZoomFactor),
          Round(FLassoPts[I].Y * FZoomFactor));
      FBacking.Canvas.LineTo(Round(FLassoPts[0].X * FZoomFactor),
        Round(FLassoPts[0].Y * FZoomFactor));
    end;
    FBacking.Canvas.Pen.Style := psSolid;
    FBacking.Canvas.Brush.Style := bsSolid;
  end;

  // Overlay maski ochronnej (kreskowanie, tylko gdy włączone)
  if FShowProtMask then
    DrawProtMaskOverlay(FBacking.Canvas);

  // Atomowa publikacja czystego kadru do widoku (pod pierścieniem leży zawsze
  // ten sam spójny stan).
  PaintBox.Canvas.CopyRect(FullR, FBacking.Canvas, FullR);

  // Kółko pędzla zamiast wskaźnika myszy (aktywna gumka, crNone).
  DrawBrushCursor;
end;

procedure TfrmMain.InvalidatePreviewCache;
begin
  FScaleCache.Free;
  FScaleCache := nil;
  FScaleCacheHandle := 0;
  FScaleCacheZoom := 0;
  FMipLevelBmp.Free;
  FMipLevelBmp := nil;
  FMipLevelKey := 0;
  FMipLevelIdx := -1;
  if FMipPyramid <> nil then
    FMipPyramid.Invalidate;
end;

// ⚠️ WYDAJNOŚĆ (2026-08): pierworodna wersja blurowała PEŁNE źródło przy każdym kroku
// zoomu (klucz cache (handle, zoom) -> BoxBlur w pętli zooma = zawieszenia UI). Obecnie:
// blur liczy się RAZ na zmianę zawartości (klucz: handle) do piramidy mip-map (uMipMap.pas),
// a każda zmiana zoomu przebudowuje tylko mały FScaleCache tanim StretchDraw (bez blura).
//
// Uwaga: GR32 Blur32 to filtr IIR Younga-van Vliet — koszt O(W*H) NIEZALEŻNY od radiusu
// (patrz GR32.Blur.RecursiveGaussian.pas:94-103), stan lokalny per call. Jednorazowy blur
// 48 MP to ~100-300 ms przy loadzie/edycji, a nie per krok zoomu.
//
// Nyquist (rozwiązane piramidą): jeden stały radius (kalibrowany do DispW=1000) nie był
// poprawny dla wszystkich poziomów zoom-out — dawał za mocny blur przy zoom ~0.88 i za słaby
// przy głębokim zoom-out (moiré rastra). TMipPyramid: level0=ostre źródło, każdy następny
// poziom = blur+½; przy zoomie wybór poziomu daje decymację resztkową <= 2x. level0 używane
// tylko dla zoom >= MinZoomForL0 (zapas Nyquista), niżej wybrany poziom konwertowany do
// FMipLevelBmp (klucz: handle+indeks) i StretchDraw do FScaleCache.
// Unieważnianie (InvalidatePreviewCache) pokrywa wszystkie 7 punktów zmiany zawartości:
// FinishEffect, undo, redo, paste, revert, load, close.
//
// FRasterPreview (gate): blur ścieżki wykonuje się TYLKO gdy podgląd jest periodycznym
// rastrem (Riso V1/V2/V3, Sitodruk, Nadruk) — patrz PaintBoxPaint. Zwykłe zdjęcia rysowane
// ostro (HALFTONE na źródle, bez rozmycia). Flagę ustawiają handlerzy tych 5 efektów PO
// FinishEffect (inaczej zostałaby skasowana), a czyści 7 punktów jak wyżej — w tym
// FinishEffect, więc "kolor po riso" wyłącza blur (znane ograniczenie, moiré wtedy wraca).
procedure TfrmMain.EnsureMipPyramid;
begin
  if FMipPyramid = nil then
    FMipPyramid := TMipPyramid.Create;
  if FMipPyramid.SourceHandle <> FBitmap.Handle then
    FMipPyramid.Build(FBitmap);
end;

procedure TfrmMain.BuildSmoothPreview;
var
  DispW, DispH, LvlIdx: Integer;
  DrawSource: TBitmap;
  Level: TBitmap32;
begin
  DispW := Round(FBitmap.Width * FZoomFactor);
  DispH := Round(FBitmap.Height * FZoomFactor);
  if (DispW < 1) or (DispH < 1) then
  begin
    InvalidatePreviewCache;
    Exit;
  end;

  EnsureMipPyramid;
  if FMipPyramid.Source = nil then Exit;

  LvlIdx := FMipPyramid.LevelIndexForZoom(FZoomFactor);
  if LvlIdx = 0 then
    DrawSource := FBitmap              // L=0: ostre źródło (zoom >= MinZoomForL0)
  else
  begin
    Level := FMipPyramid.Level(LvlIdx);
    if Level = nil then Exit;
    if (FMipLevelBmp = nil) or (FMipLevelKey <> FBitmap.Handle) or
       (FMipLevelIdx <> LvlIdx) then
    begin
      if FMipLevelBmp = nil then
        FMipLevelBmp := TBitmap.Create;
      FMipLevelBmp.Assign(Level);      // adapter GR32 -> pf32bit
      FMipLevelBmp.PixelFormat := pf24bit;  // konsumenci czytają ScanLine 3 bajty/piksel
      FMipLevelKey := FBitmap.Handle;
      FMipLevelIdx := LvlIdx;
    end;
    DrawSource := FMipLevelBmp;
  end;

  if FScaleCache = nil then
    FScaleCache := TBitmap.Create;
  FScaleCache.PixelFormat := pf24bit;
  FScaleCache.SetSize(DispW, DispH);
  SetStretchBltMode(FScaleCache.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(FScaleCache.Canvas.Handle, 0, 0, nil);
  FScaleCache.Canvas.StretchDraw(Rect(0, 0, DispW, DispH), DrawSource);
  FScaleCacheHandle := FBitmap.Handle;
  FScaleCacheZoom := FZoomFactor;
end;

// Zwykłe zdjęcia (FRasterPreview = False): ten sam cache co BuildSmoothPreview
// (klucz: handle+zoom), ale bez piramidy mip-map - czyste HALFTONE skalowanie
// źródła, identyczne wizualnie z poprzednim bezpośrednim StretchDraw w PaintBoxPaint.
procedure TfrmMain.BuildPlainPreview;
var
  DispW, DispH: Integer;
begin
  DispW := Round(FBitmap.Width * FZoomFactor);
  DispH := Round(FBitmap.Height * FZoomFactor);
  if (DispW < 1) or (DispH < 1) then
  begin
    InvalidatePreviewCache;
    Exit;
  end;
  if FScaleCache = nil then
    FScaleCache := TBitmap.Create;
  FScaleCache.PixelFormat := pf24bit;
  FScaleCache.SetSize(DispW, DispH);
  SetStretchBltMode(FScaleCache.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(FScaleCache.Canvas.Handle, 0, 0, nil);
  FScaleCache.Canvas.StretchDraw(Rect(0, 0, DispW, DispH), FBitmap);
  FScaleCacheHandle := FBitmap.Handle;
  FScaleCacheZoom := FZoomFactor;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  if FBitmap.Width > 0 then
    UpdateZoomFit;
end;

procedure TfrmMain.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  mnuViewZoomOutClick(Sender);
  Handled := True;
end;

procedure TfrmMain.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  mnuViewZoomInClick(Sender);
  Handled := True;
end;

procedure TfrmMain.ScrollBoxMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  mnuViewZoomOutClick(Sender);
  Handled := True;
end;

procedure TfrmMain.ScrollBoxMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  mnuViewZoomInClick(Sender);
  Handled := True;
end;

procedure TfrmMain.ScrollBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
begin
  // PPM czyści zaznaczenie niezależnie od miejsca kliknięcia (cały viewport),
  // zgodnie z Hollywood (events.hws MouseRight). Obszar ramki unieważniany PRZED Clear.
  if Button <> mbRight then Exit;
  if FSelecting then
  begin
    R := SelectionScreenRect;
    FSelecting := False;
    FSelMode := 'new';
    FSelection.Clear;
    InvalidatePaintRect(R);
  end
    else if FSelection.Active then
    begin
      R := SelectionScreenRect;
      FSelection.Clear;
      InvalidatePaintRect(R);
    end;
end;

procedure TfrmMain.ScrollBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
  SpaceDown: Boolean;
begin
  if not FPanning then Exit;
  SpaceDown := (GetAsyncKeyState(VK_SPACE) and $8000) <> 0;
  // Zabezpieczenie: przycisk/spacja puszczone bez ScrollBoxMouseUp (np. capture
  // przerwany) - kończymy panning, zamiast zostawiać go zablokowanego.
  if not ((ssMiddle in Shift) or ((ssLeft in Shift) and SpaceDown)) then
  begin
    FPanning := False;
    Mouse.Capture := 0;
    PaintBox.Cursor := crDefault;
    Screen.Cursor := crDefault;
    Exit;
  end;
  P := Mouse.CursorPos;
  // Współrzędne ekranowe: niezależne od przesuwającego się PaintBoxa, więc zero
  // sprzężenia - obraz płynie 1:1 za kursorem.
  ScrollBox.HorzScrollBar.Position := FPanOrgSX - (P.X - FPanOrgX);
  ScrollBox.VertScrollBar.Position := FPanOrgSY - (P.Y - FPanOrgY);
end;

procedure TfrmMain.ScrollBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not FPanning then Exit;
  FPanning := False;
  Mouse.Capture := 0;
  PaintBox.Cursor := crDefault;
  Screen.Cursor := crDefault;
end;

procedure TfrmMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  R: TRect;
  IX, IY: Integer;
begin
  // Pan: środkowy przycisk lub spacja+LPM (konwencja Photoshop). Stan spacji
  // sprawdzany przez GetAsyncKeyState - nie zależy od fokusa klawiatury.
  // LPM bez spacji trafia w normalną gałąź selekcji poniżej.
  if (Button = mbMiddle) or
     ((Button = mbLeft) and ((GetAsyncKeyState(VK_SPACE) and $8000) <> 0)) then
  begin
    FPanning := True;
    FPanOrgX := Mouse.CursorPos.X;
    FPanOrgY := Mouse.CursorPos.Y;
    FPanOrgSX := ScrollBox.HorzScrollBar.Position;
    FPanOrgSY := ScrollBox.VertScrollBar.Position;
    PaintBox.Cursor := crSizeAll;
    Screen.Cursor := crSizeAll;
    Mouse.Capture := ScrollBox.Handle;
    Exit;
  end;

  // PPM czyści zaznaczenie — obszar ramki unieważniany PRZED Clear.
  // W trybie zamiany koloru (pędzel, bmColorReplace) PPM zamiast tego
  // pobiera kolor do zamiany (jak zakraplacz) — zaznaczenie nietknięte.
  if Button = mbRight then
  begin
    if (FActiveToolKind = tkBrush) and (FBrushMode = bmColorReplace) and
       (FBitmap.Width > 0) and (FBitmap.Height > 0) then
    begin
      IX := Round(X / FZoomFactor);
      IY := Round(Y / FZoomFactor);
      if IX < 0 then IX := 0;
      if IY < 0 then IY := 0;
      if IX >= FBitmap.Width then IX := FBitmap.Width - 1;
      if IY >= FBitmap.Height then IY := FBitmap.Height - 1;
      SetForeColor(FBitmap.Canvas.Pixels[IX, IY]);
      Exit;
    end;
    if FSelecting then
    begin
      R := SelectionScreenRect;
      FSelecting := False;
      FSelMode := 'new';
      FSelection.Clear;
      InvalidatePaintRect(R);
    end
    else if FSelection.Active then
    begin
      R := SelectionScreenRect;
      FSelection.Clear;
      InvalidatePaintRect(R);
    end;
    Exit;
  end;

  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then Exit;

  // LPM: delegacja do aktywnego narzędzia (domyślnie TSelectionTool —
  // jej przeniesiona logika zaznaczenia jest w sekcji implementation).
  // Pan i PPM obsłużone wyżej, tutaj już tylko narzędzie.
  if Button = mbLeft then
  begin
    if FActiveTool <> nil then
      FActiveTool.MouseDown(Shift, X, Y);
    Exit;
  end;
end;

procedure TfrmMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  // Pan: WM_MOUSEMOVE przy aktywnym capture na ScrollBox jest routowany przez VCL
  // do PaintBox (kontrolka pod kursorem), więc pan obsługujemy tutaj, a delta
  // liczona we współrzędnych EKRANOWYCH (Mouse.CursorPos) - niezależna od
  // przesuwającego się PaintBoxa, zero sprzężenia (w przeciwieństwie do
  // pozycji lokalnych X/Y z v2, które dawały drganie).
  if FPanning then
  begin
    P := Mouse.CursorPos;
    ScrollBox.HorzScrollBar.Position := FPanOrgSX - (P.X - FPanOrgX);
    ScrollBox.VertScrollBar.Position := FPanOrgSY - (P.Y - FPanOrgY);
    Exit;
  end;

  if FBitmap.Width = 0 then Exit;

  // Delegacja do aktywnego narzędzia (logika kursora i przeciągania
  // zaznaczenia mieszka w TSelectionTool, rysowanie - w TEraserTool).
  if FActiveTool <> nil then
    FActiveTool.MouseMove(Shift, X, Y);
end;

procedure TfrmMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) and (Button <> mbMiddle) then Exit;

  // Koniec pana. WM_*BUTTONUP przy capture na ScrollBox trafia do PaintBox
  // (kontrolka pod kursorem) lub do ScrollBox (gdy puszczono poza obrazem) -
  // oba handlery sprzątają, żeby FPanning nigdy nie został zablokowany.
  if FPanning then
  begin
    FPanning := False;
    Mouse.Capture := 0;
    if FActiveTool is TEraserTool then
      PaintBox.Cursor := crNone
    else
      PaintBox.Cursor := crDefault;
    Screen.Cursor := crDefault;
    Exit;
  end;

  if Button <> mbLeft then Exit;

  // Delegacja do aktywnego narzędzia (commit selekcji/retuszu).
  if FActiveTool <> nil then
    FActiveTool.MouseUp(Shift, X, Y);
end;

{ ========================================================================= }
{  Plik }
{ ========================================================================= }

procedure TfrmMain.mnuFileOpenClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := GetImageFilter;
    Dlg.FilterIndex := 1;
    Dlg.Options := [ofFileMustExist, ofHideReadOnly];
    if Dlg.Execute then
      LoadImage(Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TfrmMain.WMDropFiles(var Msg: TWMDropFiles);
var
  Cnt, Len: Integer;
  FileName: string;
begin
  try
    Cnt := DragQueryFile(Msg.Drop, $FFFFFFFF, nil, 0);
    if Cnt > 0 then
    begin
      Len := DragQueryFile(Msg.Drop, 0, nil, 0);
      if Len > 0 then
      begin
        SetLength(FileName, Len);
        DragQueryFile(Msg.Drop, 0, PChar(FileName), Len + 1);
        SetLength(FileName, StrLen(PChar(FileName)));
        LoadImage(FileName);
      end;
    end;
  finally
    DragFinish(Msg.Drop);
  end;
  Msg.Result := 0;
end;

procedure TfrmMain.mnuFileSaveAsClick(Sender: TObject);
const
  SaveExts: array[1..6] of string = ('.png', '.jpg', '.bmp', '.gif', '.tiff', '.webp');
var
  Dlg: TSaveDialog;
begin
  if FBitmap.Width = 0 then
    Exit;

  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter := GetSaveImageFilter;
    Dlg.FilterIndex := 1;
    Dlg.Options := [ofHideReadOnly, ofPathMustExist];
    if FFilePath <> '' then
      Dlg.FileName := FFilePath;
    while Dlg.Execute do
    begin
      Dlg.FileName := ChangeFileExt(Dlg.FileName, SaveExts[Dlg.FilterIndex]);
      if FileExists(Dlg.FileName) then
        if MessageDlg(Format(T('File "%s" already exists.'), [ExtractFileName(Dlg.FileName)]) + #13#10 +
          T('Overwrite?'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
          Continue;
      SaveImage(Dlg.FileName);
      Break;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure ExportToPdf(ABitmap: TBitmap; const AFilePath: string);
var
  JpgStream: TMemoryStream;
  JpgImg: TJPEGImage;
  Pdf: TFPDF;
  Scale, ImgW, ImgH, X, Y: Double;
begin
  if (ABitmap.Width = 0) or (ABitmap.Height = 0) then Exit;

  JpgImg := TJPEGImage.Create;
  try
    JpgImg.Assign(ABitmap);
    JpgImg.CompressionQuality := 95;
    JpgStream := TMemoryStream.Create;
    try
      JpgImg.SaveToStream(JpgStream);
      JpgStream.Position := 0;

      Pdf := TFPDF.Create(poPortrait, puPT, pfA4);
      try
        Pdf.AddPage;

        Scale := Min(Pdf.GetPageWidth / ABitmap.Width, Pdf.GetPageHeight / ABitmap.Height);
        ImgW := ABitmap.Width * Scale;
        ImgH := ABitmap.Height * Scale;
        X := (Pdf.GetPageWidth - ImgW) / 2;
        Y := (Pdf.GetPageHeight - ImgH) / 2;

        Pdf.Image(JpgStream, 'JPG', X, Y, ImgW, ImgH);
        Pdf.SaveToFile(AFilePath);
      finally
        Pdf.Free;
      end;
    finally
      JpgStream.Free;
    end;
  finally
    JpgImg.Free;
  end;
end;

procedure TfrmMain.mnuFileExportPDFClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then
  begin
    MessageDlg(T('No image loaded.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := T('Export PDF');
    SaveDlg.DefaultExt := '.pdf';
    SaveDlg.Filter := 'PDF|*.pdf';
    if SaveDlg.Execute then
    begin
      ExportToPdf(FBitmap, SaveDlg.FileName);
      MessageDlg(T('PDF saved successfully.'), mtInformation, [mbOK], 0);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmMain.mnuFileExportComparisonClick(Sender: TObject);
var
  Orig, ScaledOrig, ScaledCurrent, Combined: TBitmap;
  OrigW, OrigH, CurrW, CurrH, DstH: Integer;
  SOrigW, SCurrW, TotalW, Margin, SepW: Integer;
  SaveDlg: TSaveDialog;
begin
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then
  begin
    MessageDlg(T('No image loaded.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  if (FFilePath = '') or (not FileExists(FFilePath)) then
  begin
    MessageDlg(T('Cannot compare - image was not opened from a file.'), mtInformation, [mbOK], 0);
    Exit;
  end;

  Orig := LoadImageFile(FFilePath);
  if Orig = nil then
  begin
    MessageDlg(T('Unsupported file format.'), mtError, [mbOK], 0);
    Exit;
  end;
  try
    OrigW := Orig.Width;
    OrigH := Orig.Height;
    CurrW := FBitmap.Width;
    CurrH := FBitmap.Height;

    DstH := Min(1080, Max(OrigH, CurrH));
    if DstH < 1 then DstH := 1;

    SOrigW := Max(1, Round(OrigW / OrigH * DstH));
    SCurrW := Max(1, Round(CurrW / CurrH * DstH));

    ScaledOrig := TBitmap.Create;
    try
      ScaledOrig.SetSize(SOrigW, DstH);
      ScaledOrig.Canvas.StretchDraw(Rect(0, 0, SOrigW, DstH), Orig);

      ScaledCurrent := TBitmap.Create;
      try
        ScaledCurrent.SetSize(SCurrW, DstH);
        ScaledCurrent.Canvas.StretchDraw(Rect(0, 0, SCurrW, DstH), FBitmap);

        Margin := 4;
        SepW := 2;
        TotalW := SOrigW + SepW + Margin * 2 + SCurrW;

        Combined := TBitmap.Create;
        try
          Combined.SetSize(TotalW, DstH);
          Combined.Canvas.Brush.Color := clWhite;
          Combined.Canvas.FillRect(Rect(0, 0, TotalW, DstH));
          Combined.Canvas.Draw(0, 0, ScaledOrig);

          Combined.Canvas.Pen.Color := clSilver;
          Combined.Canvas.MoveTo(SOrigW + Margin, 0);
          Combined.Canvas.LineTo(SOrigW + Margin + SepW - 1, DstH - 1);

          Combined.Canvas.Draw(SOrigW + Margin + SepW + Margin, 0, ScaledCurrent);

          SaveDlg := TSaveDialog.Create(nil);
          try
            SaveDlg.Title := T('Export comparison');
            SaveDlg.DefaultExt := '.png';
            SaveDlg.Filter := 'PNG|*.png';
            if SaveDlg.Execute then
            begin
              SaveImageFile(Combined, SaveDlg.FileName);
              MessageDlg(T('Comparison saved successfully.'), mtInformation, [mbOK], 0);
            end;
          finally
            SaveDlg.Free;
          end;
        finally
          Combined.Free;
        end;
      finally
        ScaledCurrent.Free;
      end;
    finally
      ScaledOrig.Free;
    end;
  finally
    Orig.Free;
  end;
end;

procedure TfrmMain.mnuFileInfoClick(Sender: TObject);
var
  Dlg: TfrmFileInfo;
begin
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then
  begin
    MessageDlg(T('No image loaded.'), mtInformation, [mbOK], 0);
    Exit;
  end;

  Dlg := TfrmFileInfo.Create(nil);
  try
    Dlg.ShowFileInfo(FFilePath, FBitmap);
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmMain.mnuFileCloseClick(Sender: TObject);
var
  Res: Integer;
begin
  if FDirty then
  begin
    Res := ConfirmSaveDlg(T('The image has not been saved.') + #13#10 +
      T('Do you want to save your changes before closing?'));
    case Res of
      mrYes:
        begin
          mnuFileSaveAsClick(Self);
          if FDirty then Exit;
        end;
      mrNo:
        ;
      mrCancel:
        Exit;
    end;
  end;
  CloseImage;
end;

procedure TfrmMain.mnuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.HandleRecentFileClick(Sender: TObject);
var
  Item: TMenuItem;
  Idx: Integer;
  Path: string;
begin
  Item := TMenuItem(Sender);
  Idx := Item.Tag;
  if (Idx < 0) or (Idx >= MAX_RECENT) then
    Exit;
  Path := Prefs.RecentFiles[Idx];
  if (Path <> '') and FileExists(Path) then
    LoadImage(Path)
  else if Path <> '' then
    MessageDlg(T('File does not exist:') + sLineBreak + Path,
      mtWarning, [mbOK], 0);
end;

{ ========================================================================= }
{  Edycja }
{ ========================================================================= }

procedure TfrmMain.mnuEditUndoClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  if Undo(FBitmap, FAlphaMask, FProtMask) then
  begin
    if (FAlphaMask <> nil) and
       ((FAlphaMask.Width <> FBitmap.Width) or (FAlphaMask.Height <> FBitmap.Height)) then
      EnsureAlphaMask;
    if (FProtMask <> nil) and
       ((FProtMask.Width <> FBitmap.Width) or (FProtMask.Height <> FBitmap.Height)) then
      EnsureProtMask;
    RecalcProtCoverCount;
    UpdateLayout;
    FRasterPreview := False;
    InvalidatePreviewCache;
  end;
end;

procedure TfrmMain.mnuEditRedoClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  if Redo(FBitmap, FAlphaMask, FProtMask) then
  begin
    if (FAlphaMask <> nil) and
       ((FAlphaMask.Width <> FBitmap.Width) or (FAlphaMask.Height <> FBitmap.Height)) then
      EnsureAlphaMask;
    if (FProtMask <> nil) and
       ((FProtMask.Width <> FBitmap.Width) or (FProtMask.Height <> FBitmap.Height)) then
      EnsureProtMask;
    RecalcProtCoverCount;
    UpdateLayout;
    FRasterPreview := False;
    InvalidatePreviewCache;
  end;
end;

procedure TfrmMain.mnuEditCopyClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  Clipboard.Assign(FBitmap);
end;

procedure TfrmMain.mnuEditPasteClick(Sender: TObject);
var
  Bmp, Tmp: TBitmap;
begin
  if not Clipboard.HasFormat(CF_BITMAP) then Exit;
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromClipboardFormat(CF_BITMAP, Clipboard.GetAsHandle(CF_BITMAP), 0);

    // Obraz ze schowka bywa pf32bit (4 bajty/piksel). Silnik (SelectionCrop,
    // efekty) czyta ScanLine jako 3 bajty/piksel, a StretchDraw z kanałem alfa
    // przekłamuje kolory — normalizuj do pf24bit zaraz po wczytaniu.
    if Bmp.PixelFormat <> pf24bit then
    begin
      Tmp := TBitmap.Create;
      try
        Tmp.PixelFormat := pf24bit;
        Tmp.Width := Bmp.Width;
        Tmp.Height := Bmp.Height;
        Tmp.Canvas.Draw(0, 0, Bmp);
        Bmp.Assign(Tmp);
      finally
        Tmp.Free;
      end;
    end;
  except
    Bmp.Free;
    raise;
  end;
  UndoPush(FBitmap);
  FBitmap.Free;
  FBitmap := Bmp;
  EnsureAlphaMask;
  EnsureProtMask;
  FDirty := True;
  FFilePath := '';
  UpdateCaption;
  UpdateZoomFit;
  UpdateStatusBar;
  FRasterPreview := False;
  InvalidatePreviewCache;
  PaintBox.Invalidate;
  UpdateMenuState;
end;

procedure TfrmMain.mnuEditRevertClick(Sender: TObject);
var
  SW: TStopwatch;
  Loaded: TBitmap;
begin
  if (FFilePath = '') or (not FileExists(FFilePath)) then
  begin
    MessageDlg(T('Source file not found on disk to restore the original.'), mtWarning, [mbOK], 0);
    Exit;
  end;

  SW := TStopwatch.StartNew;

  UndoPush(FBitmap);

  Loaded := LoadImageFile(FFilePath);
  try
    FBitmap.Assign(Loaded);
  finally
    Loaded.Free;
  end;
  ApplyMaxResolution(FBitmap);
  EnsureAlphaMask;
  EnsureProtMask;

  FDirty := False;
  UpdateCaption;
  UpdateZoomFit;
  UpdateStatusBar;
  FRasterPreview := False;
  InvalidatePreviewCache;
  PaintBox.Invalidate;

  SetOperationInfo(T('Restore original'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuEditClearHistoryClick(Sender: TObject);
begin
  // Czyszczenie historii w uUndo (czyści UndoStack i RedoStack)
  UndoClear;

  // Aktualizacja dostępności elementów menu na podstawie funkcji z uUndo
  mnuEditUndo.Enabled := UndoCanUndo;
  mnuEditRedo.Enabled := UndoCanRedo;

  // Informacja na pasek statusu (panel 6)
  SetOperationInfo(T('Clear history'), 0);
end;

{ ========================================================================= }
{  Widok }
{ ========================================================================= }

procedure TfrmMain.mnuViewZoomInClick(Sender: TObject);
var
  I: Integer;
begin
  for I := Low(ZOOM_STEPS) to High(ZOOM_STEPS) do
    if ZOOM_STEPS[I] > FZoomFactor + 0.001 then
    begin
      UpdateZoom(ZOOM_STEPS[I]);
      Exit;
    end;
end;

procedure TfrmMain.mnuViewZoomOutClick(Sender: TObject);
var
  I: Integer;
begin
  for I := High(ZOOM_STEPS) downto Low(ZOOM_STEPS) do
    if ZOOM_STEPS[I] < FZoomFactor - 0.001 then
    begin
      UpdateZoom(ZOOM_STEPS[I]);
      Exit;
    end;
end;

procedure TfrmMain.mnuViewFitClick(Sender: TObject);
begin
  UpdateZoomFit;
end;

procedure TfrmMain.mnuView100Click(Sender: TObject);
begin
  UpdateZoom(1.0);
end;

procedure TfrmMain.mnuView50Click(Sender: TObject);
begin
  UpdateZoom(0.5);
end;

procedure TfrmMain.mnuView25Click(Sender: TObject);
begin
  UpdateZoom(0.25);
end;

procedure TfrmMain.mnuView200Click(Sender: TObject);
begin
  UpdateZoom(2.0);
end;

procedure TfrmMain.mnuView400Click(Sender: TObject);
begin
  UpdateZoom(4.0);
end;

{ ========================================================================= }
{  Korektor }
{ ========================================================================= }

procedure TfrmMain.DoFlipH(Bitmap: TBitmap);
var
  Y, X: Integer;
  Row: PByte;
  Tmp: array[0..2] of Byte;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  for Y := 0 to Bitmap.Height - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to (Bitmap.Width div 2) - 1 do
    begin
      Move(Row[X * 3], Tmp, 3);
      Move(Row[(Bitmap.Width - 1 - X) * 3], Row[X * 3], 3);
      Move(Tmp, Row[(Bitmap.Width - 1 - X) * 3], 3);
    end;
  end;
end;

procedure TfrmMain.DoFlipV(Bitmap: TBitmap);
var
  Y, RowSize: Integer;
  TmpRow: array of Byte;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  RowSize := Bitmap.Width * 3;
  SetLength(TmpRow, RowSize);
  for Y := 0 to (Bitmap.Height div 2) - 1 do
  begin
    Move(Bitmap.ScanLine[Y]^, TmpRow[0], RowSize);
    Move(Bitmap.ScanLine[Bitmap.Height - 1 - Y]^, Bitmap.ScanLine[Y]^, RowSize);
    Move(TmpRow[0], Bitmap.ScanLine[Bitmap.Height - 1 - Y]^, RowSize);
  end;
end;

procedure TfrmMain.DoRotateLeft(Bitmap: TBitmap);
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow: PByte;
  DstScanlines: array of PByte;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Src := TBitmap.Create;
  try
    Src.Assign(Bitmap);
    W := Src.Width;
    H := Src.Height;

    Bitmap.Width := H;
    Bitmap.Height := W;
    Bitmap.PixelFormat := pf24bit;

    SetLength(DstScanlines, W);
    for X := 0 to W - 1 do
      DstScanlines[X] := Bitmap.ScanLine[X];

    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Move(SrcRow[X * 3], DstScanlines[W - 1 - X][Y * 3], 3);
      end;
    end;
  finally
    Src.Free;
  end;
end;

procedure TfrmMain.DoRotateRight(Bitmap: TBitmap);
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow: PByte;
  DstScanlines: array of PByte;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Src := TBitmap.Create;
  try
    Src.Assign(Bitmap);
    W := Src.Width;
    H := Src.Height;

    Bitmap.Width := H;
    Bitmap.Height := W;
    Bitmap.PixelFormat := pf24bit;

    SetLength(DstScanlines, W);
    for X := 0 to W - 1 do
      DstScanlines[X] := Bitmap.ScanLine[X];

    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Move(SrcRow[X * 3], DstScanlines[X][(H - 1 - Y) * 3], 3);
      end;
    end;
  finally
    Src.Free;
  end;
end;

procedure TfrmMain.DoRotate180(Bitmap: TBitmap);
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow, DstRow: PByte;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Src := TBitmap.Create;
  try
    Src.Assign(Bitmap);
    W := Src.Width;
    H := Src.Height;
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      DstRow := Bitmap.ScanLine[H - 1 - Y];
      for X := 0 to W - 1 do
        Move(SrcRow[X * 3], DstRow[(W - 1 - X) * 3], 3);
    end;
  finally
    Src.Free;
  end;
end;

procedure TfrmMain.mnuFlipHClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  FDirty := True;
  UpdateCaption;
  DoFlipH(FBitmap);
  ProtFlipH;
  AlphaFlipH;
  FinishEffect(T('Mirror horizontally'), 0);
end;

procedure TfrmMain.mnuFlipVClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  FDirty := True;
  UpdateCaption;
  DoFlipV(FBitmap);
  ProtFlipV;
  AlphaFlipV;
  FinishEffect(T('Mirror vertically'), 0);
end;

procedure TfrmMain.mnuRotateLeftClick(Sender: TObject);
var
  SW: TStopwatch;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  FDirty := True;
  UpdateCaption;

  DoRotateLeft(FBitmap);
  ProtRotateLeft;
  AlphaRotateLeft;

  NotifyBitmapResized;
  SW.Stop;
  FinishEffect(T('Rotate left'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuRotateRightClick(Sender: TObject);
var
  SW: TStopwatch;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  FDirty := True;
  UpdateCaption;

  DoRotateRight(FBitmap);
  ProtRotateRight;
  AlphaRotateRight;

  NotifyBitmapResized;
  SW.Stop;
  FinishEffect(T('Rotate right'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuRotate180Click(Sender: TObject);
begin
  if FBitmap.Width = 0 then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  FDirty := True;
  UpdateCaption;
  DoRotate180(FBitmap);
  ProtRotate180;
  AlphaRotate180;
  FinishEffect(T('Rotate 180'), 0);
end;

procedure TfrmMain.mnuStraightenClick(Sender: TObject);
var
  Angle: Integer;
  SW: TStopwatch; // Nasz stoper
begin
  if FBitmap.Width = 0 then Exit;
  StraightenSourceBmp := FBitmap;
  if not ShowStraightenDlg(Angle) then Exit;
  if Angle = 0 then Exit;

  Screen.Cursor := crHourGlass;
  SW := TStopwatch.StartNew; // 1. Włączamy stoper
  try
    UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
    FDirty := True;
    UpdateCaption;
    RotateAndCrop(FBitmap, Angle);
    ProtRotateAngle(Angle);
    AlphaRotateAngle(Angle);
    NotifyBitmapResized;
    UpdateStatusBar; // Odświeża wymiary (1440x1920)
  finally
    SW.Stop; // 2. Zatrzymujemy stoper
    Screen.Cursor := crDefault;
  end;

  // 3. Rejestrujemy krok makra (kąt) i kończymy efekt:
  gMacroPending.Code := 'STRAIGHTEN';
  gMacroPending.Params := IntToStr(Angle);
  FinishEffect(T('Straighten'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuHistogramClick(Sender: TObject);
var
  Dlg: THistogramDlg;
begin
  if FBitmap.Width = 0 then Exit;
  HistogramSourceBmp := FBitmap;
  Dlg := THistogramDlg.Create(Application);
  Dlg.OnEqualize := DoEqualize;
  Dlg.CalcHistogram;
  Dlg.SetChannel('all');
  Dlg.ShowModal;
  Dlg.Free;
end;

procedure TfrmMain.DoEqualize(const Mode: string);
var
  SW: TStopwatch;
  Backup: TBitmap;
begin
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  EqualizeHistogram(FBitmap, Mode);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'EQUALIZE';
  gMacroPending.Params := Mode;
  FinishEffect(T('Histogram equalization'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.SelectionRepaint(Sender: TObject);
begin
  if (FSelection.W > 0) and (FSelection.H > 0) then
    InvalidatePaintRect(SelectionScreenRect);
end;

function TfrmMain.SelectionScreenRect: TRect;
var
  L, T, R, B: Integer;
begin
  L := Round(Min(FSelection.X1, FSelection.X2) * FZoomFactor);
  T := Round(Min(FSelection.Y1, FSelection.Y2) * FZoomFactor);
  R := Round(Max(FSelection.X1, FSelection.X2) * FZoomFactor);
  B := Round(Max(FSelection.Y1, FSelection.Y2) * FZoomFactor);
  Result := Rect(L, T, R, B);
  System.Types.InflateRect(Result, 6, 6); // margines na uchwyty (8px) i kreski
end;

procedure TfrmMain.RestoreOutsideSelection(Backup: TBitmap);
var
  R: TRect;
  Y, X: Integer;
  DstRow, SrcRow: PRGBTripleArray;
  MP: PByte;
  SelValid, Coverage, ShapeSel: Boolean;
begin
  if (Backup = nil) or (Backup.Width <> FBitmap.Width) or (Backup.Height <> FBitmap.Height) then
    Exit;
  SelValid := FSelection.IsValid;
  Coverage := (FProtCoverCount > 0) and (FProtMask <> nil) and
    (FProtMask.Width = FBitmap.Width) and (FProtMask.Height = FBitmap.Height);
  ShapeSel := SelValid and (FSelection.Shape <> hsRect);
  if SelValid then
    R := FSelection.ClampedRect(FBitmap.Width, FBitmap.Height)
  else
    R := Rect(0, 0, -1, -1);
  for Y := 0 to FBitmap.Height - 1 do
  begin
    DstRow := FBitmap.ScanLine[Y];
    SrcRow := Backup.ScanLine[Y];
    if SelValid and (Y >= R.Top) and (Y <= R.Bottom) then
    begin
      // left side
      if R.Left > 0 then
        Move(SrcRow[0], DstRow[0], R.Left * 3);
      // right side
      X := R.Right + 1;
      if X < FBitmap.Width then
        Move(SrcRow[X], DstRow[X], (FBitmap.Width - X) * 3);
      // eliptyczne/lasso/różdżka: piksele wewnątrz bboxa, ale poza kształtem,
      // przywracane z Backup (efekt działa tylko w obrębie kształtu)
      if ShapeSel then
        for X := R.Left to R.Right do
          if not FSelection.Contains(X + 0.5, Y + 0.5) then
            DstRow[X] := SrcRow[X];
    end
    else if SelValid then
      Move(SrcRow[0], DstRow[0], FBitmap.Width * 3);
    // maska ochronna: piksele zakryte (255) przywracane z Backup niezależnie od selekcji
    if Coverage then
    begin
      MP := FProtMask.ScanLine[Y];
      for X := 0 to FBitmap.Width - 1 do
        if MP[X] <> 0 then
          DstRow[X] := SrcRow[X];
    end;
  end;
end;

function TfrmMain.NeedEffectBackup: Boolean;
begin
  Result := FSelection.IsValid or (FProtCoverCount > 0);
end;

procedure TfrmMain.mnuContrastClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowContrastDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Contrast'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuBrightnessClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowBrightnessDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Brightness'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuGammaClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowGammaDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Gamma correction'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuLevelsClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowLevelsDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Levels'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuWBClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowWBDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('White balance'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuHSBClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowHSBDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('HSB balance'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuSharpenClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowSharpenDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Sharpen'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuHDR1Click(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowHDR1Dlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Vividness'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuHDR2Click(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowWzmocnienieDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Photo enhancement'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuEmergoClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowEmergoDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Emergo'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuSelSizeClick(Sender: TObject);
var
  W, H: Integer;
begin
  if FBitmap.Width = 0 then Exit;
  if FSelection.Active then
  begin
    W := Round(FSelection.W);
    H := Round(FSelection.H);
  end
  else
  begin
    W := FBitmap.Width div 2;
    H := FBitmap.Height div 2;
  end;
  if ShowSelSizeDlg(W, H) then
  begin
    if (W > 0) and (H > 0) then
    begin
      if FSelection.Active then
        FSelection.SetSizeKeepTopLeft(W, H, FBitmap.Width, FBitmap.Height)
      else
        FSelection.SetSizeCentered(W, H, FBitmap.Width, FBitmap.Height);
      UpdateStatusBar;
      PaintBox.Invalidate;
    end;
  end;
end;

procedure TfrmMain.mnuCropToSelClick(Sender: TObject);
var
  Cropped: TBitmap;
  R: TRect;
begin
  if (FBitmap.Width = 0) or (not FSelection.IsValid) then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  Cropped := SelectionCrop(FBitmap, FSelection);
  if Cropped <> nil then
  begin
    R := FSelection.ClampedRect(FBitmap.Width, FBitmap.Height);
    ProtCrop(R);
    AlphaCrop(R);
    FSelection.Clear;
    FBitmap.Assign(Cropped);
    Cropped.Free;
    NotifyBitmapResized;
    UpdateStatusBar;
    FinishEffect(T('Crop'), 0);
  end;
end;

procedure TfrmMain.SetSelectionShape(AShape: THitShape);
begin
  FSelection.Shape := AShape;
  if FActiveToolKind <> tkSelection then
    ActivateTool(tkSelection);
  if FSelection.Active and FSelection.IsValid then
    InvalidatePaintRect(SelectionScreenRect);
  if (FToolsDlg <> nil) and FToolsDlg.Visible then
    FToolsDlg.RefreshToleranceVisibility;
end;

procedure TfrmMain.DoSetSelectionShape(AShape: THitShape);
begin
  SetSelectionShape(AShape);
end;

procedure TfrmMain.RecomputeWandFromSeed;
begin
  // Ponowne zalewanie od zapamiętanego punktu (bez nowego kliknięcia) po
  // zmianie tolerancji. Parametr tolerancji: 0..100 -> 0..255 (jak różdżka).
  if FBitmap = nil then Exit;
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then Exit;
  if FSelection.Shape <> hsWand then Exit;
  if not FSelection.HasValidSeed then Exit;
  if FSelection.Active then
    InvalidatePaintRect(SelectionScreenRect);
  FSelection.RecomputeFromSeed(FBitmap, FRetouchTolerance * 51 div 20);
  if FSelection.Active then
  begin
    InvalidatePaintRect(SelectionScreenRect);
    UpdateStatusBar;
  end;
end;

procedure TfrmMain.WandDebounceTimerProc(Sender: TObject);
begin
  if FWandDebounceTimer <> nil then
    FWandDebounceTimer.Enabled := False;
  RecomputeWandFromSeed;
end;

function TfrmMain.GetSelectionView: TSelectionView;
begin
  Result := FSelectionView;
end;

procedure TfrmMain.SetSelectionView(AView: TSelectionView);
begin
  FSelectionView := AView;
  FSelection.View := AView;   // silnik rysuje wg TSelection.FView
  if FSelection.Active then
    InvalidatePaintRect(SelectionScreenRect);
end;

procedure TfrmMain.DebouncedWandFromSeed(ADelayMs: Integer);
begin
  if FWandDebounceTimer = nil then
  begin
    FWandDebounceTimer := TTimer.Create(Self);
    FWandDebounceTimer.OnTimer := WandDebounceTimerProc;
  end;
  FWandDebounceTimer.Enabled := False;
  FWandDebounceTimer.Interval := ADelayMs;
  FWandDebounceTimer.Enabled := True;
end;

procedure TfrmMain.mnuResizeClick(Sender: TObject);
var
  NewW, NewH: Integer;
begin
  if FBitmap.Width = 0 then Exit;
  ResizeSourceBmp := FBitmap;
  if ShowResizeDlg(NewW, NewH) then
  begin
    UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
    ImageResize(FBitmap, NewW, NewH);
    ProtResize(NewW, NewH);
    AlphaResize(NewW, NewH);
    FSelection.Clear;
    NotifyBitmapResized; FinishEffect(T('Resize'), 0);
  end;
  ResizeSourceBmp := nil;
end;

procedure TfrmMain.mnuResizeCropClick(Sender: TObject);
var
  NewW, NewH, Corner: Integer;
begin
  if FBitmap.Width = 0 then Exit;
  ResizeCropSourceBmp := FBitmap;
  if ShowResizeCropDlg(NewW, NewH, Corner) then
  begin
    UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
    ImageResizeCrop(FBitmap, NewW, NewH, Corner);
    ProtResizeCrop(NewW, NewH, Corner);
    AlphaResizeCrop(NewW, NewH, Corner);
    FSelection.Clear;
    NotifyBitmapResized; FinishEffect(T('Fit to size with cropping'), 0);
  end;
  ResizeCropSourceBmp := nil;
end;

procedure TfrmMain.mnuTilesClick(Sender: TObject);
var
  NewW, NewH: Integer;
begin
  if FBitmap.Width = 0 then Exit;
  TileSourceBmp := FBitmap;
  if ShowTileDlg(NewW, NewH) then
  begin
    UndoPush(FBitmap);
    ImageTile(FBitmap, NewW, NewH);
    FSelection.Clear;
    UpdateZoomFit; FinishEffect(T('Tiling'), 0);
  end;
  TileSourceBmp := nil;
end;

{ ========================================================================= }
{  Efekty }
{ ========================================================================= }

procedure TfrmMain.mnuTintClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowKolorowanieDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Colorize'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuDuotoneClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDuotoneDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Duotone'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuTritoneClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowTritoneDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Tritone'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuQuadtoneClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowQuadToneDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Quad-tone'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuSepiaClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowSepiaDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Sepia'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.DoFalseIR(Bitmap: TBitmap);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  t: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      t := Row[X].R;
      Row[X].R := Row[X].G;
      Row[X].G := t;
    end;
  end;
end;

procedure TfrmMain.DoNightVision(Bitmap: TBitmap);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  gray, ph: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      gray := Trunc((Row[X].R * 299 + Row[X].G * 587 + Row[X].B * 114) / 1000);
      ph := Trunc(gray * 0.15);
      Row[X].R := Byte(ph);
      Row[X].G := Byte(gray);
      Row[X].B := Byte(ph);
    end;
  end;
end;

procedure TfrmMain.DoThermal(Bitmap: TBitmap);
var
  W, H, X, Y, V: Integer;
  Row: PRGBTripleArray;
  g: Byte;
  LutR, LutG, LutB: array[0..255] of Byte;
begin
  for V := 0 to 255 do
  begin
    if V < 64 then
    begin
      LutR[V] := 0;
      LutG[V] := 0;
      LutB[V] := V * 4;
    end
    else if V < 128 then
    begin
      LutR[V] := (V - 64) * 4;
      LutG[V] := 0;
      LutB[V] := 255 - (V - 64) * 4;
    end
    else if V < 192 then
    begin
      LutR[V] := 255;
      LutG[V] := (V - 128) * 4;
      LutB[V] := 0;
    end
    else
    begin
      LutR[V] := 255;
      LutG[V] := 255;
      LutB[V] := (V - 192) * 4;
    end;
  end;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      g := Round(Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114);
      Row[X].R := LutR[g];
      Row[X].G := LutG[g];
      Row[X].B := LutB[g];
    end;
  end;
end;

procedure TfrmMain.DoOrton(Bitmap: TBitmap);
var
  W, H, X, Y, Radius: Integer;
  Row, BlurRow: PRGBTripleArray;
  Blurred: TBitmap;
  BlurLines: array of PRGBTripleArray;
  rd, rs, rout: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Radius := Max(1, Min(W, H) div 20);
  Blurred := TBitmap.Create;
  try
    BoxBlur(Bitmap, Blurred, Radius);

    SetLength(BlurLines, H);
    for Y := 0 to H - 1 do
      BlurLines[Y] := Blurred.ScanLine[Y];

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      BlurRow := BlurLines[Y];
      for X := 0 to W - 1 do
      begin
        rd := Row[X].R / 255.0;
        rs := BlurRow[X].R / 255.0;
        rout := (rd + rs - rd * rs) * 0.5 + rd * 0.5;
        Row[X].R := Byte(Min(255, Max(0, Trunc(rout * 255))));

        rd := Row[X].G / 255.0;
        rs := BlurRow[X].G / 255.0;
        rout := (rd + rs - rd * rs) * 0.5 + rd * 0.5;
        Row[X].G := Byte(Min(255, Max(0, Trunc(rout * 255))));

        rd := Row[X].B / 255.0;
        rs := BlurRow[X].B / 255.0;
        rout := (rd + rs - rd * rs) * 0.5 + rd * 0.5;
        Row[X].B := Byte(Min(255, Max(0, Trunc(rout * 255))));
      end;
    end;
  finally
    Blurred.Free;
  end;
end;

procedure TfrmMain.DoXray(Bitmap: TBitmap);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := 255 - Row[X].R;
      Row[X].G := 255 - Row[X].G;
      Row[X].B := 255 - Row[X].B;
    end;
  end;
  DoDuotone(Bitmap, RGB(0, 5, 20), RGB(180, 215, 255));
end;

procedure TfrmMain.mnuCyanotypeClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoDuotone(FBitmap, RGB(0, 20, 60), RGB(200, 225, 255));
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('Cyanotype'), 0);
end;

procedure TfrmMain.mnuSaltprintClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoDuotone(FBitmap, RGB(61, 26, 0), RGB(255, 245, 224));
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('Salt print'), 0);
end;

procedure TfrmMain.mnuXrayClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoXray(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('X-Ray'), 0);
end;

procedure TfrmMain.mnuFalseIRClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoFalseIR(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('False-color IR'), 0);
end;

procedure TfrmMain.mnuNightVisionClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoNightVision(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('Night vision'), 0);
end;

procedure TfrmMain.mnuThermalClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoThermal(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('Thermal'), 0);
end;

procedure TfrmMain.mnuOrtonClick(Sender: TObject);
var
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  DoOrton(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('Orton'), 0);
end;

procedure TfrmMain.mnuBWClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowBWDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Black & white'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuGrayClick(Sender: TObject);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  g: Byte;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  W := FBitmap.Width;
  H := FBitmap.Height;
  for Y := 0 to H - 1 do
  begin
    Row := FBitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      g := Round(Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114);
      Row[X].R := g;
      Row[X].G := g;
      Row[X].B := g;
    end;
  end;
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'GRAY';
  gMacroPending.Params := '';
  FinishEffect(T('Grayscale'), 0);
end;

procedure TfrmMain.mnuInvertClick(Sender: TObject);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  W := FBitmap.Width;
  H := FBitmap.Height;
  for Y := 0 to H - 1 do
  begin
    Row := FBitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := 255 - Row[X].R;
      Row[X].G := 255 - Row[X].G;
      Row[X].B := 255 - Row[X].B;
    end;
  end;
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'INVERT';
  gMacroPending.Params := '';
  FinishEffect(T('Negative'), 0);
end;

procedure TfrmMain.mnuSolarizeClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowSolarizeDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Solarize'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuFilmGrainClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowFilmGrainDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Film grain'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuOleoClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowOleoDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Oil painting'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuCharcoalClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowCharcoalDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Charcoal'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuObrysClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowObrysDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Outline'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuBlurClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowBlurDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Blur'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuEmbossClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowEmbossDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Emboss'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuReliefClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowReliefDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Bas-relief'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuPixelateClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowPixelateDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Pixelation'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuStereogramClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowStereogramDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Stereogram'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuVignetteClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowVignetteDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Vignette'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuBokehClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowBokehDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Artificial bokeh'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuMakietaClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowMakietaDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Mockup'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuQuantizeClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowQuantizeDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Posterize'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuEdgeClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowEdgeDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Edge detection'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuGlowClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowGlowDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Glow'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuCrossProcessClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowCrossProcessDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Cross process'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuGlitchClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowGlitchDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Glitch'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuBlendClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowBlendDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Effect blending'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

{ ========================================================================= }
{  Druk }
{ ========================================================================= }

procedure TfrmMain.mnuCMYKClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowCmykDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('CMYK error'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuLinocutClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowLinocutDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Linocut'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuStencilClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowStencilDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Mimeograph'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuEngravingClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowEngravingDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Engraving'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuCrosshatchClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowCrosshatchDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Crosshatch'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuHalftoneClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowHalftoneDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Halftone'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuStippleClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowStippleDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Stipple'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuDiceClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDiceDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Dice'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuScreenPrintClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowScreenPrintDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Screen print'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuRastrCMYKClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowRastrCmykDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Raster CMYK...'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuRisoClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowRisoDlg(FBitmap, rvV1, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Risograph'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuRisoV2Click(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowRisoDlg(FBitmap, rvV2, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Risograph v2'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuRisoV3Click(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowRisoV3Dlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Risograph v3'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuTshirtClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowTshirtDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Creating overprint'), Elapsed);
    // PO FinishEffect (on czyści flagę) — zachować kolejność, patrz FinishEffect.
    FRasterPreview := True;
  end
  else if Backup <> nil then Backup.Free;
end;

{ ========================================================================= }
{  Makro }
{ ========================================================================= }

procedure TfrmMain.UpdateMacroMenu;
begin
  mnuMacroStart.Enabled := not MacroRecorder.IsActive;
  mnuMacroStop.Enabled := MacroRecorder.IsActive;
  mnuMacroCancel.Enabled := MacroRecorder.IsActive;
end;

procedure TfrmMain.mnuMacroStartClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then
  begin
    MessageDlg(T('Open an image first.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  MacroRecorder.Start;
  gMacroPending.Code := '';
  UpdateMacroMenu;
  UpdateCaption;
  if StatusBar.Panels.Count > 0 then StatusBar.Panels[0].Text := T('Recording macro') + '...';
end;

procedure TfrmMain.mnuMacroStopClick(Sender: TObject);
var
  M: TMacro;
  Name: string;
begin
  if not MacroRecorder.IsActive then Exit;
  MacroRecorder.Stop(M);
  UpdateMacroMenu;
  UpdateCaption;
  if StatusBar.Panels.Count > 0 then StatusBar.Panels[0].Text := '';
  if Length(M.Steps) = 0 then
  begin
    MessageDlg(T('Macro is empty - not saved.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  Name := '';
  if not InputQuery(T('Macro name'), T('Enter macro name:'), Name) then
  begin
    MessageDlg(T('Cancelled - macro was not saved.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  if Trim(Name) = '' then Name := T('Macro') + ' ' + IntToStr(MacrosCount + 1);
  M.Name := Trim(Name);
  MacrosAdd(M);
  MacrosSaveToFile;
end;

procedure TfrmMain.mnuMacroCancelClick(Sender: TObject);
begin
  if not MacroRecorder.IsActive then Exit;
  MacroRecorder.Cancel;
  gMacroPending.Code := '';
  UpdateMacroMenu;
  UpdateCaption;
  if StatusBar.Panels.Count > 0 then StatusBar.Panels[0].Text := '';
end;

procedure TfrmMain.mnuBatchClick(Sender: TObject);
var
  Opts: TBatchOptions;
begin
  if MacrosCount = 0 then
  begin
    MessageDlg(T('No saved macros.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  if ShowBatchDlg(Opts) then
    BatchProcess(Opts);
end;

procedure TfrmMain.mnuTimelapseClick(Sender: TObject);
var
  Opts: TTimelapseOptions;
begin
  if ShowTimelapseDlg(Opts) then
    RunTimelapse(Opts);
end;

procedure TfrmMain.BatchProcess(const Opts: TBatchOptions);
var
  SR: TSearchRec;
  Files: TArray<string>;
  i, j, OkCount, ErrCount, NW, NH: Integer;
  Bmp: TBitmap;
  SrcPath, DstPath, Msg: string;
  M: TMacro;
  Prog: TForm;
  Lbl: TLabel;
  BtnAbort: TButton;
begin
  FBatchAbort := False;
  OkCount := 0;
  ErrCount := 0;
  SetLength(Files, 0);

  if FindFirst(IncludeTrailingPathDelimiter(Opts.SrcDir) + '*.*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then
          if SaveExtSupported(SR.Name) then
          begin
            SetLength(Files, Length(Files) + 1);
            Files[High(Files)] := SR.Name;
          end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  if Length(Files) = 0 then
  begin
    MessageDlg(T('No images in the source folder.'), mtInformation, [mbOK], 0);
    Exit;
  end;

  M := MacrosGet(Opts.MacroIndex);

  Prog := TForm.CreateNew(Self);
  try
    Prog.Caption := T('Batch processing');
    Prog.Position := poScreenCenter;
    Prog.BorderStyle := bsDialog;
    Prog.ClientWidth := 340;
    Prog.ClientHeight := 90;

    Lbl := TLabel.Create(Prog);
    Lbl.Parent := Prog;
    Lbl.Left := 12;
    Lbl.Top := 12;
    Lbl.Width := 316;
    Lbl.Height := 15;
    Lbl.Caption := T('Processing...') + ' 0/' + IntToStr(Length(Files));

    BtnAbort := TButton.Create(Prog);
    BtnAbort.Parent := Prog;
    BtnAbort.Caption := T('Cancel');
    BtnAbort.Left := 243;
    BtnAbort.Top := 50;
    BtnAbort.Width := 85;
    BtnAbort.Height := 25;
    BtnAbort.OnClick := BatchAbortClick;

    Prog.Show;
    Application.ProcessMessages;

    for i := 0 to High(Files) do
    begin
      if FBatchAbort then Break;

      Lbl.Caption := Files[i] + ' (' + IntToStr(i + 1) + '/' + IntToStr(Length(Files)) + ')';
      Application.ProcessMessages;
      if FBatchAbort then Break;

      SrcPath := IncludeTrailingPathDelimiter(Opts.SrcDir) + Files[i];
      DstPath := IncludeTrailingPathDelimiter(Opts.DstDir) + Files[i];

      try
        Bmp := LoadImageFile(SrcPath);
      except
        Inc(ErrCount);
        Continue;
      end;

      try
        try
          if not Opts.NoMacro then
            for j := 0 to High(M.Steps) do
            begin
              if Opts.Scale and
                (SameText(M.Steps[j].Code, 'RESIZE') or SameText(M.Steps[j].Code, 'RESIZECROP')) then
                Continue;
              ApplyMacroStep(M.Steps[j], Bmp);
            end;

          if Opts.Scale and (Opts.TargetEdge > 0) and
            (Max(Bmp.Width, Bmp.Height) <> Opts.TargetEdge) then
          begin
            NW := Max(1, Trunc(Bmp.Width * (Opts.TargetEdge / Max(Bmp.Width, Bmp.Height))));
            NH := Max(1, Trunc(Bmp.Height * (Opts.TargetEdge / Max(Bmp.Width, Bmp.Height))));
            ImageResize(Bmp, NW, NH);
          end;

          SaveImageFile(Bmp, DstPath);
          Inc(OkCount);
        finally
          Bmp.Free;
        end;
      except
        Inc(ErrCount);
      end;
    end;

    Prog.Close;
  finally
    Prog.Free;
  end;

  Msg := T('Processed') + ': ' + IntToStr(OkCount) + '/' + IntToStr(Length(Files));
  if ErrCount > 0 then
    Msg := Msg + sLineBreak + T('errors') + ': ' + IntToStr(ErrCount);
  if FBatchAbort then
    Msg := T('Cancel') + sLineBreak + Msg;
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

procedure TfrmMain.BatchAbortClick(Sender: TObject);
begin
  FBatchAbort := True;
end;

procedure TfrmMain.mnuMacroManageClick(Sender: TObject);
var
  btnPlay, btnRename, btnDelete, btnDeleteStep, btnClose: TButton;
  i: Integer;
begin
  FMacroMgrForm := TForm.CreateNew(Self);
  try
    FMacroMgrForm.Caption := T('Manage macros');
    FMacroMgrForm.Position := poScreenCenter;
    FMacroMgrForm.Width := 480;
    FMacroMgrForm.Height := 340;
    FMacroMgrForm.BorderStyle := bsDialog;

    FMacroMgrList := TListBox.Create(FMacroMgrForm);
    FMacroMgrList.Parent := FMacroMgrForm;
    FMacroMgrList.Left := 12;
    FMacroMgrList.Top := 12;
    FMacroMgrList.Width := 336;
    FMacroMgrList.Height := 170;
    FMacroMgrList.OnClick := MacroMgrSelectClick;
    for i := 0 to MacrosCount - 1 do
      FMacroMgrList.Items.Add(MacrosGet(i).Name);

    FMacroMgrSteps := TListBox.Create(FMacroMgrForm);
    FMacroMgrSteps.Parent := FMacroMgrForm;
    FMacroMgrSteps.Left := 12;
    FMacroMgrSteps.Top := 190;
    FMacroMgrSteps.Width := 336;
    FMacroMgrSteps.Height := 72;

    btnPlay := TButton.Create(FMacroMgrForm);
    btnPlay.Parent := FMacroMgrForm;
    btnPlay.Caption := T('Play');
    btnPlay.Left := 360;
    btnPlay.Top := 12;
    btnPlay.Width := 85;
    btnPlay.Height := 25;
    btnPlay.OnClick := MacroMgrPlayClick;

    btnRename := TButton.Create(FMacroMgrForm);
    btnRename.Parent := FMacroMgrForm;
    btnRename.Caption := T('Rename');
    btnRename.Left := 360;
    btnRename.Top := 45;
    btnRename.Width := 85;
    btnRename.Height := 25;
    btnRename.OnClick := MacroMgrRenameClick;

    btnDelete := TButton.Create(FMacroMgrForm);
    btnDelete.Parent := FMacroMgrForm;
    btnDelete.Caption := T('Delete');
    btnDelete.Left := 360;
    btnDelete.Top := 78;
    btnDelete.Width := 85;
    btnDelete.Height := 25;
    btnDelete.OnClick := MacroMgrDeleteClick;

    btnDeleteStep := TButton.Create(FMacroMgrForm);
    btnDeleteStep.Parent := FMacroMgrForm;
    btnDeleteStep.Caption := T('Remove step');
    btnDeleteStep.Left := 360;
    btnDeleteStep.Top := 111;
    btnDeleteStep.Width := 85;
    btnDeleteStep.Height := 25;
    btnDeleteStep.OnClick := MacroMgrDeleteStepClick;

    btnClose := TButton.Create(FMacroMgrForm);
    btnClose.Parent := FMacroMgrForm;
    btnClose.Caption := T('Close');
    btnClose.Left := 360;
    btnClose.Top := 270;
    btnClose.Width := 85;
    btnClose.Height := 25;
    btnClose.ModalResult := mrOk;

    FMacroMgrForm.ShowModal;
  finally
    FMacroMgrForm.Free;
    FMacroMgrForm := nil;
    FMacroMgrList := nil;
    FMacroMgrSteps := nil;
  end;
end;

procedure TfrmMain.MacroMgrPlayClick(Sender: TObject);
begin
  if FMacroMgrList.ItemIndex < 0 then Exit;
  FMacroMgrForm.ModalResult := mrOk;
  RunMacro(MacrosGet(FMacroMgrList.ItemIndex));
end;

procedure TfrmMain.MacroMgrRenameClick(Sender: TObject);
var
  NewName: string;
begin
  if FMacroMgrList.ItemIndex < 0 then Exit;
  NewName := FMacroMgrList.Items[FMacroMgrList.ItemIndex];
  if InputQuery(T('Rename'), T('New macro name:'), NewName) then
  begin
    if Trim(NewName) = '' then NewName := FMacroMgrList.Items[FMacroMgrList.ItemIndex];
    NewName := Trim(NewName);
    MacrosRename(FMacroMgrList.ItemIndex, NewName);
    MacrosSaveToFile;
    FMacroMgrList.Items[FMacroMgrList.ItemIndex] := NewName;
  end;
end;

procedure TfrmMain.MacroMgrDeleteClick(Sender: TObject);
begin
  if FMacroMgrList.ItemIndex < 0 then Exit;
  if MessageDlg(Format(T('Delete macro "%s"?'), [FMacroMgrList.Items[FMacroMgrList.ItemIndex]]),
    mtConfirmation, mbOKCancel, 0) = mrOk then
  begin
    MacrosDelete(FMacroMgrList.ItemIndex);
    MacrosSaveToFile;
    FMacroMgrList.Items.Delete(FMacroMgrList.ItemIndex);
    MacroMgrSelectClick(nil);
  end;
end;

procedure TfrmMain.MacroMgrSelectClick(Sender: TObject);
var
  M: TMacro;
  i: Integer;
begin
  FMacroMgrSteps.Items.Clear;
  if FMacroMgrList.ItemIndex < 0 then Exit;
  M := MacrosGet(FMacroMgrList.ItemIndex);
  for i := 0 to High(M.Steps) do
    FMacroMgrSteps.Items.Add(MacroStepDescription(M.Steps[i]));
end;

procedure TfrmMain.MacroMgrDeleteStepClick(Sender: TObject);
var
  Mi, Si: Integer;
begin
  Mi := FMacroMgrList.ItemIndex;
  Si := FMacroMgrSteps.ItemIndex;
  if (Mi < 0) or (Si < 0) then Exit;
  if MessageDlg(Format(T('Delete step "%s"?'), [FMacroMgrSteps.Items[Si]]),
    mtConfirmation, mbOKCancel, 0) = mrOk then
  begin
    MacroDeleteStep(Mi, Si);
    MacrosSaveToFile;
    FMacroMgrSteps.Items.Delete(Si);
  end;
end;

procedure TfrmMain.RunMacro(const M: TMacro);
var
  i: Integer;
  W0, H0: Integer;
begin
  if FBitmap.Width = 0 then
  begin
    MessageDlg(T('No image to process.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  if Length(M.Steps) = 0 then Exit;
  W0 := FBitmap.Width;
  H0 := FBitmap.Height;
  { UndoPushMasked, nie UndoPush: kroki makra potrafia przeksztalcic maski
    (ROTL/ROTR/ROT180/STRAIGHTEN). Przy zwyklym UndoPush maski nie trafiaja
    na stos, a cofniecie przywraca tylko bitmape i zostawia maske w nowym
    rozmiarze - stan gorszy niz brak maski. UUndoPushMasked przyjmuje nil dla
    obu masek (uUndo.pas:79-91), wiec kroki ktore ich nie dotykaja nie placi
    za to zadnym kosztem. }
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  for i := 0 to High(M.Steps) do
    RunMacroStep(M.Steps[i]);
  if (FBitmap.Width <> W0) or (FBitmap.Height <> H0) then
    NotifyBitmapResized;
end;

procedure TfrmMain.RunMacroStep(const Step: TMacroStep);
var
  Lbl: string;
begin
  if FBitmap.Width = 0 then Exit;
  Lbl := ApplyMacroStep(Step, FBitmap);
  if Lbl = '' then
  begin
    FinishEffect(T('Unsupported step: ') + Step.Code, 0);
    Exit;
  end;
  FinishEffect(Lbl, 0);
end;

function TfrmMain.ApplyMacroStep(const Step: TMacroStep; Bitmap: TBitmap): string;
var
  P: TArray<string>;
begin
  if Bitmap.Width = 0 then Exit('');
  P := Step.Params.Split(['|']);
  if SameText(Step.Code, 'BLUR') then DoBlur(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'BRIGHTNESS') then DoBrightness(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'GAMMA') then DoGamma(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'LEVELS') then DoLevels(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0))
  else if SameText(Step.Code, 'SEPIA') then DoSepia(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'SOLARIZE') then DoSolarize(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'CONTRAST') then DoContrast(Bitmap, StrToBoolDef(P[0], True), StrToIntDef(P[1], 0))
  else if SameText(Step.Code, 'SHARPEN') then DoSharpen(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'EMBOSS') then DoEmboss(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'PIXELATE') then DoPixelate(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'VIGNETTE') then DoVignette(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'EDGE') then DoEdge(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'FILMGRAIN') then DoFilmGrain(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'RELIEF') then DoRelief(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0))
  else if SameText(Step.Code, 'GLOW') then DoGlow(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'OILPAINT') then DoOilPaint(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'CROSSPROCESS') then DoCrossProcess(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'BW') then DoBlackWhite(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToBoolDef(P[2], False))
  else if SameText(Step.Code, 'GRAY') then DoGray(Bitmap)
  else if SameText(Step.Code, 'INVERT') then DoInvert(Bitmap)
  else if SameText(Step.Code, 'FALSEIR') then DoFalseIR(Bitmap)
  else if SameText(Step.Code, 'NIGHTVISION') then DoNightVision(Bitmap)
  else if SameText(Step.Code, 'THERMAL') then DoThermal(Bitmap)
  else if SameText(Step.Code, 'ORTON') then DoOrton(Bitmap)
  else if SameText(Step.Code, 'XRAY') then DoXray(Bitmap)
  else if SameText(Step.Code, 'CYANOTYPE') then DoDuotone(Bitmap, RGB(0, 20, 60), RGB(200, 225, 255))
  else if SameText(Step.Code, 'SALTPRINT') then DoDuotone(Bitmap, RGB(61, 26, 0), RGB(255, 245, 224))
  else if SameText(Step.Code, 'EQUALIZE') then
  begin
    if P[0] = '' then EqualizeHistogram(Bitmap, 'rgb')
    else EqualizeHistogram(Bitmap, P[0]);
  end
  else if SameText(Step.Code, 'WB1') then ApplyWorkbench1(Bitmap)
  else if SameText(Step.Code, 'WB2') then ApplyWorkbench2(Bitmap)
  else if SameText(Step.Code, 'OCS32') then ApplyOCS32(Bitmap, StrToBoolDef(P[0], False))
  else if SameText(Step.Code, 'EHB64') then ApplyEHB(Bitmap, StrToBoolDef(P[0], False))
  else if SameText(Step.Code, 'AGA256') then ApplyAGA256(Bitmap, StrToBoolDef(P[0], False))
  else if SameText(Step.Code, 'WB256') then ApplyWB256(Bitmap, StrToBoolDef(P[0], False))
  else if SameText(Step.Code, 'MAGICWB') then ApplyMagicWB(Bitmap, StrToBoolDef(P[0], False))
  else if SameText(Step.Code, 'HAM6') then ApplyHAM(Bitmap, 4)
  else if SameText(Step.Code, 'HAM8') then ApplyHAM(Bitmap, 6)
  else if SameText(Step.Code, 'FLIPH') then
  begin
    DoFlipH(Bitmap);
    ProtFlipH;
    AlphaFlipH;
  end
  else if SameText(Step.Code, 'FLIPV') then
  begin
    DoFlipV(Bitmap);
    ProtFlipV;
    AlphaFlipV;
  end
  else if SameText(Step.Code, 'ROTL') then
  begin
    DoRotateLeft(Bitmap);
    ProtRotateLeft;
    AlphaRotateLeft;
  end
  else if SameText(Step.Code, 'ROTR') then
  begin
    DoRotateRight(Bitmap);
    ProtRotateRight;
    AlphaRotateRight;
  end
  else if SameText(Step.Code, 'ROT180') then
  begin
    DoRotate180(Bitmap);
    ProtRotate180;
    AlphaRotate180;
  end
  else if SameText(Step.Code, 'STRAIGHTEN') then
  begin
    { Geometria idzie w trzech warstwach: obraz, maska ochronna, maska alfa.
      Wszystkie trzy musza dostac identyczne przeksztalcenie, bo render
      porownuje ich rozmiary i przy niezgodnosci cicho konczy rysowanie. }
    RotateAndCrop(Bitmap, StrToIntDef(P[0], 0));
    ProtRotateAngle(StrToIntDef(P[0], 0));
    AlphaRotateAngle(StrToIntDef(P[0], 0));
  end
  else if SameText(Step.Code, 'STEREOGRAM') then DoStereogram(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0), StrToIntDef(P[3], 0))
  else if SameText(Step.Code, 'CHARCOAL') then DoCharcoal(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'QUANTIZE') then DoQuantize(Bitmap, StrToIntDef(P[0], 0), StrToBoolDef(P[1], False))
  else if SameText(Step.Code, 'BOKEH') then DoBokeh(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0), StrToIntDef(P[3], 0), StrToIntDef(P[4], 0))
  else if SameText(Step.Code, 'ENGRAVING') then DoEngraving(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0))
  else if SameText(Step.Code, 'CROSSHATCH') then DoCrosshatch(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0))
  else if SameText(Step.Code, 'HALFTONE') then DoHalftone(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'STIPPLE') then DoStipple(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'DICE') then DoDice(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'RASTRCMYK') then DoRastrCmyk(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0))
  else if SameText(Step.Code, 'COLORIZE') then DoTint(Bitmap, TColor(StrToIntDef(P[0], 0)), StrToIntDef(P[1], 0))
  else if SameText(Step.Code, 'SCREENPRINT') then DoScreenPrint(Bitmap, TColor(StrToIntDef(P[0], 0)), TColor(StrToIntDef(P[1], 0)), StrToIntDef(P[2], 0))
  else if SameText(Step.Code, 'MAKIETA') then DoMakieta(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0), StrToIntDef(P[3], 0))
  else if SameText(Step.Code, 'LINOCUT') then DoLinocut(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'AGONY') then ApplyAmigaGradientAgony(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), StrToIntDef(P[2], 0))
  else if SameText(Step.Code, 'AMIGAGRADIENT') then ApplyAmigaGradient(Bitmap, StrToIntDef(P[0], 0))
  else if SameText(Step.Code, 'AMIGABG') then ApplyAmigaBackground(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0), TColor(StrToIntDef(P[2], 0)))
  else if SameText(Step.Code, 'AMIGABGS') then ApplyAmigaBackgroundStretch(Bitmap, StrToIntDef(P[0], 0), StrToIntDef(P[1], 0))
  else
    Exit('');
  Result := MacroStepLabel(Step.Code);
end;

{ ========================================================================= }
{  Zniekształcenia }
{ ========================================================================= }

procedure TfrmMain.mnuBarrelClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDistortDlg(T('Barrel distortion'), [T('Weak barrel'), T('Medium barrel'), T('Strong barrel'), T('Weak pincushion'), T('Medium pincushion'), T('Strong pincushion')], ApplyBarrel, FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Barrel distortion'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuArcClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDistortDlg(T('Arc distortion'), [T('45°'), T('90°'), T('180°'), T('360°'), T('90° + rotate'), T('180° + rotate')], ApplyArc, FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Arc distortion'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuSwirlClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDistortDlg(T('Swirl'), [T('Weak (45°)'), T('Medium (90°)'), T('Strong (180°)'), T('Very strong (270°)'), T('Full (360°)'), T('Reverse')], ApplySwirl, FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Swirl'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuWaterRippleClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowWaterRippleDlg(T('Water ripple'), [T('Light'), T('Medium'), T('Strong'), T('Concentric'), T('From corner'), T('Dense')], ApplyWaterRippleEx, FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Water ripple'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuPolarClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowDistortDlg(T('Polar distortion'), [T('Full'), T('Half angle'), T('Quarter angle'), T('Ring'), T('Small radius'), T('Smooth'), T('Tunnel'), T('Swirl'), T('Fisheye'), T('Outer stretch'), T('Inverted tunnel'), T('30° slice')], ApplyPolar, FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Polar distortion'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

{ ========================================================================= }
{  Amigowe }
{ ========================================================================= }

procedure TfrmMain.mnuWB1Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyWorkbench1(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('WB 1.x palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuWB2Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyWorkbench2(FBitmap);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('WB 2.x/3.x palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuOCS32Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
  UseDither: Boolean;
begin
  if FBitmap.Width = 0 then Exit;
  if not ShowPaletteDlg(T('OCS 32-color palette'), FBitmap, @ApplyOCS32, UseDither) then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyOCS32(FBitmap, UseDither);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'OCS32';
  gMacroPending.Params := IntToStr(Ord(UseDither));
  FinishEffect(T('OCS 32 palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuEHBClick(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
  UseDither: Boolean;
begin
  if FBitmap.Width = 0 then Exit;
  if not ShowPaletteDlg(T('EHB 64-color palette'), FBitmap, @ApplyEHB, UseDither) then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyEHB(FBitmap, UseDither);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'EHB64';
  gMacroPending.Params := IntToStr(Ord(UseDither));
  FinishEffect(T('EHB 64 palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuAGA256Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
  UseDither: Boolean;
begin
  if FBitmap.Width = 0 then Exit;
  if not ShowPaletteDlg(T('AGA 256-color palette'), FBitmap, @ApplyAGA256, UseDither) then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyAGA256(FBitmap, UseDither);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'AGA256';
  gMacroPending.Params := IntToStr(Ord(UseDither));
  FinishEffect(T('AGA 256 palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuWB256Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
  UseDither: Boolean;
begin
  if FBitmap.Width = 0 then Exit;
  if not ShowPaletteDlg(T('Workbench 256-color palette'), FBitmap, @ApplyWB256, UseDither) then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyWB256(FBitmap, UseDither);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'WB256';
  gMacroPending.Params := IntToStr(Ord(UseDither));
  FinishEffect(T('Workbench 256 palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuMagicWBClick(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
  UseDither: Boolean;
begin
  if FBitmap.Width = 0 then Exit;
  if not ShowPaletteDlg(T('MagicWB 8-color palette'), FBitmap, @ApplyMagicWB, UseDither) then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyMagicWB(FBitmap, UseDither);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  gMacroPending.Code := 'MAGICWB';
  gMacroPending.Params := IntToStr(Ord(UseDither));
  FinishEffect(T('MagicWB palette'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuHAM6Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyHAM(FBitmap, 4);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('HAM6'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuHAM8Click(Sender: TObject);
var
  SW: TStopwatch;
  Backup: TBitmap;
begin
  if FBitmap.Width = 0 then Exit;
  SW := TStopwatch.StartNew;
  Backup := nil;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  ApplyHAM(FBitmap, 6);
  if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
  FinishEffect(T('HAM8'), SW.Elapsed.TotalSeconds);
end;

procedure TfrmMain.mnuAmigaGradientClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowAmigaGradientDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Amiga gradient'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuAmigaGradientAgonyClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowAgonyDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Amiga gradient (Agony)'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuAmigaBGClick(Sender: TObject);
var
  Elapsed: Double;
begin
  if FBitmap.Width = 0 then Exit;
  UndoPush(FBitmap);
  if ShowAmigaBGDlg(FBitmap, Elapsed) then
  begin
    FSelection.Clear;
    UpdateZoomFit; FinishEffect(T('Amiga background'), Elapsed);
  end;
end;

procedure TfrmMain.mnuAmigaBGSClick(Sender: TObject);
var
  Elapsed: Double;
begin
  if FBitmap.Width = 0 then Exit;
  UndoPush(FBitmap);
  if ShowAmigaBGSDlg(FBitmap, Elapsed) then
  begin
    FSelection.Clear;
    UpdateZoomFit; FinishEffect(T('Amiga background (stretched, MagicWB)'), Elapsed);
  end;
end;

{ ========================================================================= }
{  Inne retrokomputery }
{ ========================================================================= }

procedure TfrmMain.mnuC64Click(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowC64Dlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Commodore 64'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuZXSpectrumClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowZXSpectrumDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('ZX Spectrum'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuGameBoyClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowGameBoyDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('Game Boy'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

procedure TfrmMain.mnuNESClick(Sender: TObject);
var
  Elapsed: Double;
  Backup: TBitmap;
begin
  Backup := nil;
  if FBitmap.Width = 0 then Exit;
  if NeedEffectBackup then
  begin Backup := TBitmap.Create; Backup.Assign(FBitmap); end;
  UndoPush(FBitmap);
  if ShowNESDlg(FBitmap, Elapsed) then
  begin
    if Backup <> nil then begin RestoreOutsideSelection(Backup); Backup.Free; end;
    FinishEffect(T('NES - Nestopia'), Elapsed);
  end
  else if Backup <> nil then Backup.Free;
end;

{ ========================================================================= }
{  Ustawienia }
{ ========================================================================= }

procedure TfrmMain.mnuSettingsLangClick(Sender: TObject);
var
  Lang: TLanguage;
begin
  Lang := CurrentLanguage;
  if ShowLanguageDlg(Lang) then
  begin
    SetLanguage(Lang);
    Prefs.Language := Ord(Lang);
    SavePrefs;
  end;
end;

procedure TfrmMain.mnuSettingsQualityClick(Sender: TObject);
begin
  ShowQualityDlg;
end;

procedure TfrmMain.InterfacePreview(AColor: TColor; AFontSize: Integer);
begin
  Self.Color := AColor;
  ScrollBox.Color := AColor;
  StatusBar.UseSystemFont := False;
  StatusBar.Font.Size := Application.DefaultFont.Size - Prefs.UIFontSize + AFontSize;
end;

procedure TfrmMain.mnuSettingsInterfaceClick(Sender: TObject);
var
  NewBG: TColor;
  NewRemember: Boolean;
  NewFontSize, NewRecentCount: Integer;
  NewTheme: string;
  OldBG: TColor;
  OldFontSize: Integer;
  OldTheme: string;
begin
  OldBG := Prefs.CanvasBG;
  OldFontSize := Prefs.UIFontSize;
  OldTheme := Prefs.ThemeName;

  NewBG := Prefs.CanvasBG;
  NewRemember := Prefs.RememberWin;
  NewFontSize := Prefs.UIFontSize;
  NewRecentCount := Prefs.RecentFilesCount;
  NewTheme := Prefs.ThemeName;

  if ShowInterfaceDlg(NewBG, NewRemember, NewFontSize, NewRecentCount,
    NewTheme, InterfacePreview) then
  begin
    Prefs.CanvasBG := NewBG;
    Prefs.RememberWin := NewRemember;
    Prefs.UIFontSize := NewFontSize;
    Prefs.RecentFilesCount := NewRecentCount;
    Prefs.ThemeName := NewTheme;
    SavePrefs;

    Self.Color := Prefs.CanvasBG;
    ScrollBox.Color := Prefs.CanvasBG;
    Application.DefaultFont.Size := Application.DefaultFont.Size - OldFontSize + NewFontSize;
    Screen.MenuFont.Size := Screen.MenuFont.Size - OldFontSize + NewFontSize;
    Self.Menu := nil;
    Self.Menu := MainMenu;
    StatusBar.UseSystemFont := False;
    StatusBar.Font.Size := Application.DefaultFont.Size;
    RebuildRecentMenu(mnuFile, mnuFileSepRecent, HandleRecentFileClick);
    TStyleManager.TrySetStyle(Prefs.ThemeName);
    ApplyThemeLabelColors(Self);
  end
  else
  begin
    Self.Color := OldBG;
    ScrollBox.Color := OldBG;
    StatusBar.UseSystemFont := False;
    StatusBar.Font.Size := Application.DefaultFont.Size;
    TStyleManager.TrySetStyle(OldTheme);
    ApplyThemeLabelColors(Self);
  end;
end;

procedure TfrmMain.mnuSettingsPerformanceClick(Sender: TObject);
begin
  ShowPerformanceDlg;
end;

{ ========================================================================= }
{  Pomoc }
{ ========================================================================= }

procedure TfrmMain.mnuLauncherClick(Sender: TObject);
begin
  if FLauncherDlg = nil then
    FLauncherDlg := TLauncherDlg.Create(Self);
  if FLauncherDlg.Visible then
    FLauncherDlg.Hide
  else
  begin
    FLauncherDlg.Show;
    FLauncherDlg.BringToFront;
  end;
end;

procedure TfrmMain.mnuToolsPanelClick(Sender: TObject);
begin
  if FToolsDlg = nil then
    FToolsDlg := TToolsDlg.Create(Self);
  if FToolsDlg.Visible then
  begin
    ActivateTool(tkSelection);
    FToolsDlg.Hide;
  end
  else
  begin
    FToolsDlg.Show;
    FToolsDlg.BringToFront;
  end;
end;

procedure TfrmMain.mnuSelPanelClick(Sender: TObject);
begin
  TSelDlg.ShowSelection;
end;

procedure TfrmMain.mnuRemoveBackgroundClick(Sender: TObject);
var
  Corner, Tolerance: Integer;
  SW: TStopwatch;
  Elapsed: Double;
begin
  if FBitmap = nil then Exit;
  if FBitmap.Width = 0 then Exit;
  if (FAlphaMask = nil) or (FAlphaMask.Width <> FBitmap.Width) or
     (FAlphaMask.Height <> FBitmap.Height) then
    EnsureAlphaMask;
  if not ShowUsunTloDlg(FBitmap, FAlphaMask, Corner, Tolerance) then Exit;
  SW := TStopwatch.StartNew;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  ApplyRemoveBackground(FBitmap, FAlphaMask, Corner, Tolerance, FAlphaDirtyRect);
  Elapsed := SW.Elapsed.TotalSeconds;
  FinishEffect(T('Remove background'), Elapsed);
end;

procedure TfrmMain.mnuProtShowClick(Sender: TObject);
begin
  FShowProtMask := not FShowProtMask;
  mnuProtShow.Checked := FShowProtMask;
  PaintBox.Invalidate;
end;

procedure TfrmMain.mnuProtClearClick(Sender: TObject);
begin
  if FBitmap = nil then Exit;
  if FBitmap.Width = 0 then Exit;
  if (FProtMask <> nil) and (FProtCoverCount > 0) then
  begin
    UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
    FProtMask.Canvas.Brush.Color := clBlack;
    FProtMask.Canvas.FillRect(Rect(0, 0, FProtMask.Width, FProtMask.Height));
    RecalcProtCoverCount;
    FDirty := True;
    UpdateCaption;
    PaintBox.Invalidate;
  end;
end;

procedure TfrmMain.mnuProtFromSelClick(Sender: TObject);
var
  R: TRect;
  Y, X: Integer;
  MP: PByte;
begin
  if FBitmap = nil then Exit;
  if FBitmap.Width = 0 then Exit;
  if not FSelection.IsValid then Exit;
  // Tworzymy czysta maske tylko gdy brak lub zly rozmiar - inaczej dopisujemy
  // do istniejacej ochrony (EnsureProtMask kasuje cala maske).
  if (FProtMask = nil) or (FProtMask.Width <> FBitmap.Width) or
     (FProtMask.Height <> FBitmap.Height) then
    EnsureProtMask;
  if FProtMask = nil then Exit;
  R := FSelection.ClampedRect(FBitmap.Width, FBitmap.Height);
  if (R.Right < R.Left) or (R.Bottom < R.Top) then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  for Y := R.Top to R.Bottom do
  begin
    MP := FProtMask.ScanLine[Y];
    for X := R.Left to R.Right do
      if FSelection.Contains(X + 0.5, Y + 0.5) then
        MP[X] := 255;
  end;
  FSelection.Clear;
  RecalcProtCoverCount;
  FShowProtMask := True;
  mnuProtShow.Checked := True;
  FDirty := True;
  UpdateCaption;
  PaintBox.Invalidate;
end;

procedure TfrmMain.mnuProtUnprotSelClick(Sender: TObject);
var
  R: TRect;
  Y, X: Integer;
  MP: PByte;
begin
  if FBitmap = nil then Exit;
  if FBitmap.Width = 0 then Exit;
  if (FProtMask = nil) or (FProtCoverCount = 0) then Exit;
  if not FSelection.IsValid then Exit;
  R := FSelection.ClampedRect(FBitmap.Width, FBitmap.Height);
  if (R.Right < R.Left) or (R.Bottom < R.Top) then Exit;
  UndoPushMasked(FBitmap, FAlphaMask, FProtMask);
  for Y := R.Top to R.Bottom do
  begin
    MP := FProtMask.ScanLine[Y];
    for X := R.Left to R.Right do
      if FSelection.Contains(X + 0.5, Y + 0.5) then
        MP[X] := 0;
  end;
  FSelection.Clear;
  RecalcProtCoverCount;
  FDirty := True;
  UpdateCaption;
  PaintBox.Invalidate;
end;

function TfrmMain.ActivateTool(ATool: TToolKind): ICanvasTool;
begin
  if FActiveToolKind = ATool then
  begin
    Result := FActiveTool;
    Exit;
  end;
  FActiveTool.Deactivate;
  FActiveTool := nil;
  case ATool of
    tkSelection:  FActiveTool := TSelectionTool.Create(Self);
    tkEraser:     FActiveTool := TEraserTool.Create(Self);
    tkEyedropper: FActiveTool := TEyedropperTool.Create(Self);
    tkBucket:     FActiveTool := TFloodFillTool.Create(Self);
    tkBrush:      FActiveTool := TRetouchBrushTool.Create(Self);
    tkProtect:    FActiveTool := TProtectTool.Create(Self);
  end;
  FActiveToolKind := ATool;
  FActiveTool.Activate;
  Result := FActiveTool;
end;

function TfrmMain.GetActiveToolKind: TToolKind;
begin
  Result := FActiveToolKind;
end;

function TfrmMain.GetSelectionShape: THitShape;
begin
  Result := FSelection.Shape;
end;

function TfrmMain.GetRetouchEraseMode: Boolean;
begin
  Result := FPanelErase;
end;

procedure TfrmMain.SetRetouchEraseMode(AErase: Boolean);
begin
  // Tryb czyta TEraserTool na początku każdego stroke'u (MouseDown) - tu
  // wystarczy zapis flagi, bez dotykania wewnętrznego FMode narzędzia.
  FPanelErase := AErase;
end;

function TfrmMain.GetRetouchBrushSize: Integer;
begin
  Result := FRetouchBrushSize;
end;

procedure TfrmMain.SetRetouchBrushSize(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if AValue > 100 then AValue := 100;
  FRetouchBrushSize := AValue;
end;

function TfrmMain.GetRetouchStrength: Integer;
begin
  Result := FRetouchStrength;
end;

procedure TfrmMain.SetRetouchStrength(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue > 100 then AValue := 100;
  FRetouchStrength := AValue;
end;

function TfrmMain.GetForeColor: TColor;
begin
  Result := FForeColor;
end;

procedure TfrmMain.SetForeColor(AColor: TColor);
begin
  FForeColor := AColor;
  // Swatch w panelu Narzędzi odświeżany zawsze - zakraplacz działa nawet,
  // gdy panel jest ukryty, a zmianę widać po ponownym otwarciu.
  if FToolsDlg <> nil then
    FToolsDlg.RefreshForeColor;
end;

function TfrmMain.GetRetouchTolerance: Integer;
begin
  Result := FRetouchTolerance;
end;

procedure TfrmMain.SetRetouchTolerance(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue > 100 then AValue := 100;
  FRetouchTolerance := AValue;
  // Otwarty dialog Retusz (suwak wiaderka) podąża za tą samą wartością.
  if (FToolsDlg <> nil) and FToolsDlg.Visible then
    FToolsDlg.SyncToleranceSlider(AValue);
  if Assigned(SelDlgInst) then
    SelDlgInst.SyncStatus;
end;

function TfrmMain.GetRetouchBrushMode: TBrushMode;
begin
  Result := FBrushMode;
end;

procedure TfrmMain.SetRetouchBrushMode(AMode: TBrushMode);
begin
  FBrushMode := AMode;
end;

function TfrmMain.GetReplaceColor: TColor;
begin
  Result := FReplaceColor;
end;

procedure TfrmMain.SetReplaceColor(AColor: TColor);
begin
  FReplaceColor := AColor;
  // Swatch w panelu Narzędzi odświeżany tak samo jak przy SetForeColor.
  if FToolsDlg <> nil then
    FToolsDlg.RefreshForeColor;
end;

function TfrmMain.GetReplaceRetainShading: Boolean;
begin
  Result := FReplaceRetainShading;
end;

procedure TfrmMain.SetReplaceRetainShading(AValue: Boolean);
begin
  FReplaceRetainShading := AValue;
end;

function TfrmMain.GetRetouchProtectMode: Boolean;
begin
  // True = Zakrywaj (rysuj maskę ochronną), False = Odkrywaj (kasuj maskę).
  Result := FProtectCover;
end;

procedure TfrmMain.SetRetouchProtectMode(ACover: Boolean);
begin
  // Tryb czyta TProtectTool na początku każdego stroke'u (MouseDown) - tu
  // wystarczy zapis flagi, bez dotykania wewnętrznego stanu narzędzia.
  FProtectCover := ACover;
end;

function TfrmMain.RetouchEffectiveRadius: Integer;
// Promień malowanego dysku w pikselach obrazu. Dla zamiany koloru skaluje go
// siła (Str=100 = pełny pędzel), bo pas kolorów wybiera tolerancja — oba
// suwaki muszą działać niezależnie. Używane przez malowanie i przez pierścień
// kursora, żeby kursor pokazywał faktycznie malowany obszar.
var
  R: Integer;
begin
  R := Max(1, FRetouchBrushSize div 2);
  if FBrushMode = bmColorReplace then
    R := Max(1, R * FRetouchStrength div 100);
  Result := R;
end;

procedure TfrmMain.UpdateBrushCursor(AX, AY: Integer);
var
  R: Integer;
begin
  R := Round(RetouchEffectiveRadius * FZoomFactor) + 3;
  if R < 5 then R := 5;
  // Pierścień rysowany bezpośrednio na płótnie, bez invalidation: każdy WM_PAINT
  // wywołuje pełny repaint canvasu (StretchDraw całego obrazu w DoubleBuffered
  // formie) = "wolna gumka". Stara pozycja jest czyszona ponownym rysunkiem
  // tła (obraz + szachownica) w rectu pierścienia.
  if FBrushCursorOn then
    RedrawRingBackdrop(FBrushCursorRect);
  FBrushCursorRect := Rect(AX - R, AY - R, AX + R, AY + R);
  FBrushCursorX := AX;
  FBrushCursorY := AY;
  FBrushCursorOn := True;
  DrawRing;
end;

procedure TfrmMain.ClearBrushCursor;
begin
  if FBrushCursorOn then
  begin
    RedrawRingBackdrop(FBrushCursorRect);
    FBrushCursorOn := False;
    FBrushCursorRect := Rect(0, 0, 0, 0);
  end;
end;

procedure TfrmMain.DrawRing;
var
  R, Cx, Cy: Integer;
begin
  R := Round(RetouchEffectiveRadius * FZoomFactor);
  if R < 2 then R := 2;
  Cx := FBrushCursorX;
  Cy := FBrushCursorY;
  with PaintBox.Canvas do
  begin
    Brush.Style := bsClear;
    Pen.Style := psSolid;
    Pen.Width := 2;
    Pen.Color := clBlack;
    Ellipse(Cx - R, Cy - R, Cx + R, Cy + R);
    Pen.Width := 1;
    Pen.Color := clWhite;
    Ellipse(Cx - R + 1, Cy - R + 1, Cx + R - 1, Cy + R - 1);
    Pen.Style := psSolid;
    Brush.Style := bsSolid;
  end;
end;

procedure TfrmMain.RedrawRingBackdrop(ARect: TRect);
// Bezpośrednie odtworzenie tła pod pierścieniem w rectu ekranowym, bez
// unieważniania repaintu. Źródło = FBacking ("czysty kadr" z ostatniego
// WM_PAINT, obraz+szachownica+overlay bez pierścienia) kopiowane 1:1 — ten
// sam spójny stan, który publikuje PaintBoxPaint, więc pierścień nie zostawia
// rozjazdu pomiędzy buforowanym repaintem formy a rysunkiem bezpośrednim.
var
  DstR: TRect;
begin
  if FBacking = nil then Exit;
  if (FBacking.Width <> PaintBox.Width) or
     (FBacking.Height <> PaintBox.Height) then Exit;
  DstR := ARect;
  if System.Types.IsRectEmpty(DstR) then Exit;
  System.Types.IntersectRect(DstR, DstR, PaintBox.ClientRect);
  if System.Types.IsRectEmpty(DstR) then Exit;
  PaintBox.Canvas.CopyRect(DstR, FBacking.Canvas, DstR);
end;

procedure TfrmMain.DrawBrushCursor;
var
  R, Cx, Cy: Integer;
begin
  if not FBrushCursorOn then Exit;
  R := Round(RetouchEffectiveRadius * FZoomFactor);
  if R < 2 then R := 2;
  Cx := FBrushCursorX;
  Cy := FBrushCursorY;
  // Środek poza widocznym obszarem - nic do rysowania.
  if (Cx + R < 0) or (Cy + R < 0) or
     (Cx - R >= PaintBox.Width) or (Cy - R >= PaintBox.Height) then Exit;
  DrawRing;
end;

procedure TfrmMain.mnuHelpAboutClick(Sender: TObject);
begin
  with TfrmAbout.Create(Application) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TfrmMain.mnuHelpShortcutsClick(Sender: TObject);
begin
  with TfrmShortcutsDlg.Create(Application) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure TfrmMain.mnuHelpBenchmarkClick(Sender: TObject);
begin
  if FBitmap.Width = 0 then
  begin
    MessageDlg(T('Load an image before running the performance test.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  RunBenchmark(FBitmap, Self.DoOrton, Self);
end;

procedure TfrmMain.mnuHelpOnlineDocsClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://amiga.org.pl/fotografista/', nil, nil,
    SW_SHOWNORMAL);
end;

{ ========================================================================= }
{  Internal }
{ ========================================================================= }

procedure TfrmMain.LoadImage(const APath: string);
var
  NewBitmap: TBitmap;
begin
  NewBitmap := nil;
  try
    NewBitmap := LoadImageFile(APath);
    ApplyMaxResolution(NewBitmap);
    FBitmap.Free;
    FBitmap := NewBitmap;
    NewBitmap := nil;
    EnsureAlphaMask;
    EnsureProtMask;
    FRasterPreview := False;
    InvalidatePreviewCache;
    FFilePath := APath;
    FDirty := False;
    UndoClear;
    UpdateCaption;
    AddRecentFile(APath);
    RebuildRecentMenu(mnuFile, mnuFileSepRecent, HandleRecentFileClick);
    UpdateZoomFit;
    UpdateStatusBar;
    UpdateMenuState;
    if Assigned(SelDlgInst) then
      SelDlgInst.SyncStatus;
  except
    on E: Exception do
    begin
      NewBitmap.Free;
      if FBitmap = nil then
      begin
        FBitmap := TBitmap.Create;
        FBitmap.PixelFormat := pf24bit;
      end;
      MessageDlg(T('Cannot load image:') + sLineBreak + E.Message,
        mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.SaveImage(const APath: string);
begin
  SaveImageFile(FBitmap, APath);
  FFilePath := APath;
  FDirty := False;
  UpdateCaption;
end;

procedure TfrmMain.CloseImage;
begin
  FBitmap.Free;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf24bit;
  FAlphaMask.Free;
  FAlphaMask := nil;
  FAlphaDirtyRect := Rect(0, 0, 0, 0);
  FProtMask.Free;
  FProtMask := nil;
  FProtDirtyRect := Rect(0, 0, 0, 0);
  FProtCoverCount := 0;
  FRasterPreview := False;
  InvalidatePreviewCache;
  FSelection.Clear;
  FSelecting := False;
  FFilePath := '';
  FZoomFactor := 1.0;
  FDirty := False;
  UpdateCaption;
  UpdateStatusBar;
  UpdateLayout;
  UpdateMenuState;
  if Assigned(SelDlgInst) then
    SelDlgInst.SyncStatus;
end;

procedure TfrmMain.EnsureAlphaMask;
var
  Y: Integer;
  P: PByte;
begin
  FAlphaDirtyRect := Rect(0, 0, 0, 0);
  FAlphaMask.Free;
  FAlphaMask := nil;
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then Exit;
  FAlphaMask := TBitmap.Create;
  FAlphaMask.PixelFormat := pf8bit;
  FAlphaMask.Width := FBitmap.Width;
  FAlphaMask.Height := FBitmap.Height;
  for Y := 0 to FAlphaMask.Height - 1 do
  begin
    P := FAlphaMask.ScanLine[Y];
    FillChar(P^, FAlphaMask.Width, 255);
  end;
end;

procedure TfrmMain.EnsureProtMask;
var
  Y: Integer;
  P: PByte;
begin
  FProtDirtyRect := Rect(0, 0, 0, 0);
  FProtCoverCount := 0;
  FProtMask.Free;
  FProtMask := nil;
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then Exit;
  FProtMask := TBitmap.Create;
  FProtMask.PixelFormat := pf8bit;
  FProtMask.Width := FBitmap.Width;
  FProtMask.Height := FBitmap.Height;
  for Y := 0 to FProtMask.Height - 1 do
  begin
    P := FProtMask.ScanLine[Y];
    FillChar(P^, FProtMask.Width, 0);
  end;
end;

procedure TfrmMain.RecalcProtCoverCount;
var
  Y, X, C: Integer;
  P: PByte;
  MinX, MinY, MaxX, MaxY: Integer;
begin
  C := 0;
  MinX := MaxInt; MinY := MaxInt;
  MaxX := -MaxInt; MaxY := -MaxInt;
  if FProtMask <> nil then
    for Y := 0 to FProtMask.Height - 1 do
    begin
      P := FProtMask.ScanLine[Y];
      for X := 0 to FProtMask.Width - 1 do
        if P[X] <> 0 then
        begin
          Inc(C);
          if X < MinX then MinX := X;
          if X > MaxX then MaxX := X;
          if Y < MinY then MinY := Y;
          if Y > MaxY then MaxY := Y;
        end;
    end;
  FProtCoverCount := C;
  if C = 0 then
    FProtDirtyRect := Rect(0, 0, 0, 0)
  else
    FProtDirtyRect := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

{ Transformacje maski ochronnej (FProtMask, 1 bajt/piksel, 255 = chronione).
  Każda operacja przepisuje maskę tak samo jak operacja na obrazie, żeby
  maska pozostała wyrównana z pikselami obrazu po flip/rotate/resize. }

procedure TfrmMain.ProtFlipH;
var
  Y, X: Integer;
  Row: PByte;
  Tmp: Byte;
begin
  if FProtMask = nil then Exit;
  for Y := 0 to FProtMask.Height - 1 do
  begin
    Row := FProtMask.ScanLine[Y];
    for X := 0 to (FProtMask.Width div 2) - 1 do
    begin
      Tmp := Row[X];
      Row[X] := Row[FProtMask.Width - 1 - X];
      Row[FProtMask.Width - 1 - X] := Tmp;
    end;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtFlipV;
var
  Y, RowSize: Integer;
  TmpRow: array of Byte;
begin
  if FProtMask = nil then Exit;
  RowSize := FProtMask.Width;
  SetLength(TmpRow, RowSize);
  for Y := 0 to (FProtMask.Height div 2) - 1 do
  begin
    Move(FProtMask.ScanLine[Y]^, TmpRow[0], RowSize);
    Move(FProtMask.ScanLine[FProtMask.Height - 1 - Y]^,
      FProtMask.ScanLine[Y]^, RowSize);
    Move(TmpRow[0], FProtMask.ScanLine[FProtMask.Height - 1 - Y]^, RowSize);
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.AlphaFlipH;
var
  Y, X: Integer;
  Row: PByte;
  Tmp: Byte;
begin
  if FAlphaMask = nil then Exit;
  for Y := 0 to FAlphaMask.Height - 1 do
  begin
    Row := FAlphaMask.ScanLine[Y];
    for X := 0 to (FAlphaMask.Width div 2) - 1 do
    begin
      Tmp := Row[X];
      Row[X] := Row[FAlphaMask.Width - 1 - X];
      Row[FAlphaMask.Width - 1 - X] := Tmp;
    end;
  end;
  FAlphaDirtyRect := Rect(0, 0, FAlphaMask.Width, FAlphaMask.Height);
end;

procedure TfrmMain.AlphaFlipV;
var
  Y, RowSize: Integer;
  TmpRow: array of Byte;
begin
  if FAlphaMask = nil then Exit;
  RowSize := FAlphaMask.Width;
  SetLength(TmpRow, RowSize);
  for Y := 0 to (FAlphaMask.Height div 2) - 1 do
  begin
    Move(FAlphaMask.ScanLine[Y]^, TmpRow[0], RowSize);
    Move(FAlphaMask.ScanLine[FAlphaMask.Height - 1 - Y]^,
      FAlphaMask.ScanLine[Y]^, RowSize);
    Move(TmpRow[0], FAlphaMask.ScanLine[FAlphaMask.Height - 1 - Y]^, RowSize);
  end;
  FAlphaDirtyRect := Rect(0, 0, FAlphaMask.Width, FAlphaMask.Height);
end;

procedure TfrmMain.ProtRotateLeft;
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow: PByte;
  New: TBitmap;
begin
  if FProtMask = nil then Exit;
  W := FProtMask.Width;
  H := FProtMask.Height;
  Src := FProtMask;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(H, W);
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
        PByte(New.ScanLine[W - 1 - X])[Y] := SrcRow[X];
    end;
    FProtMask.Free;
    FProtMask := New;
  except
    New.Free;
    raise;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtRotateRight;
var
  X, Y, W, H: Integer;
  SrcRow: PByte;
  New: TBitmap;
begin
  if FProtMask = nil then Exit;
  W := FProtMask.Width;
  H := FProtMask.Height;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(H, W);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FProtMask.ScanLine[Y];
      for X := 0 to W - 1 do
        PByte(New.ScanLine[X])[H - 1 - Y] := SrcRow[X];
    end;
    FProtMask.Free;
    FProtMask := New;
  except
    New.Free;
    raise;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtRotate180;
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow, DstRow: PByte;
begin
  if FProtMask = nil then Exit;
  Src := TBitmap.Create;
  try
    Src.Assign(FProtMask);
    Src.PixelFormat := pf8bit;
    W := Src.Width;
    H := Src.Height;
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      DstRow := FProtMask.ScanLine[H - 1 - Y];
      for X := 0 to W - 1 do
        DstRow[W - 1 - X] := SrcRow[X];
    end;
  finally
    Src.Free;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtCrop(const R: TRect);
var
  W, H, Y, X: Integer;
  New: TBitmap;
  SrcRow, DstRow: PByte;
begin
  if FProtMask = nil then Exit;
  W := R.Right - R.Left + 1;
  H := R.Bottom - R.Top + 1;
  if (W < 1) or (H < 1) then Exit;
  if (R.Left < 0) or (R.Top < 0) or
     (R.Right >= FProtMask.Width) or (R.Bottom >= FProtMask.Height) then Exit;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FProtMask.ScanLine[R.Top + Y];
      DstRow := New.ScanLine[Y];
      for X := 0 to W - 1 do
        DstRow[X] := SrcRow[R.Left + X];
    end;
    FProtMask.Free;
    FProtMask := New;
  except
    New.Free;
    raise;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtResize(NewW, NewH: Integer);
var
  Src: TBitmap;
  W, H, Y, X, SX, SY: Integer;
  New: TBitmap;
  SrcRow, DstRow: PByte;
begin
  if FProtMask = nil then Exit;
  if (NewW < 1) or (NewH < 1) then Exit;
  if (NewW = FProtMask.Width) and (NewH = FProtMask.Height) then Exit;
  Src := FProtMask;
  W := Src.Width;
  H := Src.Height;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(NewW, NewH);
    for Y := 0 to NewH - 1 do
    begin
      SY := Y * H div NewH;
      SrcRow := Src.ScanLine[SY];
      DstRow := New.ScanLine[Y];
      for X := 0 to NewW - 1 do
      begin
        SX := X * W div NewW;
        DstRow[X] := SrcRow[SX];
      end;
    end;
    FProtMask.Free;
    FProtMask := New;
  except
    New.Free;
    raise;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtResizeCrop(TargetW, TargetH, Corner: Integer);
var
  Scale, SW, SH: Double;
  ScaledW, ScaledH, ExcessW, ExcessH, CropX, CropY: Integer;
  New, Scaled: TBitmap;
  W, H, Y, X, SX, SY: Integer;
  SrcRow, DstRow: PByte;
begin
  if FProtMask = nil then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;
  W := FProtMask.Width;
  H := FProtMask.Height;
  if (W = 0) or (H = 0) then Exit;
  SW := TargetW / W;
  SH := TargetH / H;
  if SW > SH then Scale := SW else Scale := SH;
  ScaledW := Max(1, Round(W * Scale));
  ScaledH := Max(1, Round(H * Scale));
  ExcessW := ScaledW - TargetW;
  ExcessH := ScaledH - TargetH;
  case Corner of
    0: begin CropX := 0;       CropY := 0;       end;
    1: begin CropX := ExcessW; CropY := 0;       end;
    2: begin CropX := 0;       CropY := ExcessH; end;
  else
    begin CropX := ExcessW;   CropY := ExcessH; end;
  end;
  if CropX < 0 then CropX := 0;
  if CropY < 0 then CropY := 0;
  Scaled := TBitmap.Create;
  try
    Scaled.PixelFormat := pf8bit;
    Scaled.SetSize(ScaledW, ScaledH);
    for Y := 0 to ScaledH - 1 do
    begin
      SY := Y * H div ScaledH;
      SrcRow := FProtMask.ScanLine[SY];
      DstRow := Scaled.ScanLine[Y];
      for X := 0 to ScaledW - 1 do
      begin
        SX := X * W div ScaledW;
        DstRow[X] := SrcRow[SX];
      end;
    end;
    New := TBitmap.Create;
    try
      New.PixelFormat := pf8bit;
      New.SetSize(TargetW, TargetH);
      for Y := 0 to TargetH - 1 do
      begin
        SrcRow := Scaled.ScanLine[CropY + Y];
        Move((SrcRow + CropX)^, New.ScanLine[Y]^, TargetW);
      end;
      FProtMask.Free;
      FProtMask := New;
    except
      New.Free;
      raise;
    end;
  finally
    Scaled.Free;
  end;
  RecalcProtCoverCount;
end;

procedure TfrmMain.ProtRotateAngle(AngleDeg: Double);
var
  Src, RotBmp, NewMask: TBitmap;
  SrcGP: TGPBitmap;
  G: TGPGraphics;
  RotM: TGPMatrix;
  W, H: Integer;
  Rad, AbsCos, AbsSin, Cos2: Double;
  IW, IH: Double;
  CW, CH, CropX, CropY: Integer;
  Y, X: Integer;
  SrcRow, DstRow: PByte;
  V: Byte;
begin
  if FProtMask = nil then Exit;
  if (FProtMask.Width = 0) or (FProtMask.Height = 0) or (AngleDeg = 0) then Exit;
  W := FProtMask.Width;
  H := FProtMask.Height;

  // 1. Zachowujemy maske w pf8bit, obrot wykonamy na kopii pf24bit.
  Src := TBitmap.Create;
  try
    Src.PixelFormat := pf24bit;
    Src.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FProtMask.ScanLine[Y];
      DstRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        V := SrcRow[X];
        if V > 127 then V := 255 else V := 0;
        DstRow[X * 3] := V;
        DstRow[X * 3 + 1] := V;
        DstRow[X * 3 + 2] := V;
      end;
    end;

    // 2. Obrot GDI+ w czystym, pelnym wymiarze - identyczny wzor jak w RotateAndCrop
    RotBmp := TBitmap.Create;
    try
      RotBmp.PixelFormat := pf24bit;
      RotBmp.SetSize(W, H);

      SrcGP := TGPBitmap.Create(Src.Handle, Src.Palette);
      try
        G := TGPGraphics.Create(RotBmp.Canvas.Handle);
        try
          G.SetInterpolationMode(InterpolationModeHighQualityBilinear);
          G.Clear(MakeColor(255, 0, 0, 0));

          RotM := TGPMatrix.Create;
          try
            RotM.RotateAt(AngleDeg, MakePoint(W / 2.0, H / 2.0));
            G.SetTransform(RotM);
            G.DrawImage(SrcGP, 0, 0, W, H);
          finally
            RotM.Free;
          end;
        finally
          G.Free;
        end;
      finally
        SrcGP.Free;
      end;

      // 3. Wpisany prostokat (Inscribed Rectangle) - ten sam wzor co w RotateAndCrop
      Rad := AngleDeg * Pi / 180.0;
      AbsCos := Abs(Cos(Rad));
      AbsSin := Abs(Sin(Rad));
      Cos2 := Cos(2 * Rad);

      CW := W;
      CH := H;
      CropX := 0;
      CropY := 0;

      if Abs(Cos2) > 0.01 then
      begin
        IW := (W * AbsCos - H * AbsSin) / Cos2;
        IH := (H * AbsCos - W * AbsSin) / Cos2;

        if (IW > W * 0.5) and (IH > H * 0.5) then
        begin
          CropX := Integer(Trunc((W - IW) / 2));
          CropY := Integer(Trunc((H - IH) / 2));
          CW := Min(Integer(Trunc(IW)), W - CropX);
          CH := Min(Integer(Trunc(IH)), H - CropY);
        end;
      end;

      // 4. Przepisujemy przyciety wynik i wracamy do twardej maski 0/255
      NewMask := TBitmap.Create;
      try
        NewMask.PixelFormat := pf8bit;
        NewMask.SetSize(CW, CH);
        for Y := 0 to CH - 1 do
        begin
          SrcRow := RotBmp.ScanLine[CropY + Y];
          DstRow := NewMask.ScanLine[Y];
          for X := 0 to CW - 1 do
          begin
            V := SrcRow[(CropX + X) * 3];
            if V > 127 then DstRow[X] := 255 else DstRow[X] := 0;
          end;
        end;
        FProtMask.Free;
        FProtMask := NewMask;
      except
        NewMask.Free;
        raise;
      end;
      RecalcProtCoverCount;
    finally
      RotBmp.Free;
    end;
  finally
    Src.Free;
  end;
end;

procedure TfrmMain.AlphaRotateAngle(AngleDeg: Double); // naprawa prostowania skanu 
var
  Src, RotBmp, NewMask: TBitmap;
  SrcGP: TGPBitmap;
  G: TGPGraphics;
  RotM: TGPMatrix;
  W, H: Integer;
  Rad, AbsCos, AbsSin, Cos2: Double;
  IW, IH: Double;
  CW, CH, CropX, CropY: Integer;
  Y, X: Integer;
  SrcRow, DstRow: PByte;
  V: Byte;
begin
  if FAlphaMask = nil then Exit;
  if (FAlphaMask.Width = 0) or (FAlphaMask.Height = 0) or (AngleDeg = 0) then Exit;
  W := FAlphaMask.Width;
  H := FAlphaMask.Height;

  // 1. Kopia w pf24bit do obrotu GDI+, tak jak w ProtRotateAngle
  Src := TBitmap.Create;
  try
    Src.PixelFormat := pf24bit;
    Src.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FAlphaMask.ScanLine[Y];
      DstRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        V := SrcRow[X];
        if V > 127 then V := 255 else V := 0;
        DstRow[X * 3] := V;
        DstRow[X * 3 + 1] := V;
        DstRow[X * 3 + 2] := V;
      end;
    end;

    // 2. Obrót GDI+ — identyczny wzór jak w RotateAndCrop/ProtRotateAngle
    RotBmp := TBitmap.Create;
    try
      RotBmp.PixelFormat := pf24bit;
      RotBmp.SetSize(W, H);

      SrcGP := TGPBitmap.Create(Src.Handle, Src.Palette);
      try
        G := TGPGraphics.Create(RotBmp.Canvas.Handle);
        try
          G.SetInterpolationMode(InterpolationModeHighQualityBilinear);
          G.Clear(MakeColor(255, 0, 0, 0)); // obszar poza obrotem = 0 = przezroczysty (fMain.pas:638)

          RotM := TGPMatrix.Create;
          try
            RotM.RotateAt(AngleDeg, MakePoint(W / 2.0, H / 2.0));
            G.SetTransform(RotM);
            G.DrawImage(SrcGP, 0, 0, W, H);
          finally
            RotM.Free;
          end;
        finally
          G.Free;
        end;
      finally
        SrcGP.Free;
      end;

      // 3. Wpisany prostokąt — ten sam wzór co RotateAndCrop/ProtRotateAngle
      Rad := AngleDeg * Pi / 180.0;
      AbsCos := Abs(Cos(Rad));
      AbsSin := Abs(Sin(Rad));
      Cos2 := Cos(2 * Rad);

      CW := W;
      CH := H;
      CropX := 0;
      CropY := 0;

      if Abs(Cos2) > 0.01 then
      begin
        IW := (W * AbsCos - H * AbsSin) / Cos2;
        IH := (H * AbsCos - W * AbsSin) / Cos2;

        if (IW > W * 0.5) and (IH > H * 0.5) then
        begin
          CropX := Integer(Trunc((W - IW) / 2));
          CropY := Integer(Trunc((H - IH) / 2));
          CW := Min(Integer(Trunc(IW)), W - CropX);
          CH := Min(Integer(Trunc(IH)), H - CropY);
        end;
      end;

      // 4. Przepisanie przyciętego wyniku, powrót do pf8bit 0/255
      NewMask := TBitmap.Create;
      try
        NewMask.PixelFormat := pf8bit;
        NewMask.SetSize(CW, CH);
        for Y := 0 to CH - 1 do
        begin
          SrcRow := RotBmp.ScanLine[CropY + Y];
          DstRow := NewMask.ScanLine[Y];
          for X := 0 to CW - 1 do
          begin
            V := SrcRow[(CropX + X) * 3];
            if V > 127 then DstRow[X] := 255 else DstRow[X] := 0;
          end;
        end;
        FAlphaDirtyRect := Rect(0, 0, CW, CH);
        FAlphaMask.Free;
        FAlphaMask := NewMask;
      except
        NewMask.Free;
        raise;
      end;
    finally
      RotBmp.Free;
    end;
  finally
    Src.Free;
  end;
end;

{ Alpha* dla FAlphaMask. Geometria identyczna jak Prot* dla FProtMask (te same
  indeksy, ten sam nearest-neighbour), z jednym dodatkiem: po kazdej zmianie
  maski caly nowy prostokat dostaje FAlphaDirtyRect. Pozostale wartowniki
  rozmiaru przy renderze koncza cicho, a DrawCheckerRect pomija pusty rect
  (pusty = zero kosztu) - bez tego szachownica zostalaby stara.
  Wewnatrz try przypisanie FAlphaMask musi byc OSTATNIE: cokolwiek po nim
  rzucajace daloby wyjatkiem juz z przypisana nowa bitmapa, a except zwolnilby
  ja drugi raz. }
procedure TfrmMain.AlphaRotateLeft;
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow: PByte;
  New: TBitmap;
begin
  if FAlphaMask = nil then Exit;
  W := FAlphaMask.Width;
  H := FAlphaMask.Height;
  Src := FAlphaMask;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(H, W);
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      for X := 0 to W - 1 do
        PByte(New.ScanLine[W - 1 - X])[Y] := SrcRow[X];
    end;
    FAlphaDirtyRect := Rect(0, 0, H, W);
    FAlphaMask.Free;
    FAlphaMask := New;
  except
    New.Free;
    raise;
  end;
end;

procedure TfrmMain.AlphaRotateRight;
var
  X, Y, W, H: Integer;
  SrcRow: PByte;
  New: TBitmap;
begin
  if FAlphaMask = nil then Exit;
  W := FAlphaMask.Width;
  H := FAlphaMask.Height;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(H, W);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FAlphaMask.ScanLine[Y];
      for X := 0 to W - 1 do
        PByte(New.ScanLine[X])[H - 1 - Y] := SrcRow[X];
    end;
    FAlphaDirtyRect := Rect(0, 0, H, W);
    FAlphaMask.Free;
    FAlphaMask := New;
  except
    New.Free;
    raise;
  end;
end;

procedure TfrmMain.AlphaRotate180;
var
  Src: TBitmap;
  X, Y, W, H: Integer;
  SrcRow, DstRow: PByte;
begin
  if FAlphaMask = nil then Exit;
  Src := TBitmap.Create;
  try
    Src.Assign(FAlphaMask);
    Src.PixelFormat := pf8bit;
    W := Src.Width;
    H := Src.Height;
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      DstRow := FAlphaMask.ScanLine[H - 1 - Y];
      for X := 0 to W - 1 do
        DstRow[W - 1 - X] := SrcRow[X];
    end;
    FAlphaDirtyRect := Rect(0, 0, W, H);
  finally
    Src.Free;
  end;
end;

procedure TfrmMain.AlphaCrop(const R: TRect);
var
  W, H, Y, X: Integer;
  New: TBitmap;
  SrcRow, DstRow: PByte;
begin
  if FAlphaMask = nil then Exit;
  W := R.Right - R.Left + 1;
  H := R.Bottom - R.Top + 1;
  if (W < 1) or (H < 1) then Exit;
  if (R.Left < 0) or (R.Top < 0) or
     (R.Right >= FAlphaMask.Width) or (R.Bottom >= FAlphaMask.Height) then Exit;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      SrcRow := FAlphaMask.ScanLine[R.Top + Y];
      DstRow := New.ScanLine[Y];
      for X := 0 to W - 1 do
        DstRow[X] := SrcRow[R.Left + X];
    end;
    FAlphaDirtyRect := Rect(0, 0, W, H);
    FAlphaMask.Free;
    FAlphaMask := New;
  except
    New.Free;
    raise;
  end;
end;

procedure TfrmMain.AlphaResize(NewW, NewH: Integer);
var
  Src: TBitmap;
  W, H, Y, X, SX, SY: Integer;
  New: TBitmap;
  SrcRow, DstRow: PByte;
begin
  if FAlphaMask = nil then Exit;
  if (NewW < 1) or (NewH < 1) then Exit;
  if (NewW = FAlphaMask.Width) and (NewH = FAlphaMask.Height) then Exit;
  Src := FAlphaMask;
  W := Src.Width;
  H := Src.Height;
  New := TBitmap.Create;
  try
    New.PixelFormat := pf8bit;
    New.SetSize(NewW, NewH);
    for Y := 0 to NewH - 1 do
    begin
      SY := Y * H div NewH;
      SrcRow := Src.ScanLine[SY];
      DstRow := New.ScanLine[Y];
      for X := 0 to NewW - 1 do
      begin
        SX := X * W div NewW;
        DstRow[X] := SrcRow[SX];
      end;
    end;
    FAlphaDirtyRect := Rect(0, 0, NewW, NewH);
    FAlphaMask.Free;
    FAlphaMask := New;
  except
    New.Free;
    raise;
  end;
end;

{ UWAGA - ProtResizeCrop (fMain.pas:6945) musi utrzymywac identyczna geometrie
  z ImageResizeCrop (uTransform.pas:153-159), bo obraz wyznacza
  przeksztalcenie. Obie licza ExcessW/ExcessH i mapuja Corner tak samo - przy
  rozbieznosci maska przestaje dostawac ten sam kadr co obraz. }
procedure TfrmMain.AlphaResizeCrop(TargetW, TargetH, Corner: Integer);
var
  Scale, SW, SH: Double;
  ScaledW, ScaledH, ExcessW, ExcessH, CropX, CropY: Integer;
  New, Scaled: TBitmap;
  W, H, Y, X, SX, SY: Integer;
  SrcRow, DstRow: PByte;
begin
  if FAlphaMask = nil then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;
  W := FAlphaMask.Width;
  H := FAlphaMask.Height;
  if (W = 0) or (H = 0) then Exit;
  SW := TargetW / W;
  SH := TargetH / H;
  if SW > SH then Scale := SW else Scale := SH;
  ScaledW := Max(1, Round(W * Scale));
  ScaledH := Max(1, Round(H * Scale));
  ExcessW := ScaledW - TargetW;
  ExcessH := ScaledH - TargetH;
  case Corner of
    0: begin CropX := 0;       CropY := 0;       end;
    1: begin CropX := ExcessW; CropY := 0;       end;
    2: begin CropX := 0;       CropY := ExcessH; end;
  else
    begin CropX := ExcessW;   CropY := ExcessH; end;
  end;
  if CropX < 0 then CropX := 0;
  if CropY < 0 then CropY := 0;
  Scaled := TBitmap.Create;
  try
    Scaled.PixelFormat := pf8bit;
    Scaled.SetSize(ScaledW, ScaledH);
    for Y := 0 to ScaledH - 1 do
    begin
      SY := Y * H div ScaledH;
      SrcRow := FAlphaMask.ScanLine[SY];
      DstRow := Scaled.ScanLine[Y];
      for X := 0 to ScaledW - 1 do
      begin
        SX := X * W div ScaledW;
        DstRow[X] := SrcRow[SX];
      end;
    end;
    New := TBitmap.Create;
    try
      New.PixelFormat := pf8bit;
      New.SetSize(TargetW, TargetH);
      for Y := 0 to TargetH - 1 do
      begin
        SrcRow := Scaled.ScanLine[CropY + Y];
        Move((SrcRow + CropX)^, New.ScanLine[Y]^, TargetW);
      end;
      FAlphaDirtyRect := Rect(0, 0, TargetW, TargetH);
      FAlphaMask.Free;
      FAlphaMask := New;
    except
      New.Free;
      raise;
    end;
  finally
    Scaled.Free;
  end;
end;

{ Jedyna brama dla "FBitmap ma teraz inny rozmiar". Wywolywana JAWNIE z kazdego
  miejsca, ktore realnie zmienia wymiary - obrot 90 (zamiana osi), kadrowanie,
  resize, resize z przycieciem, prostowanie skanu, makro.
  Celowo NIE w FinishEffect: maska potrzebuje kata/geometrii, ktore zna tylko
  miejsce wywolania, a FinishEffect dostaje tylko nazwe operacji i czas.
  Dlatego wrappery Prot*/Alpha* stoją obok wywolan, a ta funkcja zamyka wylacznie
  to, co wspolne: przeliczenie zoomu i geometrii PaintBox.
  Uwaga: ROT180 i FLIP sa tu swiadomie pominiete - nie zmieniaja wymiarow
  (podwojna zamiana osi / odbicie), a UpdateZoomFit zresetowalby zoom,
  ktorego uzytkownik nie zmienial. Maske i tak odswieza FinishEffect. }
procedure TfrmMain.NotifyBitmapResized;
begin
  UpdateZoomFit;
end;

procedure TfrmMain.DrawTransparencyChecker(Canvas: TCanvas);
begin
  DrawCheckerRect(Canvas, Canvas.ClipRect);
end;

procedure TfrmMain.DrawProtMaskOverlay(Canvas: TCanvas);
var
  Y1, Y2, X1, X2, RunStart: Integer;
  RRect: TRect;
  Y, X: Integer;
  P: PByte;
begin
  if FProtMask = nil then Exit;
  if (FProtMask.Width <> FBitmap.Width) or
     (FProtMask.Height <> FBitmap.Height) then Exit;
  if (FProtDirtyRect.Right <= FProtDirtyRect.Left) or
     (FProtDirtyRect.Bottom <= FProtDirtyRect.Top) then Exit;
  RRect := FProtDirtyRect;

  // Kreskowanie ukośne - wzór maski w Photoshopie. Rysujemy tylko prostokąt
  // otaczający chronione piksele (FProtDirtyRect), nie cały obraz.
  Canvas.Brush.Style := bsBDiagonal;
  Canvas.Brush.Color := clRed;
  Canvas.Pen.Style := psClear;
  Y1 := Trunc(RRect.Top * FZoomFactor);
  Y2 := Trunc((RRect.Bottom) * FZoomFactor);
  for Y := Y1 to Y2 - 1 do
  begin
    P := FProtMask.ScanLine[Trunc(Y / FZoomFactor)];
    X1 := Trunc(RRect.Left * FZoomFactor);
    X2 := Trunc(RRect.Right * FZoomFactor);
    RunStart := -1;
    for X := X1 to X2 - 1 do
    begin
      if P[Trunc(X / FZoomFactor)] <> 0 then
      begin
        if RunStart = -1 then RunStart := X;
      end
      else
      begin
        if RunStart >= 0 then
        begin
          Canvas.FillRect(Rect(RunStart, Y, X, Y + 1));
          RunStart := -1;
        end;
      end;
    end;
    if RunStart >= 0 then
      Canvas.FillRect(Rect(RunStart, Y, X2, Y + 1));
  end;
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsSolid;
end;

procedure TfrmMain.DrawCheckerRect(Canvas: TCanvas; ScreenR: TRect);
var
  ClipR, R: TRect;
  Y, S, H2, X, XEnd, MRunStart: Integer;
  Y1, Y2, X1, X2: Integer;
  P: PByte;
begin
  if FAlphaMask = nil then Exit;
  if (FAlphaMask.Width <> FBitmap.Width) or
     (FAlphaMask.Height <> FBitmap.Height) then Exit;
  // Brak dziur (pusty prostokąt) = zero kosztu.
  if (FAlphaDirtyRect.Right <= FAlphaDirtyRect.Left) or
     (FAlphaDirtyRect.Bottom <= FAlphaDirtyRect.Top) then Exit;

  // Klip do obszaru nieprawidłowego (ClipRect lub rect pierścienia). Maska
  // jest w koordynatach OBRAZU, rect w koordynatach PaintBox. Bez klipu każdy
  // repaint nadpisywał CAŁY skumulowany FAlphaDirtyRect i koszt rósł
  // z powierzchnią wymazywania ("wolna gumka"). +2 to margines zaokrągleń
  // (bezpieczny: nadmiar i tak jest przycinany przez region okna).
  ClipR := ScreenR;
  Y1 := Trunc(ClipR.Top / FZoomFactor);
  if Y1 < 0 then Y1 := 0;
  Y2 := Trunc(ClipR.Bottom / FZoomFactor) + 2;
  if Y2 > FBitmap.Height then Y2 := FBitmap.Height;
  X1 := Trunc(ClipR.Left / FZoomFactor);
  if X1 < 0 then X1 := 0;
  X2 := Trunc(ClipR.Right / FZoomFactor) + 2;
  if X2 > FBitmap.Width then X2 := FBitmap.Width;

  R := FAlphaDirtyRect;
  if R.Left < X1 then R.Left := X1;
  if R.Top < Y1 then R.Top := Y1;
  if R.Right > X2 then R.Right := X2;
  if R.Bottom > Y2 then R.Bottom := Y2;
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;

  Canvas.Brush.Style := bsSolid;
  for Y := R.Top to R.Bottom - 1 do
  begin
    P := FAlphaMask.ScanLine[Y];
    S := Round(Y * FZoomFactor);
    H2 := Round((Y + 1) * FZoomFactor) - S;
    if H2 < 1 then H2 := 1;
    X := R.Left;
    while X < R.Right do
    begin
      while (X < R.Right) and (P[X] <> 0) do Inc(X);
      if X >= R.Right then Break;
      MRunStart := X;
      XEnd := ((X div 8) + 1) * 8;
      if XEnd > R.Right then XEnd := R.Right;
      while (X < XEnd) and (P[X] = 0) do Inc(X);
      if (((MRunStart div 8) + (Y div 8)) mod 2) = 0 then
        Canvas.Brush.Color := clWhite
      else
        Canvas.Brush.Color := clSilver;
      Canvas.FillRect(Rect(
        Round(MRunStart * FZoomFactor), S,
        Round(X * FZoomFactor), S + H2));
    end;
  end;
end;

procedure TfrmMain.UpdateZoomFit;
var
  ZoomX, ZoomY: Double;
begin
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) or
     (ScrollBox.ClientWidth = 0) or (ScrollBox.ClientHeight = 0) then
    Exit;

  ZoomX := ScrollBox.ClientWidth / FBitmap.Width;
  ZoomY := ScrollBox.ClientHeight / FBitmap.Height;
  FZoomFactor := Min(ZoomX, ZoomY);

  if FZoomFactor > 4.0 then
    FZoomFactor := 4.0;

  ScrollBox.HorzScrollBar.Position := 0;
  ScrollBox.VertScrollBar.Position := 0;
  UpdateLayout;
  UpdateStatusBar;
end;

procedure TfrmMain.UpdateZoom(Value: Double);
var
  Vw, Vh, OldW, OldH, NewW, NewH: Integer;
  OffX, OffY, ImgCX, ImgCY: Double;
  TargetX, TargetY: Integer;
begin
  if Value < 0.1 then Value := 0.1;
  if Value > 16.0 then Value := 16.0;
  if Value = FZoomFactor then Exit;

  Vw := ScrollBox.ClientWidth;
  Vh := ScrollBox.ClientHeight;

  // Kotwica jak Hollywood p_ZoomSet (image_zoom.hws:23-44): punkt obrazu w środku
  // viewportu przed zmianą zoomu zostaje w środku po zmianie.
  OldW := Round(FBitmap.Width * FZoomFactor);
  OldH := Round(FBitmap.Height * FZoomFactor);
  OffX := Max(0, (Vw - OldW) div 2);
  OffY := Max(0, (Vh - OldH) div 2);
  ImgCX := (ScrollBox.HorzScrollBar.Position + Vw / 2 - OffX) / FZoomFactor;
  ImgCY := (ScrollBox.VertScrollBar.Position + Vh / 2 - OffY) / FZoomFactor;

  FZoomFactor := Value;

  NewW := Round(FBitmap.Width * FZoomFactor);
  NewH := Round(FBitmap.Height * FZoomFactor);
  TargetX := Round(ImgCX * FZoomFactor - Vw / 2);
  TargetY := Round(ImgCY * FZoomFactor - Vh / 2);
  if TargetX < 0 then TargetX := 0;
  if TargetY < 0 then TargetY := 0;
  if TargetX > Max(0, NewW - Vw) then TargetX := Max(0, NewW - Vw);
  if TargetY > Max(0, NewH - Vh) then TargetY := Max(0, NewH - Vh);

  ScrollBox.HorzScrollBar.Position := TargetX;
  ScrollBox.VertScrollBar.Position := TargetY;

  UpdateLayout;
  UpdateStatusBar;
end;

procedure TfrmMain.InvalidatePaintRect(R: TRect);
begin
  // PaintBox to TGraphicControl (TPaintBox) - nie ma własnego Handle (HWND).
  // Unieważniamy fragment okna rodzica (ScrollBox: TWinControl), przesuwając
  // prostokąt o bieżącą pozycję PaintBox w obrębie ScrollBox.
  System.Types.OffsetRect(R, PaintBox.Left, PaintBox.Top);
  InvalidateRect(ScrollBox.Handle, @R, False);
end;

procedure TfrmMain.UpdateLayout;
var
  DispW, DispH, Vw, Vh, Left, Top: Integer;
begin
  // Zmiana układu (zoom/przewijanie/rozmiar) przestawia obraz — pierścień
  // gumki w starych współrzędnych byłby nieaktualny. Restaurujemy jego tło
  // i gasimy kursor do następnego ruchu myszy.
  if FBrushCursorOn then
  begin
    RedrawRingBackdrop(FBrushCursorRect);
    FBrushCursorOn := False;
  end;
  if (FBitmap.Width = 0) or (FBitmap.Height = 0) then
  begin
    PaintBox.SetBounds(0, 0, 0, 0);
    ScrollBox.Invalidate;
    Exit;
  end;

  DispW := Round(FBitmap.Width * FZoomFactor);
  DispH := Round(FBitmap.Height * FZoomFactor);
  if (DispW < 1) or (DispH < 1) then
  begin
    PaintBox.SetBounds(0, 0, 0, 0);
    ScrollBox.Invalidate;
    Exit;
  end;

  Vw := ScrollBox.ClientWidth;
  Vh := ScrollBox.ClientHeight;

  // Obraz mniejszy od viewportu = wyśrodkowany; większy = od (0,0) + suwaki.
  if DispW < Vw then Left := (Vw - DispW) div 2 else Left := 0;
  if DispH < Vh then Top := (Vh - DispH) div 2 else Top := 0;

  if (DispW <= Vw) and (ScrollBox.HorzScrollBar.Position <> 0) then
    ScrollBox.HorzScrollBar.Position := 0;
  if (DispH <= Vh) and (ScrollBox.VertScrollBar.Position <> 0) then
    ScrollBox.VertScrollBar.Position := 0;

  PaintBox.SetBounds(Left, Top, DispW, DispH);
  PaintBox.Invalidate;
end;

procedure TfrmMain.StatusBarHint(Sender: TObject);
begin
  if StatusBar.Panels.Count > 5 then
    StatusBar.Panels[5].Text := Application.Hint;
end;

procedure TfrmMain.UpdateStatusBar(const OpName: string = ''; ExecutionTimeSec: Double = 0);
var
  ZoomPct: Integer;
  SizeStr: string;
  FormatStr: string;
begin
  if FBitmap.Width > 0 then
  begin
    SizeStr := Format('%d x %d px', [FBitmap.Width, FBitmap.Height]);
    ZoomPct := Round(FZoomFactor * 100);
    FormatStr := Format('%d-bit', [PixelFormatBits(FBitmap.PixelFormat)]);

    StatusBar.Panels[0].Text := ExtractFileName(FFilePath);
    StatusBar.Panels[1].Text := SizeStr;
    StatusBar.Panels[2].Text := FormatStr;
    StatusBar.Panels[3].Text := Format('%d%%', [ZoomPct]);

    if FSelection.Active and (FSelection.W > 0) and (FSelection.H > 0) then
      StatusBar.Panels[4].Text := Format(T('Selection: %d x %d'), [Round(FSelection.W), Round(FSelection.H)])
    else
      StatusBar.Panels[4].Text := '';
  end
  else
  begin
    StatusBar.Panels[0].Text := T('No image loaded.');
    StatusBar.Panels[1].Text := '';
    StatusBar.Panels[2].Text := '';
    StatusBar.Panels[3].Text := '';
    StatusBar.Panels[4].Text := '';
  end;

  // Jeśli przekazano parametr, aktualizujemy panel 6.
  // Jeśli nie - NIE ruszamy panelu 6, żeby nie wymazywać informacji o ostatniej operacji!
  if OpName <> '' then
    SetOperationInfo(OpName, ExecutionTimeSec);
end;

procedure TfrmMain.UpdateCaption;
var
  Marker: string;
begin
  if FDirty then Marker := ' *' else Marker := '';
  if MacroRecorder.IsActive then Marker := Marker + ' [NAGRYWANIE]';
  if FFilePath <> '' then
    Caption := ExtractFileName(FFilePath) + Marker + ' - Fotografista'
  else
    Caption := T('(new)') + Marker + ' - Fotografista';
end;

procedure TfrmMain.UpdateMenuState;
var
  HasImage: Boolean;
  I, J: Integer;
  M: TMenuItem;
begin
  HasImage := (FBitmap <> nil) and (FBitmap.Width > 0);

  if HasImage then
  begin
    for I := 0 to MainMenu.Items.Count - 1 do
      MainMenu.Items[I].Enabled := True;
    for I := 0 to MainMenu.Items.Count - 1 do
      for J := 0 to MainMenu.Items[I].Count - 1 do
        MainMenu.Items[I].Items[J].Enabled := True;
    for J := 0 to mnuFile.Count - 1 do
      if mnuFile.Items[J].Tag = -1 then
        mnuFile.Items[J].Enabled := False;
    UpdateMacroMenu;
  end
  else
  begin
    for I := 0 to MainMenu.Items.Count - 1 do
    begin
      M := MainMenu.Items[I];
      if (M = mnuFile) or (M = mnuEdit) or (M = mnuMacro) or
         (M = mnuSettings) or (M = mnuHelp) then
        Continue;
      for J := 0 to M.Count - 1 do
        M.Items[J].Enabled := False;
    end;

    mnuFileSaveAs.Enabled := False;
    mnuFileExportPDF.Enabled := False;
    mnuFileExportComparison.Enabled := False;
    mnuFileInfo.Enabled := False;
    mnuFileClose.Enabled := False;
    mnuFileExit.Enabled := False;

    for I := 0 to mnuEdit.Count - 1 do
      mnuEdit.Items[I].Enabled := False;
    mnuEditPaste.Enabled := True;

    for I := 0 to mnuMacro.Count - 1 do
      mnuMacro.Items[I].Enabled := False;
    mnuBatch.Enabled := True;
    mnuTimelapse.Enabled := True;

    mnuSettings.Enabled := True;
    mnuHelp.Enabled := True;
  end;
end;

procedure TfrmMain.FinishEffect(const OpName: string; Seconds: Double);
begin
  if MacroRecorder.IsActive then
  begin
    if gMacroPending.Code = '' then
    begin
      gMacroPending.Code := MacroCodeForOpName(OpName);
      if gMacroPending.Code <> '' then
        gMacroPending.Params := '';
    end;
    if gMacroPending.Code <> '' then
    begin
      if MessageDlg(Format(T('Add "%s" to macro?'), [MacroStepLabel(gMacroPending.Code)]),
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        MacroRecorder.Capture(gMacroPending.Code, gMacroPending.Params);
    end;
  end;
  gMacroPending.Code := '';
  gMacroPending.Params := '';
  FDirty := True;
  UpdateCaption;
  // Kolejność WAŻNA: FinishEffect czyści FRasterPreview. Handler efektów rastrowych
  // (Riso V1/V2/V3, Sitodruk, Nadruk) ustawia FRasterPreview := True DOPIERO PO tym
  // wywołaniu — inaczej flaga byłaby skasowana natychmiast. Nie zmieniać kolejności
  // ani nie przenosić czyszczenia (repaint jest asynchroniczny, WM_PAINT — brak okna).
  FRasterPreview := False;
  InvalidatePreviewCache;
  PaintBox.Invalidate;
  SetOperationInfo(OpName, Seconds);
end;

procedure TfrmMain.SetOperationInfo(const OpName: string; Seconds: Double);
begin
  if StatusBar.Panels.Count > 6 then
  begin
    if (OpName <> '') and (Seconds > 0) then
      StatusBar.Panels[6].Text := Format('%s: %.3f s', [OpName, Seconds])
    else
      StatusBar.Panels[6].Text := OpName;
  end;
end;

end.
