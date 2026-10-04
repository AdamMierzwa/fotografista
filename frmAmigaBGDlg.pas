unit frmAmigaBGDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, uAmiga, uI18n, uMacros;

type
  TAmigaBGDlg = class(TForm)
    lblRes: TLabel;
    cbRes: TComboBox;
    lblColor: TLabel;
    cbColor: TComboBox;
    btnCustomColor: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnCustomColorClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FCustomColor: TColor;
    FHasCustom: Boolean;
    FSourceBmp: TBitmap;
    function GetFillColor: TColor;
    procedure ApplyFull(Tw, Th: Integer; FillColor: TColor);
  end;

function ShowAmigaBGDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

type
  TMagicColor = record
    Name: string;
    RGB: Cardinal; // $RRGGBB
  end;

const
  MagicColors: array[0..7] of TMagicColor = (
    (Name: 'Grey';         RGB: $959595),
    (Name: 'Black';        RGB: $000000),
    (Name: 'White';        RGB: $FFFFFF),
    (Name: 'Blue';         RGB: $3B67A2),
    (Name: 'Dark grey';    RGB: $7B7B7B),
    (Name: 'Light grey';   RGB: $AFAFAF),
    (Name: 'Brown';        RGB: $AA907C),
    (Name: 'Salmon';       RGB: $FFA997));

const
  ResW: array[0..4] of Integer = (320, 640, 640, 800, 1024);
  ResH: array[0..4] of Integer = (256, 256, 512, 600, 768);

// $RRGGBB -> TColor ($00BBGGRR)
function RgbToColor(RGB: Cardinal): TColor;
begin
  Result := TColor(((RGB and $FF) shl 16) or (RGB and $FF00) or ((RGB shr 16) and $FF));
end;

function ShowAmigaBGDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TAmigaBGDlg;
  SW: TStopwatch;
  Idx, Tw, Th: Integer;
  FillColor: TColor;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TAmigaBGDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;
    Dlg.FHasCustom := False;

    if Dlg.ShowModal = mrOk then
    begin
      Idx := Dlg.cbRes.ItemIndex;
      if Idx < 0 then Idx := 0;
      Tw := ResW[Idx];
      Th := ResH[Idx];
      FillColor := Dlg.GetFillColor;
      SW := TStopwatch.StartNew;
      gMacroPending.Code := 'AMIGABG';
      gMacroPending.Params := IntToStr(Tw) + '|' + IntToStr(Th) + '|' + IntToStr(Integer(FillColor));
      Dlg.ApplyFull(Tw, Th, FillColor);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TAmigaBGDlg }

procedure TAmigaBGDlg.FormCreate(Sender: TObject);
var
  I, MaxItemW, ComboW, ContentW, Gap, SectionGap, Margin, Pad: Integer;
begin
  cbRes.Items.Clear;
  cbRes.Items.Add('320 x 256 (OCS/ECS PAL Lo-Res)');
  cbRes.Items.Add('640 x 256 (OCS/ECS PAL Hi-Res)');
  cbRes.Items.Add('640 x 512 (OCS/ECS PAL Interlace)');
  cbRes.Items.Add('800 x 600 (AGA/RTG)');
  cbRes.Items.Add('1024 x 768 (AGA/RTG)');
  cbRes.ItemIndex := 0;

  cbColor.Items.Clear;
  for I := 0 to High(MagicColors) do
    cbColor.Items.Add(T(MagicColors[I].Name));
  cbColor.ItemIndex := 0;

  FCustomColor := RgbToColor(MagicColors[0].RGB);

  TranslateForm(Self);

  Margin := 15;
  Gap := Canvas.TextHeight('Wg') div 3;
  SectionGap := Canvas.TextHeight('Wg');
  Pad := 2 * Canvas.TextWidth('W');

  MaxItemW := 0;
  for I := 0 to cbRes.Items.Count - 1 do
    if Canvas.TextWidth(cbRes.Items[I]) > MaxItemW then
      MaxItemW := Canvas.TextWidth(cbRes.Items[I]);
  for I := 0 to cbColor.Items.Count - 1 do
    if Canvas.TextWidth(cbColor.Items[I]) > MaxItemW then
      MaxItemW := Canvas.TextWidth(cbColor.Items[I]);

  btnCustomColor.Width := Max(85, Canvas.TextWidth(btnCustomColor.Caption) + Pad);
  btnOK.Width := Max(85, Canvas.TextWidth(btnOK.Caption) + Pad);
  btnCancel.Width := Max(85, Canvas.TextWidth(btnCancel.Caption) + Pad);

  ComboW := MaxItemW + SectionGap * 2 + 8;
  cbRes.Width := ComboW;
  cbColor.Width := ComboW;

  ContentW := Max(lblRes.Width, lblColor.Width);
  if ComboW > ContentW then
    ContentW := ComboW;
  if btnCustomColor.Width > ContentW then
    ContentW := btnCustomColor.Width;
  if btnOK.Width + Gap + btnCancel.Width > ContentW then
    ContentW := btnOK.Width + Gap + btnCancel.Width;
  ClientWidth := ContentW + 2 * Margin;

  lblRes.Left := Margin;
  lblRes.Top := Margin;
  cbRes.Left := Margin;
  cbRes.Top := lblRes.Top + lblRes.Height + Gap;

  lblColor.Left := Margin;
  lblColor.Top := cbRes.Top + cbRes.Height + SectionGap;
  cbColor.Left := Margin;
  cbColor.Top := lblColor.Top + lblColor.Height + Gap;

  btnCustomColor.Left := Margin;
  btnCustomColor.Top := cbColor.Top + cbColor.Height + SectionGap;

  btnCancel.Left := ClientWidth - Margin - btnCancel.Width;
  btnOK.Left := btnCancel.Left - Gap - btnOK.Width;
  btnOK.Top := btnCustomColor.Top + btnCustomColor.Height + Gap;
  btnCancel.Top := btnOK.Top;

  ClientHeight := btnOK.Top + btnOK.Height + Margin;
end;

function TAmigaBGDlg.GetFillColor: TColor;
begin
  if FHasCustom then
    Result := FCustomColor
  else
    Result := RgbToColor(MagicColors[Max(0, cbColor.ItemIndex)].RGB);
end;

procedure TAmigaBGDlg.ApplyFull(Tw, Th: Integer; FillColor: TColor);
begin
  ApplyAmigaBackground(FSourceBmp, Tw, Th, FillColor);
end;

procedure TAmigaBGDlg.btnCustomColorClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FCustomColor;
    if Dlg.Execute then
    begin
      FCustomColor := Dlg.Color;
      FHasCustom := True;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
