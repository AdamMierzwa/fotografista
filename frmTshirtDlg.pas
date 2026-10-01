unit frmTshirtDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTshirt, uI18n, uTitleBar;

type
  TTshirtDlg = class(TFotoForm)
    grpStage1: TGroupBox;
    grpStage2: TGroupBox;
    grpStage3: TGroupBox;
    grpStage4: TGroupBox;
    lblColors: TLabel;
    cmbColors: TComboBox;
    swInk0: TShape;
    lblPal0: TLabel;
    btnInk0: TButton;
    lblInk0: TLabel;
    swInk1: TShape;
    lblPal1: TLabel;
    btnInk1: TButton;
    lblInk1: TLabel;
    swInk2: TShape;
    lblPal2: TLabel;
    btnInk2: TButton;
    lblInk2: TLabel;
    swInk3: TShape;
    lblPal3: TLabel;
    btnInk3: TButton;
    lblInk3: TLabel;
    swInk4: TShape;
    lblPal4: TLabel;
    btnInk4: TButton;
    lblInk4: TLabel;
    swInk5: TShape;
    lblPal5: TLabel;
    btnInk5: TButton;
    lblInk5: TLabel;
    lblMinArea: TLabel;
    tbMinArea: TTrackBar;
    lblMinVal: TLabel;
    chkRaster: TCheckBox;
    lblCellMult: TLabel;
    tbCellMult: TTrackBar;
    lblCellMultVal: TLabel;
    lblCleanCount: TLabel;
    pboxPreview: TPaintBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure cmbColorsChange(Sender: TObject);
    procedure btnInk0Click(Sender: TObject);
    procedure btnInk1Click(Sender: TObject);
    procedure btnInk2Click(Sender: TObject);
    procedure btnInk3Click(Sender: TObject);
    procedure btnInk4Click(Sender: TObject);
    procedure btnInk5Click(Sender: TObject);
    procedure tbMinAreaChange(Sender: TObject);
    procedure chkRasterClick(Sender: TObject);
    procedure tbCellMultChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FInks: TShirtColors;
    procedure EnsureInks(N: Integer);
    procedure RunPreview(Bitmap: TBitmap);
    procedure UpdateMapping;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure LayoutDialog(pw, ph: Integer);
    function GetCellMultValue: Double;
  end;

function ShowTshirtDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowTshirtDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TTshirtDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TTshirtDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Scaled := TBitmap.Create;
    try
      Scaled.PixelFormat := pf24bit;
      Scaled.SetSize(pw, ph);
      Scaled.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

      Dlg.FOriginalPreview := TBitmap.Create;
      Dlg.FOriginalPreview.PixelFormat := pf24bit;
      Dlg.FOriginalPreview.SetSize(pw, ph);
      Dlg.FOriginalPreview.Canvas.Draw(0, 0, Scaled);

      Dlg.FWorkingPreview := TBitmap.Create;
      Dlg.FWorkingPreview.PixelFormat := pf24bit;
      Dlg.FWorkingPreview.SetSize(pw, ph);
    finally
      Scaled.Free;
    end;

    Dlg.LayoutDialog(pw, ph);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TTshirtDlg }

procedure TTshirtDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  DoubleBuffered := True;
  cmbColors.Items.Add('2');
  cmbColors.Items.Add('3');
  cmbColors.Items.Add('4');
  cmbColors.Items.Add('5');
  cmbColors.Items.Add('6');
  cmbColors.ItemIndex := 0;

  tbMinArea.Min := 0;
  tbMinArea.Max := 50;
  tbMinArea.Position := 0;
  lblMinVal.Caption := IntToStr(tbMinArea.Position);

  tbCellMult.Min := 1;
  tbCellMult.Max := 16; // krok = 0.25: 1..16 -> 0.25..4.0 (pozycja 4 = 1.0)
  tbCellMult.Position := 4;
  lblCellMultVal.Caption := FormatFloat('0.00×', GetCellMultValue);
  tbCellMult.Enabled := chkRaster.Checked;

    lblCleanCount.Caption := T('Islands removed:') + ' 0';

  for I := 0 to 5 do
  begin
    TShape(FindComponent('swInk' + IntToStr(I))).Brush.Color := clWhite;
    TShape(FindComponent('swInk' + IntToStr(I))).Pen.Style := psClear;
  end;
