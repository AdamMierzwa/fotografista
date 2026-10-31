unit frmLauncherDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types, System.UITypes,
  System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ComCtrls, Vcl.ToolWin,
  Vcl.ExtCtrls, Vcl.Buttons, Vcl.Imaging.pngimage, Vcl.StdCtrls,
  System.Skia, Vcl.ImageCollection, Vcl.VirtualImageList, uTitleBar;

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
    FIconColl: TImageCollection;
    FIconList: TVirtualImageList;
    procedure LoadIcons;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
    procedure FitButtons;
  public
    procedure RefreshZoom;
  end;

implementation

uses
  Vcl.Themes, fMain, uI18n;

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

// TColor (takze kolor systemowy z motywu) -> TAlphaColor dla Skia
function ToAlphaColor(C: TColor): TAlphaColor;
var
  RGBValue: COLORREF;
begin
  RGBValue := ColorToRGB(C);
  Result := $FF000000 or (TAlphaColor(GetRValue(RGBValue)) shl 16) or
    (TAlphaColor(GetGValue(RGBValue)) shl 8) or GetBValue(RGBValue);
end;

// Zwraca TResourceStream dla ikony SVG osadzonej w EXE (launcher_icons.res),
// lub nil gdy zasob nie istnieje. Pamietyc o Free po uzyciu.
function LoadLauncherSvgStream(const AResName: string): TResourceStream;
begin
  if FindResource(HInstance, PChar(AResName), RT_RCDATA) = 0 then
    Exit(nil);
  Result := TResourceStream.Create(HInstance, AResName, RT_RCDATA);
end;

// Renderuje SVG do PNG W x H z PRZEZROCZYSTYM tlem, rysunek przemalowany na
// kolor AFg z zachowanym ksztaltem i wygladzeniem - warstwa z
// TSkColorFilter.MakeBlend(AFg, SrcIn) (System.Skia.pas:1534, SaveLayer :1358).
// Przezroczyste tlo + TVirtualImageList (kanal alfa) = pod ikona tlo, ktore
// rysuje sam motyw paska narzedzi (2026-10-23; wczesniej staly kafelek -
// najpierw $E8E8E8 jak w Hollywood, potem clBtnFace, ktory w czesci stylow
// VCL nie jest kolorem paska). TSkSVGDOM.MakeFromStream + SetContainerSize
// rozwiazuje width="100%" height="100%".
function RenderSvgToPng(const AStream: TStream; W, H: Integer; AFg: TAlphaColor): TBytes;
var
  SVG: ISkSVGDOM;
  Surface: ISkSurface;
  Tint: ISkPaint;
begin
  Result := nil;
  SVG := TSkSVGDOM.MakeFromStream(AStream);
  if SVG = nil then Exit;
  Surface := TSkSurface.MakeRaster(W, H);
  Surface.Canvas.Clear(TAlphaColors.Null);
  SVG.SetContainerSize(TSizeF.Create(W, H));
  Tint := TSkPaint.Create;
  Tint.ColorFilter := TSkColorFilter.MakeBlend(AFg, TSkBlendMode.SrcIn);
  Surface.Canvas.SaveLayer(Tint);
  SVG.Render(Surface.Canvas);
  Surface.Canvas.Restore;
  Surface.Flush;
  Result := Surface.MakeImageSnapshot.Encode(TSkEncodedImageFormat.Png, 100);
end;

{ TLauncherDlg }

procedure TLauncherDlg.FormCreate(Sender: TObject);
begin
  TranslateForm(Self);
  LoadIcons;
  FitButtons;
  RefreshZoom;
end;

// Ikony przez TImageCollection + TVirtualImageList (PNG z kanalem alfa,
// TCustomSpeedButton.Images - Vcl.Buttons.pas:144): przezroczyste tlo, kolor
// rysunku = kolor tekstu przyciskow paska narzedzi w biezacym stylu
// (GetStyleFontColor(sfToolItemTextNormal), Vcl.Themes.pas:1335).
procedure TLauncherDlg.LoadIcons;
var
  Btn: TSpeedButton;
  Stream: TResourceStream;
  Png: TMemoryStream;
  Bytes: TBytes;
  I: Integer;
  Fg: TAlphaColor;
begin
  if FIconColl = nil then
  begin
    FIconColl := TImageCollection.Create(Self);
    FIconList := TVirtualImageList.Create(Self);
    FIconList.ImageCollection := FIconColl;
    FIconList.Width := 24;
    FIconList.Height := 24;
  end;
  FIconList.Clear;
  FIconColl.Images.Clear;
  Fg := ToAlphaColor(StyleServices.GetStyleFontColor(sfToolItemTextNormal));
  for I := 0 to High(LAUNCHER_ICONS) do
  begin
    case I of
      0: Btn := sbOpen;
      1: Btn := sbSave;
      2: Btn := sbCopy;
      3: Btn := sbPaste;
      4: Btn := sbMacro;
    else
      Btn := sbCompare;
    end;
    Stream := LoadLauncherSvgStream(LAUNCHER_ICONS[I]);
    if Stream = nil then Continue;
    try
      Bytes := RenderSvgToPng(Stream, 24, 24, Fg);
    finally
      Stream.Free;
    end;
    if Length(Bytes) = 0 then Continue;
    Png := TMemoryStream.Create;
    try
      Png.WriteBuffer(Bytes[0], Length(Bytes));
      Png.Position := 0;
      FIconColl.Add(LAUNCHER_ICONS[I], Png);
    finally
      Png.Free;
    end;
    FIconList.Add(LAUNCHER_ICONS[I], LAUNCHER_ICONS[I]);
    Btn.Glyph := nil;
    Btn.Images := FIconList;
    Btn.ImageIndex := FIconList.Count - 1;
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
  MaxW, I, ToolW: Integer;
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

    // Ikony z odstepem CtrlGap miedzy rysunkami (2026-10-23): TToolBar uklada
    // przyciski jeden przy drugim, wiec odstep daje szerokosc przycisku
    // (ikona 24 px wysrodkowana). Okno co najmniej na caly pasek - inaczej
    // pasek zawinalby sie do drugiego rzedu.
    for I := 0 to ToolBar.ControlCount - 1 do
      if ToolBar.Controls[I] is TSpeedButton then
        ToolBar.Controls[I].Width := 24 + CtrlGap;
    ToolW := ToolBar.Indent + ToolBar.BorderWidth * 2 + 4;
    for I := 0 to ToolBar.ControlCount - 1 do
      Inc(ToolW, ToolBar.Controls[I].Width);
    ClientWidth := Max(grpZoom.Left + grpZoom.Width + 6, ToolW);

    // ramki na szerokosc okna (ten sam margines co z lewej), przyciski
    // i odczyt zoomu na szerokosc ramki
    grpZoom.Width := ClientWidth - grpZoom.Left - 6;
    grpEdit.Width := grpZoom.Width;
    btnZoomFit.Width := grpZoom.Width - 12 - 8;
    btnUndo.Width := btnZoomFit.Width;
    btnRevert.Width := btnZoomFit.Width;
    btnZoomIn.Left := grpZoom.ClientWidth - 8 - btnZoomIn.Width;
    lblZoom.Left := btnZoomOut.Left + btnZoomOut.Width + CtrlGap;
    lblZoom.Width := btnZoomIn.Left - CtrlGap - lblZoom.Left;
  finally
    Bmp.Free;
  end;
end;

// zmiana motywu (Ustawienia): ikony w nowych kolorach
procedure TLauncherDlg.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  LoadIcons;
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
