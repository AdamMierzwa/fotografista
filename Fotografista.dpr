program Fotografista;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {frmMain},
  uImageIO in 'uImageIO.pas',
  uPrefs in 'uPrefs.pas',
  frmInterfaceDlg in 'frmInterfaceDlg.pas' {InterfaceDlg},
  frmFileInfoDlg in 'frmFileInfoDlg.pas' {frmFileInfo},
  frmQualityDlg in 'frmQualityDlg.pas' {QualityDlg},
  frmPerformanceDlg in 'frmPerformanceDlg.pas' {PerformanceDlg},
  uTransform in 'uTransform.pas',
  uMediaFoundation in 'uMediaFoundation.pas',
  uVideoWriter in 'uVideoWriter.pas',
  frmStraightenDlg in 'frmStraightenDlg.pas' {StraightenDlg},
  frmPerspectiveDlg in 'frmPerspectiveDlg.pas' {PerspectiveDlg},
  uUndo in 'uUndo.pas',
  frmHistogramDlg in 'frmHistogramDlg.pas' {HistogramDlg},
  frmContrastDlg in 'frmContrastDlg.pas' {ContrastDlg},
  frmCmykDlg in 'frmCmykDlg.pas' {CmykDlg},
  frmLinocutDlg in 'frmLinocutDlg.pas' {LinocutDlg},
  frmStencilDlg in 'frmStencilDlg.pas' {StencilDlg},
  frmEngravingDlg in 'frmEngravingDlg.pas' {EngravingDlg},
  frmCrosshatchDlg in 'frmCrosshatchDlg.pas' {CrosshatchDlg},
  frmHalftoneDlg in 'frmHalftoneDlg.pas' {HalftoneDlg},
  frmStippleDlg in 'frmStippleDlg.pas' {StippleDlg},
  frmDiceDlg in 'frmDiceDlg.pas' {DiceDlg},
  frmScreenPrintDlg in 'frmScreenPrintDlg.pas' {ScreenPrintDlg},
  frmRastrCmykDlg in 'frmRastrCmykDlg.pas' {RastrCmykDlg},
  uRastrCMYK in 'uRastrCMYK.pas',
  frmBatchDlg in 'frmBatchDlg.pas' {BatchDlg},
  frmTimelapseDlg in 'frmTimelapseDlg.pas' {TimelapseDlg},
  frmLauncherDlg in 'frmLauncherDlg.pas' {LauncherDlg},
  frmToolsDlg in 'frmToolsDlg.pas' {ToolsDlg},
  frmSelDlg in 'frmSelDlg.pas' {SelDlg},
  frmUsunTloDlg in 'frmUsunTloDlg.pas' {UsunTloDlg},
  uCanvasTools in 'uCanvasTools.pas',
  frmShortcutsDlg in 'frmShortcutsDlg.pas' {ShortcutsDlg},
  uQuantize in 'uQuantize.pas',
  uRiso in 'uRiso.pas',
  uPixelEngine in 'uPixelEngine.pas',
  uMipMap in 'uMipMap.pas',
  uMacros in 'uMacros.pas',
  frmRisoDlg in 'frmRisoDlg.pas' {RisoDlg},
  frmRisoV3Dlg in 'frmRisoV3Dlg.pas' {RisoV3Dlg},
  uTshirt in 'uTshirt.pas',
  frmTshirtDlg in 'frmTshirtDlg.pas' {TshirtDlg},
  frmBrightnessDlg in 'frmBrightnessDlg.pas' {BrightnessDlg},
  frmGammaDlg in 'frmGammaDlg.pas' {GammaDlg},
  frmLevelsDlg in 'frmLevelsDlg.pas' {LevelsDlg},
  frmWBDlg in 'frmWBDlg.pas' {WBDlg},
  frmHSBDlg in 'frmHSBDlg.pas' {HSBDlg},
  frmKolorowanieDlg in 'frmKolorowanieDlg.pas' {KolorowanieDlg},
  frmSharpenDlg in 'frmSharpenDlg.pas' {SharpenDlg},
  uDuotone in 'uDuotone.pas',
  frmDuotoneDlg in 'frmDuotoneDlg.pas' {DuotoneDlg},
  frmSepiaDlg in 'frmSepiaDlg.pas' {SepiaDlg},
  AboutBoxUnit in 'AboutBoxUnit.pas' {frmAbout},
  uI18n in 'uI18n.pas',
  frmLanguageDlg in 'frmLanguageDlg.pas' {LanguageDlg},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  LoadPrefs;
  Application.DefaultFont.Size := Application.DefaultFont.Size + Prefs.UIFontSize;
  Screen.MenuFont.Size := Screen.MenuFont.Size + Prefs.UIFontSize;
  Application.Title := 'Fotografista';
  Application.CreateForm(TfrmMain, frmMain);
  if Prefs.Language >= 0 then
    SetLanguage(TLanguage(Prefs.Language))
  else
    SetLanguage(DetectLanguage);
  Application.Run;
end.
