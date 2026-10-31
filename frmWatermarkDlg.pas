unit frmWatermarkDlg;

// Okno Znaku wodnego (2026-10-27): kontrolki w kolumnie z lewej, podglad z
// prawej. Uklad liczony w RefitButtons (otwarcie, zmiana czcionki i jezyka),
// odstepy z czcionki. Wielkosc i margines w % krotszego boku, wiec podglad
// 400 px wyglada jak wynik na pelnym zdjeciu.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  System.UITypes,   // inline TFont.GetStyle, MessageDlg (H2443)
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  GR32, uWatermark, uI18n, uTitleBar, uMacros;

type
  TWatermarkDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    rbText: TRadioButton;
    edText: TEdit;
    btnFont: TButton;
    btnColor: TButton;
    chkShadow: TCheckBox;
    rbLogo: TRadioButton;
    btnBrowse: TButton;
    lblLogoFile: TLabel;
    lblPosition: TLabel;
    pnlAnchor: TPanel;
    chkTiled: TCheckBox;
    lblSize: TLabel;
    tbSize: TTrackBar;
    lblSizeVal: TLabel;
    lblMargin: TLabel;
    tbMargin: TTrackBar;
    lblMarginVal: TLabel;
    lblOpacity: TLabel;
    tbOpacity: TTrackBar;
    lblOpacityVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pboxPreviewPaint(Sender: TObject);
    procedure ControlChanged(Sender: TObject);
    procedure btnFontClick(Sender: TObject);
    procedure btnColorClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
  private
    FAnchors: array[0..8] of TRadioButton;
    FOrigPreview, FWorkPreview: TBitmap;
    FLogo: TBitmap32;
    FLogoOK: Boolean;
    FParams: TWatermarkParams;
    FLoading: Boolean;
    procedure SetParams(const P: TWatermarkParams);
    procedure ReadParams;
    procedure UpdateEnabled;
    procedure UpdateValues;
    procedure ApplyPreview;
    procedure UpdateLogoLabel;
  public
    procedure RefitButtons; override;
  end;

