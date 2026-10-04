unit frmLauncherDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.Imaging.pngimage, Vcl.StdCtrls,
  System.Skia, uTitleBar;

type
  TLauncherDlg = class(TFotoForm)
    ToolBar: TToolBar;
    sbOpen: TSpeedButton;
    sbSave: TSpeedButton;
    sbCopy: TSpeedButton;
    sbPaste: TSpeedButton;
    sbMacro: TSpeedButton;
    sbCompare: TSpeedButton;
    grpZoom: TGroupBox;
    btnZoomOut: TButton;
    lblZoom: TLabel;
    btnZoomIn: TButton;
    btnZoomFit: TButton;
    grpEdit: TGroupBox;
    btnUndo: TButton;
    btnRevert: TButton;
    Timer: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure sbOpenClick(Sender: TObject);
    procedure sbSaveClick(Sender: TObject);
    procedure sbCopyClick(Sender: TObject);
    procedure sbPasteClick(Sender: TObject);
    procedure sbMacroClick(Sender: TObject);
    procedure sbCompareClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomFitClick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRevertClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FLastFitKey: string;
    procedure LoadIcons;
    procedure FitButtons;
  public
    procedure RefreshZoom;
  end;

implementation

uses
  fMain, uI18n;

{$R *.dfm}

{$R launcher_icons.res}

const
  // Nazwy zasobow RCDATA z launcher_icons.rc (SVG ikon, kompilowane przez
  // brcc32 do launcher_icons.res). Ikony sa czescia aplikacji, nie
  // zewnetrznych assetow - osadzone w EXE jak about_logo.
  LAUNCHER_ICONS: array[0..5] of string = (
    'ICON_FILE_OPEN',
    'ICON_SAVE_AS',
    'ICON_COPY',
    'ICON_PASTE',
    'ICON_MACRO',
    'ICON_COMPARE');

  // Tlo ikon = E8E8E8, dokladnie jak brush w Hollywood p_LoadSvgIcon
  // (events.hws:1042-1047: rasteryzacja na tle $00E8E8E8). OPAQUE tlo
  // gwarantuje, ze ikona zawsze jest widoczna - bez ryzyka znikniecia
  // przy stracie kanalu alfa (PNG -> TBitmap -> SpeedButton.Glyph).
  SVG_BG_COLOR = TAlphaColor($FFE8E8E8);

// Zwraca TResourceStream dla ikony SVG osadzonej w EXE (launcher_icons.res),
// lub nil gdy zasob nie istnieje. Pamietyc o Free po uzyciu.
function LoadLauncherSvgStream(const AResName: string): TResourceStream;
begin
  if FindResource(HInstance, PChar(AResName), RT_RCDATA) = 0 then
    Exit(nil);
  Result := TResourceStream.Create(HInstance, AResName, RT_RCDATA);
end;

// Renderuje SVG do bitmapy 24x24 z OPAQUE tlem E8E8E8. Skia:
// TSkSVGDOM.MakeFromStream + SetContainerSize(24,24) rozwiazuje
// width="100%" height="100%" (odpowiednik rasteryzacji nanosvg
// w Hollywood), render na TSkSurface.MakeRaster, zapis do PNG.
function RenderSvgToBitmap(const AStream: TStream; W, H: Integer): TBitmap;
var
  SVG: ISkSVGDOM;
  Surface: ISkSurface;
  Img: ISkImage;
  Bytes: TBytes;
  Stream: TMemoryStream;
  PNG: TPngImage;
begin
  Result := nil;
  SVG := TSkSVGDOM.MakeFromStream(AStream);
  if SVG = nil then Exit;
  Surface := TSkSurface.MakeRaster(W, H);
  Surface.Canvas.Clear(SVG_BG_COLOR);
  SVG.SetContainerSize(TSizeF.Create(W, H));
  SVG.Render(Surface.Canvas);
  Surface.Flush;
  Img := Surface.MakeImageSnapshot;
  Bytes := Img.Encode(TSkEncodedImageFormat.Png, 100);
  if Length(Bytes) = 0 then Exit;
  Stream := TMemoryStream.Create;
  try
    Stream.Write(Bytes[0], Length(Bytes));
    Stream.Position := 0;
    PNG := TPngImage.Create;
    try
      PNG.LoadFromStream(Stream);
      Result := TBitmap.Create;
      Result.Assign(PNG);
    finally
      PNG.Free;
    end;
  finally
    Stream.Free;
  end;
end;

{ TLauncherDlg }

procedure TLauncherDlg.FormCreate(Sender: TObject);
begin
  TranslateForm(Self);
  LoadIcons;
  FitButtons;
  RefreshZoom;
end;

procedure TLauncherDlg.LoadIcons;
var
  Bmp: TBitmap;
  Btn: TSpeedButton;
  Stream: TResourceStream;
  I: Integer;