end;

procedure TTshirtDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TTshirtDlg.LayoutDialog(pw, ph: Integer);
// Podgląd standardowy (max 400 px na dłuższym boku) po prawej stronie
// kolumny etapów. GroupBoxy i ich zawartość skalowane fontem.
var
  Scale: Double;
  PrevW, PrevH, ColTop, ColW, ColH, ButtonTop: Integer;
  Gap, SecGap, CapH, RowTop, RowPitch, MaxH: Integer;
  NeedW, SliderLeft, SliderRight: Integer;
  I: Integer;
  SW: TShape;
  LblPal, LblInk: TLabel;
  Btn: TButton;
begin
  if (pw <= 0) or (ph <= 0) then Exit;

  UpdateMapping;

  Gap := RowGap;
  SecGap := SectionGap;
  CapH := Self.Canvas.TextHeight('Wg') + 8;

  Scale := Min(400.0 / pw, 400.0 / ph);
  if Scale > 1.0 then Scale := 1.0;
  PrevW := Max(1, Round(pw * Scale));
  PrevH := Max(1, Round(ph * Scale));

  ColW := grpStage1.Width;

  // --- grpStage1: etykieta + combobox obok siebie ---
  lblColors.Left := 10;
  lblColors.Top := CapH;
  cmbColors.Left := lblColors.Left + lblColors.Width + Gap * 2;
  cmbColors.Top := lblColors.Top + (lblColors.Height - cmbColors.Height) div 2;
  grpStage1.Height := cmbColors.Top + cmbColors.Height + Gap + 4;

  // --- grpStage2: 6 wierszy atramentów (pozycje stałe, z najdłuższego możliwego tekstu) ---
  RowTop := CapH;
  RowPitch := 24 + Gap;
  for I := 0 to 5 do
  begin
    SW := TShape(FindComponent('swInk' + IntToStr(I)));
    LblPal := TLabel(FindComponent('lblPal' + IntToStr(I)));
    Btn := TButton(FindComponent('btnInk' + IntToStr(I)));
    LblInk := TLabel(FindComponent('lblInk' + IntToStr(I)));

    SW.Top := RowTop;
    LblPal.Left := SW.Left + SW.Width + Gap;
    LblPal.Top := RowTop + (24 - LblPal.Height) div 2;
    Btn.Left := LblPal.Left + Self.Canvas.TextWidth(T('Assign ink 6') + ':') + Gap * 3;
    Btn.Top := RowTop;
    LblInk.Left := Btn.Left + Btn.Width + Gap * 2;
    LblInk.AutoSize := False;
    LblInk.Height := Self.Canvas.TextHeight('Wg');
    LblInk.Width := Self.Canvas.TextWidth('Ink: R=255 G=255 B=255') + 10;
    LblInk.Top := RowTop + (24 - LblInk.Height) div 2;

    RowTop := RowTop + RowPitch;
  end;

  NeedW := LblInk.Left + LblInk.Width + 10;
  if NeedW > ColW then
  begin
    ColW := NeedW;
    grpStage1.Width := ColW;
    grpStage2.Width := ColW;
    grpStage3.Width := ColW;
    grpStage4.Width := ColW;
  end;

  grpStage2.Height := RowTop - Gap + Gap + 4;

  // --- grpStage3: etykieta + suwak obok siebie, odczyt poniżej ---
  SliderLeft := 15 + Max(lblMinArea.Width, lblCellMult.Width) + Gap * 8;
  SliderRight := LblInk.Left + LblInk.Width - 15;
  RowTop := CapH;
  lblMinArea.Left := 10;
  lblMinArea.Top := RowTop;
  tbMinArea.Left := SliderLeft;
  tbMinArea.Top := RowTop + (lblMinArea.Height - tbMinArea.Height) div 2;
  tbMinArea.Width := SliderRight - SliderLeft;
  MaxH := Max(lblMinArea.Height, tbMinArea.Height);
  RowTop := RowTop + MaxH + Gap;
  lblMinVal.Left := tbMinArea.Left;
  lblMinVal.Width := tbMinArea.Width;
  lblMinVal.Top := RowTop;
  RowTop := RowTop + lblMinVal.Height + Gap;
  lblCleanCount.Left := 10;
  lblCleanCount.Top := RowTop;
  grpStage3.Height := RowTop + lblCleanCount.Height + Gap + 4;

  // --- grpStage4: checkbox, etykieta + suwak, odczyt ---
  RowTop := CapH;
  chkRaster.Left := 10;
  chkRaster.Top := RowTop;
  RowTop := RowTop + chkRaster.Height + Gap;
  lblCellMult.Left := 10;
  lblCellMult.Top := RowTop;
  tbCellMult.Left := SliderLeft;
  tbCellMult.Top := RowTop + (lblCellMult.Height - tbCellMult.Height) div 2;
  tbCellMult.Width := SliderRight - SliderLeft;
  MaxH := Max(lblCellMult.Height, tbCellMult.Height);
  RowTop := RowTop + MaxH + Gap;
  lblCellMultVal.Left := tbCellMult.Left;
  lblCellMultVal.Width := tbCellMult.Width;
  lblCellMultVal.Top := RowTop;
  grpStage4.Height := RowTop + lblCellMultVal.Height + Gap + 4;

  // --- Układ pionowy GroupBoxów ---
  grpStage1.Top := 15;
  grpStage2.Top := grpStage1.Top + grpStage1.Height + SecGap;
  grpStage3.Top := grpStage2.Top + grpStage2.Height + SecGap;
  grpStage4.Top := grpStage3.Top + grpStage3.Height + SecGap;

  ColTop := grpStage1.Top;
  ColH := (grpStage4.Top + grpStage4.Height) - ColTop;

  // Podgląd
  pboxPreview.Width := PrevW;
  pboxPreview.Height := PrevH;
  pboxPreview.Left := ColW + 30;
  pboxPreview.Top := ColTop + ((ColH - PrevH) div 2);
  if pboxPreview.Top < ColTop then pboxPreview.Top := ColTop;

  // Przyciski
  ClientWidth := pboxPreview.Left + PrevW + 15;
  ButtonTop := ColTop + ColH + SecGap;
  btnOK.Top := ButtonTop;
  btnCancel.Top := ButtonTop;
  btnOK.Left := ClientWidth - 15 - 85 - 85 - 10;
  btnCancel.Left := ClientWidth - 15 - 85;
  ClientHeight := ButtonTop + 25 + 15;