// P: ustawienia startowe (z preferencji) i wynik. True = nalozono na Bitmap.
function ShowWatermarkDlg(Bitmap: TBitmap; var P: TWatermarkParams;
  out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

const
  cPreviewMax = 400;

function ShowWatermarkDlg(Bitmap: TBitmap; var P: TWatermarkParams;
  out ElapsedSec: Double): Boolean;
var
  Dlg: TWatermarkDlg;
  Scale: Double;
  PW, PH: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TWatermarkDlg.Create(Application);
  try
    Scale := Min(1.0, Min(cPreviewMax / Bitmap.Width, cPreviewMax / Bitmap.Height));
    PW := Max(1, Round(Bitmap.Width * Scale));
    PH := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FOrigPreview := TBitmap.Create;
    Dlg.FOrigPreview.PixelFormat := pf24bit;
    Dlg.FOrigPreview.SetSize(PW, PH);
    // HALFTONE wprost (Canvas.StretchDraw przestawia na STRETCH_DELETESCANS)
    SetStretchBltMode(Dlg.FOrigPreview.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(Dlg.FOrigPreview.Canvas.Handle, 0, 0, nil);
    Winapi.Windows.StretchBlt(Dlg.FOrigPreview.Canvas.Handle, 0, 0, PW, PH,
      Bitmap.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height, SRCCOPY);
    Dlg.FWorkPreview := TBitmap.Create;
    Dlg.FWorkPreview.PixelFormat := pf24bit;
    Dlg.pboxPreview.SetBounds(0, 0, PW, PH);

    Dlg.SetParams(P);
    if Dlg.ShowModal = mrOk then
    begin
      Dlg.ReadParams;
      SW := TStopwatch.StartNew;
      if DoWatermark(Bitmap, Dlg.FParams, Dlg.FLogo) then
      begin
        P := Dlg.FParams;
        gMacroPending.Code := 'WATERMARK';
        gMacroPending.Params := WatermarkParamsToStr(P);
        Result := True;
      end;
      ElapsedSec := SW.Elapsed.TotalSeconds;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TWatermarkDlg }

procedure TWatermarkDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FLogo := TBitmap32.Create;
  // 9 kotwic: przyciski bez napisow w siatce 3x3 (jeden rodzic = wybor jednego)
  for I := 0 to 8 do
  begin
    FAnchors[I] := TRadioButton.Create(Self);
    FAnchors[I].Parent := pnlAnchor;
    FAnchors[I].Caption := '';
    FAnchors[I].Tag := I;
    FAnchors[I].OnClick := ControlChanged;
  end;
  tbSize.Min := cWmSizeMin;
  tbSize.Max := cWmSizeMax;
  tbMargin.Min := cWmMarginMin;
  tbMargin.Max := cWmMarginMax;
  tbOpacity.Min := cWmOpacityMin;
  tbOpacity.Max := cWmOpacityMax;
end;

procedure TWatermarkDlg.FormDestroy(Sender: TObject);
begin
  FOrigPreview.Free;
  FWorkPreview.Free;
  FLogo.Free;
end;

procedure TWatermarkDlg.SetParams(const P: TWatermarkParams);
begin
  FLoading := True;
  try
    FParams := P;
    rbText.Checked := P.Kind = wkText;
    rbLogo.Checked := P.Kind = wkLogo;
    edText.Text := P.Text;
    chkShadow.Checked := P.Shadow;
    FAnchors[EnsureRange(P.Anchor, 0, 8)].Checked := True;
    chkTiled.Checked := P.Tiled;
    tbSize.Position := P.SizePct;
    tbMargin.Position := P.MarginPct;
    tbOpacity.Position := P.Opacity;
    FLogoOK := LoadWatermarkLogo(P.LogoPath, FLogo);
    UpdateLogoLabel;
  finally
    FLoading := False;
  end;
  UpdateValues;
  UpdateEnabled;
  ApplyPreview;
end;

procedure TWatermarkDlg.ReadParams;
var
  I: Integer;
begin
  if rbLogo.Checked then FParams.Kind := wkLogo else FParams.Kind := wkText;
  FParams.Text := edText.Text;
  FParams.Shadow := chkShadow.Checked;
  for I := 0 to 8 do
    if FAnchors[I].Checked then FParams.Anchor := I;
  FParams.Tiled := chkTiled.Checked;
  FParams.SizePct := tbSize.Position;
  FParams.MarginPct := tbMargin.Position;
  FParams.Opacity := tbOpacity.Position;
end;

procedure TWatermarkDlg.UpdateEnabled;
var
  IsText: Boolean;
  I: Integer;
begin
  IsText := rbText.Checked;
  edText.Enabled := IsText;
  btnFont.Enabled := IsText;
  btnColor.Enabled := IsText;
  chkShadow.Enabled := IsText;
  btnBrowse.Enabled := not IsText;
  lblLogoFile.Enabled := not IsText;
  // powielony znak nie ma kotwicy
  for I := 0 to 8 do
    FAnchors[I].Enabled := not chkTiled.Checked;
  btnOK.Enabled := (IsText and (Trim(edText.Text) <> '')) or (not IsText and FLogoOK);
end;

procedure TWatermarkDlg.UpdateValues;
begin
  lblSizeVal.Caption := IntToStr(tbSize.Position) + '%';
  lblMarginVal.Caption := IntToStr(tbMargin.Position) + '%';
  lblOpacityVal.Caption := IntToStr(tbOpacity.Position) + '%';
end;

procedure TWatermarkDlg.UpdateLogoLabel;
begin
  if FLogoOK then
    lblLogoFile.Caption := ExtractFileName(FParams.LogoPath)
  else
    lblLogoFile.Caption := '';
end;

procedure TWatermarkDlg.ControlChanged(Sender: TObject);
begin
  if FLoading then Exit;
  UpdateValues;
  UpdateEnabled;
  ApplyPreview;
end;

procedure TWatermarkDlg.ApplyPreview;
begin
  if (FOrigPreview = nil) or (FWorkPreview = nil) then Exit;
  ReadParams;
  FWorkPreview.Assign(FOrigPreview);
  FWorkPreview.PixelFormat := pf24bit;
  DoWatermark(FWorkPreview, FParams, FLogo);
  pboxPreview.Invalidate;
end;

procedure TWatermarkDlg.pboxPreviewPaint(Sender: TObject);
begin
  if FWorkPreview <> nil then
    pboxPreview.Canvas.Draw(0, 0, FWorkPreview);
end;

procedure TWatermarkDlg.btnFontClick(Sender: TObject);
var
  D: TFontDialog;
begin
  D := TFontDialog.Create(nil);
  try
    D.Font.Name := FParams.FontName;
    if FParams.Bold then D.Font.Style := [fsBold] else D.Font.Style := [];
    D.Options := D.Options - [fdEffects];
    if D.Execute(Handle) then
    begin
      FParams.FontName := D.Font.Name;
      FParams.Bold := fsBold in D.Font.Style;
      ApplyPreview;
    end;
  finally
    D.Free;
  end;
end;

procedure TWatermarkDlg.btnColorClick(Sender: TObject);
var
  D: TColorDialog;
begin
  D := TColorDialog.Create(nil);
  try
    D.Color := FParams.Color;
    D.Options := [cdFullOpen];
    if D.Execute(Handle) then
    begin
      FParams.Color := D.Color;
      ApplyPreview;
    end;
  finally
    D.Free;
  end;
end;

procedure TWatermarkDlg.btnBrowseClick(Sender: TObject);
var
  D: TOpenDialog;
begin
  D := TOpenDialog.Create(nil);
  try
    D.Filter := 'PNG|*.png';
    // ofEnableSizing: jak w oknie Otworz (fMain) - stare okno plikow przy motywie VCL
    D.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    if FParams.LogoPath <> '' then
      D.InitialDir := ExtractFilePath(FParams.LogoPath);
    if D.Execute(Handle) then
    begin
      if LoadWatermarkLogo(D.FileName, FLogo) then
      begin
        FParams.LogoPath := D.FileName;
        FLogoOK := True;
        rbLogo.Checked := True;
      end
      else
        MessageDlg(T('The logo file could not be loaded.'), mtError, [mbOK], 0);
      UpdateLogoLabel;
      UpdateEnabled;
      ApplyPreview;
    end;
  finally
    D.Free;
  end;
end;

// Uklad z czcionki: kolumna kontrolek (szerokosc z najdluzszego napisu),
// podglad po prawej, przyciski pod nizszym z nich.
procedure TWatermarkDlg.RefitButtons;
var
  M, TH, Check, ColW, ValW, X, Y, I, Cell, RowH: Integer;

  procedure SliderRow(L: TLabel; TB: TTrackBar; V: TLabel);
  begin
    L.Left := M;
    L.Top := Y;
    Y := StackBelow(L, CtrlGap);
    TB.SetBounds(M, Y, ColW - ValW - CtrlGap, TH + CtrlGap * 2);
    V.AutoSize := False;
    V.Alignment := taRightJustify;
    V.SetBounds(M + ColW - ValW, Y + (TB.Height - TH) div 2, ValW, TH + 2);
    Y := StackBelow(TB, RowGap * 2);
  end;

begin
  inherited;
  M := CtrlGap * 3;
  TH := Canvas.TextHeight('Wg');
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;
  RowH := TH + 4;
  ValW := Canvas.TextWidth('100%') + CtrlGap;
  FitButton(btnFont);
  FitButton(btnColor);
  FitButton(btnBrowse);

  ColW := Canvas.TextWidth('W') * 22;
  ColW := Max(ColW, Canvas.TextWidth(rbText.Caption) + Check);
  ColW := Max(ColW, Canvas.TextWidth(rbLogo.Caption) + Check);
  ColW := Max(ColW, Canvas.TextWidth(chkShadow.Caption) + Check + M);
  ColW := Max(ColW, btnFont.Width + CtrlGap * 2 + btnColor.Width + M);

  Y := M;
  rbText.SetBounds(M, Y, Canvas.TextWidth(rbText.Caption) + Check, RowH);
  Y := StackBelow(rbText, CtrlGap);
  edText.SetBounds(M + M, Y, ColW - M, edText.Height);
  Y := StackBelow(edText, CtrlGap);
  btnFont.Left := M + M;
  btnFont.Top := Y;
  btnColor.Left := btnFont.Left + btnFont.Width + CtrlGap * 2;
  btnColor.Top := Y;
  Y := StackBelow(btnFont, CtrlGap);
  chkShadow.SetBounds(M + M, Y, Canvas.TextWidth(chkShadow.Caption) + Check, RowH);
  Y := StackBelow(chkShadow, SectionGap);

  rbLogo.SetBounds(M, Y, Canvas.TextWidth(rbLogo.Caption) + Check, RowH);
  Y := StackBelow(rbLogo, CtrlGap);
  btnBrowse.Left := M + M;
  btnBrowse.Top := Y;
  lblLogoFile.AutoSize := False;
  lblLogoFile.EllipsisPosition := epPathEllipsis;
  X := btnBrowse.Left + btnBrowse.Width + CtrlGap * 2;
  lblLogoFile.SetBounds(X, Y + (btnBrowse.Height - TH) div 2, Max(1, M + ColW - X), TH + 2);
  Y := StackBelow(btnBrowse, SectionGap);

  SliderRow(lblSize, tbSize, lblSizeVal);
  SliderRow(lblMargin, tbMargin, lblMarginVal);
  SliderRow(lblOpacity, tbOpacity, lblOpacityVal);

  // prawa kolumna: podglad, pod nim Polozenie (wybor miejsca na zdjeciu przy
  // obrazie; obie kolumny podobnej wysokosci - 2026-10-27, wariant D)
  // odstep kolumn poczworny - przy pojedynczym odczyty suwakow (60%) stykaly
  // sie z podgladem, podwojny wciaz za ciasny
  X := M + ColW + M * 4;
  pboxPreview.Left := X;
  pboxPreview.Top := M;
  lblPosition.Left := X;
  lblPosition.Top := StackBelow(pboxPreview, SectionGap);
  Cell := Check + CtrlGap;
  pnlAnchor.BevelOuter := bvNone;
  pnlAnchor.SetBounds(X + M, StackBelow(lblPosition, CtrlGap), Cell * 3, Cell * 3);
  for I := 0 to 8 do
    FAnchors[I].SetBounds((I mod 3) * Cell, (I div 3) * Cell, Check, RowH);
  chkTiled.SetBounds(X, StackBelow(pnlAnchor, CtrlGap),
    Canvas.TextWidth(chkTiled.Caption) + Check, RowH);

  btnOK.Top := Max(Y, StackBelow(chkTiled, SectionGap));
  btnCancel.Top := btnOK.Top;
  btnOK.Left := M;
  btnCancel.Left := btnOK.Left + btnOK.Width + CtrlGap * 2;
  FitToContent(SectionGap, M);
  AlignButtonsRight([btnOK, btnCancel], M);
end;

end.