begin
  for I := 0 to High(LAUNCHER_ICONS) do
  begin
    Stream := LoadLauncherSvgStream(LAUNCHER_ICONS[I]);
    if Stream = nil then Continue;
    try
      Bmp := RenderSvgToBitmap(Stream, 24, 24);
    finally
      Stream.Free;
    end;
    if Bmp = nil then Continue;
    try
      case I of
        0: Btn := sbOpen;
        1: Btn := sbSave;
        2: Btn := sbCopy;
        3: Btn := sbPaste;
        4: Btn := sbMacro;
      else
        Btn := sbCompare;
      end;
      Btn.Glyph := Bmp;   // TSpeedButton.Glyph kopiuje bitmape (Assign)
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TLauncherDlg.RefreshZoom;
var
  Txt: string;
begin
  Txt := '';
  if (frmMain <> nil) and (frmMain.StatusBar.Panels.Count > 3) then
    Txt := frmMain.StatusBar.Panels[3].Text;
  if Txt = '' then Txt := '-';
  if lblZoom.Caption <> Txt then
    lblZoom.Caption := Txt;
end;

procedure TLauncherDlg.TimerTimer(Sender: TObject);
begin
  RefreshZoom;
  FitButtons;
end;

// Dopasowuje szerokosc przyciskow do najdluzszego tlumaczonego tekstu.
// Wzorca z frmShortcutsDlg (Canvas.TextWidth). Re-fit odpala sie co 250ms
// (Timer), wiec po zmianie jezyka (SetLanguage -> TranslateForm na wszystkich
// formach) przyciski same sie dostosuja. Zachowane minimalne szerokosci z dfm.
// Szerokosc grupy liczona jako 4 px ramki (TCustomGroupBox.AdjustClientRect
// wykonuje dwa InflateRect(-1,-1), wiec ClientWidth = Width - 4) + 8 px
// marginesu wewnetrznego + szerokosc najszerszego przycisku + 8 px marginesu.
// Bez tych 4 px prawy margines wychodzil 4 px zamiast 8.
procedure TLauncherDlg.FitButtons;
var
  Bmp: TBitmap;
  Btn: TButton;
  MaxW, I: Integer;
  Key: string;
begin
  Key := btnZoomFit.Caption + #1 + btnUndo.Caption + #1 + btnRevert.Caption;
  if Key = FLastFitKey then Exit;
  FLastFitKey := Key;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font := btnZoomFit.Font;
    MaxW := 0;
    for I := 0 to 2 do
    begin
      case I of
        0: Btn := btnZoomFit;
        1: Btn := btnUndo;
      else
        Btn := btnRevert;
      end;
      MaxW := Max(MaxW, Bmp.Canvas.TextWidth(Btn.Caption) + 24);
    end;
    btnZoomFit.Width := MaxW;
    btnUndo.Width := MaxW;
    btnRevert.Width := MaxW;
    grpZoom.Width := 12 + btnZoomFit.Width + 8;
    grpEdit.Width := 12 + btnUndo.Width + 8;
    btnZoomIn.Left := grpZoom.ClientWidth - 8 - btnZoomIn.Width;
    ClientWidth := grpZoom.Left + grpZoom.Width + 6;
  finally
    Bmp.Free;
  end;
end;

procedure TLauncherDlg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TLauncherDlg.sbOpenClick(Sender: TObject);
begin
  frmMain.mnuFileOpenClick(Self);
end;

procedure TLauncherDlg.sbSaveClick(Sender: TObject);
begin
  frmMain.mnuFileSaveAsClick(Self);
end;

procedure TLauncherDlg.sbCopyClick(Sender: TObject);
begin
  frmMain.mnuEditCopyClick(Self);
end;

procedure TLauncherDlg.sbPasteClick(Sender: TObject);
begin
  frmMain.mnuEditPasteClick(Self);
end;

procedure TLauncherDlg.sbMacroClick(Sender: TObject);
begin
  frmMain.mnuMacroManageClick(Self);
end;

procedure TLauncherDlg.sbCompareClick(Sender: TObject);
begin
  frmMain.mnuFileExportComparisonClick(Self);
end;

procedure TLauncherDlg.btnZoomOutClick(Sender: TObject);
begin
  frmMain.mnuViewZoomOutClick(Self);
end;

procedure TLauncherDlg.btnZoomInClick(Sender: TObject);
begin
  frmMain.mnuViewZoomInClick(Self);
end;

procedure TLauncherDlg.btnZoomFitClick(Sender: TObject);
begin
  frmMain.mnuViewFitClick(Self);
end;

procedure TLauncherDlg.btnUndoClick(Sender: TObject);
begin
  frmMain.mnuEditUndoClick(Self);
end;

procedure TLauncherDlg.btnRevertClick(Sender: TObject);
begin
  frmMain.mnuEditRevertClick(Self);
end;

end.