end;

procedure TTshirtDlg.EnsureInks(N: Integer);
const
  Def: array[0..4] of TColor = (
    $00C83746,
    $001E1E23,
    $00F0C814,
    $0000A5C3,
    $0046AA50);
var
  I, Len: Integer;
begin
  Len := Length(FInks);
  if Len < N then
  begin
    SetLength(FInks, N);
    for I := Len to N - 1 do
    begin
      if I <= 4 then
        FInks[I] := Def[I]
      else
        FInks[I] := TshirtHSVToRGB(I * 360.0 / N, 255.0, 255.0);
    end;
  end;
end;

procedure TTshirtDlg.UpdateMapping;
var
  I, N: Integer;
  SW: TShape;
  LblPal, LblInk: TLabel;
  Btn: TButton;
  Active: Boolean;
begin
  N := cmbColors.ItemIndex + 2;
  for I := 0 to 5 do
  begin
    SW := TShape(FindComponent('swInk' + IntToStr(I)));
    LblPal := TLabel(FindComponent('lblPal' + IntToStr(I)));
    LblInk := TLabel(FindComponent('lblInk' + IntToStr(I)));
    Btn := TButton(FindComponent('btnInk' + IntToStr(I)));

    Active := I < N;
    Btn.Enabled := Active;
    LblInk.Enabled := Active;

    LblPal.Caption := T('Assign ink ' + IntToStr(I + 1));

    if Active and (I < Length(FInks)) then
    begin
      LblInk.Caption := T('Ink:') + ' ' + TshirtColorStr(FInks[I]);
      SW.Brush.Color := FInks[I];
    end
    else
      LblInk.Caption := T('Ink:');
  end;
