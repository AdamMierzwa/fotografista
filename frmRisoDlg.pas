unit frmRisoDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uRiso, uI18n, uTitleBar;

type
  TRisoVersion = (rvV1, rvV2);

  TRisoDlg = class(TFotoForm)
    lstPalettes: TListBox;
    pboxPreview: TPaintBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure lstPalettesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FVersion: TRisoVersion;
    function CurrentPalette: TRisoPalette;
    procedure FitPreview(pw, ph: Integer);
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowRisoDlg(Bitmap: TBitmap; Version: TRisoVersion; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowRisoDlg(Bitmap: TBitmap; Version: TRisoVersion; out ElapsedSec: Double): Boolean;
var
  Dlg: TRisoDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TRisoDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;
    Dlg.FVersion := Version;
    if Version = rvV1 then
      Dlg.Caption := T('Risograph v1')
    else
      Dlg.Caption := T('Risograph v2');

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

    Dlg.FitPreview(pw, ph);

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

{ TRisoDlg }

procedure TRisoDlg.FormCreate(Sender: TObject);
var
  I, MaxW, W: Integer;
  S: string;
const
  ListPadding = 30; // margines wewnętrzny + zapas na pasek przewijania
begin
  DoubleBuffered := True;
  lstPalettes.Clear;
  lstPalettes.Canvas.Font.Assign(lstPalettes.Font);
  MaxW := 0;
  for I := 0 to GetRisoPaletteCount - 1 do
  begin
    S := GetRisoPaletteName(I);
    lstPalettes.Items.Add(S);
    W := lstPalettes.Canvas.TextWidth(S);
    if W > MaxW then MaxW := W;
  end;
  lstPalettes.ItemIndex := 0;
  lstPalettes.Width := MaxW + ListPadding;
end;

procedure TRisoDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

function TRisoDlg.CurrentPalette: TRisoPalette;
begin
  Result := GetRisoPalette(lstPalettes.ItemIndex);
end;

procedure TRisoDlg.FitPreview(pw, ph: Integer);
// Podgląd po prawej stronie listy: obszar ograniczony wysokością listy,
// dopasowanie do proporcji zdjęcia, wyśrodkowanie w obszarze.
var
  AvailW, AvailH, PrevW, PrevH: Integer;
  Scale: Double;
begin
  if (pw <= 0) or (ph <= 0) then Exit;
  AvailW := ClientWidth - lstPalettes.Left - lstPalettes.Width - 30;
  AvailH := lstPalettes.Height;
  Scale := Min(AvailW / pw, AvailH / ph);
  if Scale > 1.0 then Scale := 1.0;
  PrevW := Max(1, Round(pw * Scale));
  PrevH := Max(1, Round(ph * Scale));
  pboxPreview.Width := PrevW;
  pboxPreview.Height := PrevH;
  pboxPreview.Left := lstPalettes.Left + lstPalettes.Width + 15
    + ((AvailW - PrevW) div 2);
  pboxPreview.Top := lstPalettes.Top + ((AvailH - PrevH) div 2);
end;

procedure TRisoDlg.lstPalettesClick(Sender: TObject);
begin
  if lstPalettes.ItemIndex >= 0 then ApplyPreview;
end;

procedure TRisoDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  if FVersion = rvV1 then
    DoRisoV1(FWorkingPreview, CurrentPalette)
  else
    DoRisoV2(FWorkingPreview, CurrentPalette);
  pboxPreview.Invalidate;
end;

procedure TRisoDlg.ApplyFull;
begin
  if FVersion = rvV1 then
    DoRisoV1(FSourceBmp, CurrentPalette)
  else
    DoRisoV2(FSourceBmp, CurrentPalette);
end;

procedure TRisoDlg.pboxPreviewPaint(Sender: TObject);
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