end;

procedure TTshirtDlg.RunPreview(Bitmap: TBitmap);
var
  N, MinArea: Integer;
  CleanCount: Integer;
begin
  N := cmbColors.ItemIndex + 2;
  MinArea := tbMinArea.Position;

  if chkRaster.Checked then
  begin
    EnsureInks(N);
    TshirtRender(Bitmap, FInks, GetCellMultValue);
    CleanCount := TshirtClean(Bitmap, MinArea);
    lblCleanCount.Caption := T('Islands removed:') + ' ' + IntToStr(CleanCount);
  end
  else
  begin
    if Length(FInks) < N then
      FInks := TshirtExtractPalette(Bitmap, N);
    TshirtMapToInks(Bitmap, FInks);
    lblCleanCount.Caption := T('Islands removed:') + ' '
      + IntToStr(TshirtClean(Bitmap, MinArea));
    TshirtWhiteToFabric(Bitmap);
  end;

  UpdateMapping;
end;

procedure TTshirtDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  RunPreview(FWorkingPreview);
  pboxPreview.Invalidate;
end;

procedure TTshirtDlg.ApplyFull;
begin
  if chkRaster.Checked then
  begin
    EnsureInks(cmbColors.ItemIndex + 2);
    TshirtRender(FSourceBmp, FInks, GetCellMultValue);
    TshirtClean(FSourceBmp, tbMinArea.Position);
  end
  else
  begin
    if Length(FInks) < cmbColors.ItemIndex + 2 then
      FInks := TshirtExtractPalette(FSourceBmp, cmbColors.ItemIndex + 2);
    TshirtMapToInks(FSourceBmp, FInks);
    TshirtClean(FSourceBmp, tbMinArea.Position);
    TshirtWhiteToFabric(FSourceBmp);
  end;
end;

procedure TTshirtDlg.cmbColorsChange(Sender: TObject);
begin
  SetLength(FInks, 0);
  ApplyPreview;
end;

procedure TTshirtDlg.tbMinAreaChange(Sender: TObject);
begin
  lblMinVal.Caption := IntToStr(tbMinArea.Position);
  ApplyPreview;
end;

procedure TTshirtDlg.chkRasterClick(Sender: TObject);
begin
  tbCellMult.Enabled := chkRaster.Checked;
  ApplyPreview;
end;

function TTshirtDlg.GetCellMultValue: Double;
begin
  // Suwak trzyma integer 1..16 (krok = 0.25); wartość rzeczywista = position*0.25
  // (pos. 4 => 1.0, pos. 1 => 0.25, pos. 16 => 4.0). Czysto integerowy TTrackBar.
  Result := tbCellMult.Position * 0.25;
end;

procedure TTshirtDlg.tbCellMultChange(Sender: TObject);
begin
  lblCellMultVal.Caption := FormatFloat('0.00×', GetCellMultValue);
  ApplyPreview;
end;

procedure TTshirtDlg.btnInk0Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 0;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.btnInk1Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 1;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.btnInk2Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 2;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.btnInk3Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 3;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.btnInk4Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 4;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.btnInk5Click(Sender: TObject);
var
  Dlg: TColorDialog;
  I: Integer;
begin
  Dlg := TColorDialog.Create(nil);
  try
    EnsureInks(cmbColors.ItemIndex + 2);
    I := 5;
    Dlg.Color := FInks[I];
    if Dlg.Execute then
    begin
      FInks[I] := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTshirtDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);

    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;

      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;

      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);

      DestRect := Rect(
        (TargetW - NewW) div 2,
        (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW,
        (TargetH - NewH) div 2 + NewH
      );

      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
