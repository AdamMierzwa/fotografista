unit frmEmbossDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TEmbossDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblLabel: TLabel;
    tbAmount: TTrackBar;
    lblValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbAmountChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowEmbossDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoEmboss(Bitmap: TBitmap; Pct: Integer);

implementation

uses
  uMacros;

{$R *.dfm}

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

function ClampI(V, Lo, Hi: Integer): Integer; inline;
begin
  if V < Lo then Result := Lo
  else if V > Hi then Result := Hi
  else Result := V;
end;

procedure ApplyEmbossEffect(Src, Dst: TBitmap; Strength: Double);
// Wytłaczanie (emboss): grayscale relief z jądra diagonalnego.
//   out = 128 + Strength * (L(x,y) - L(x-1,y-1))
// Luminancja L = (299R+587G+114B) div 1000. Światło pada z góry-lewo,
// więc jasne krawędzie biegną wzdłuż konturów, a cień w przeciwnym kierunku.
// Bias 128 daje szare tło (0/255 tylko dla skrajnych gradientów).
// Krawędzie obrazu klampowane (brak przycięcia na obrzeżach).
var
  W, H, X, Y, L, LPrev, Val: Integer;
  TmpBmp: TBitmap;
  SrcLines, TmpLines, DstLines: array of PRGBTripleArray;
begin
  W := Src.Width;
  H := Src.Height;
  if (W = 0) or (H = 0) then Exit;

  // Wymuś pf24bit dla Src — ScanLine czytany jako 3 bajty/piksel (PRGBTripleArray).
  if Src.PixelFormat <> pf24bit then
    Src.PixelFormat := pf24bit;

  Dst.PixelFormat := pf24bit;
  Dst.SetSize(W, H);

  TmpBmp := TBitmap.Create;
  try
    TmpBmp.PixelFormat := pf24bit;
    TmpBmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(TmpLines, H);
    SetLength(DstLines, H);

    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Src.ScanLine[Y];
      TmpLines[Y] := TmpBmp.ScanLine[Y];
    end;

    // Luminancja L (R=G=B=L) do wspólnego TmpBmp
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        L := (299 * SrcLines[Y][X].R + 587 * SrcLines[Y][X].G + 114 * SrcLines[Y][X].B) div 1000;
        TmpLines[Y][X].R := L;
        TmpLines[Y][X].G := L;
        TmpLines[Y][X].B := L;
      end;

    for Y := 0 to H - 1 do
      DstLines[Y] := Dst.ScanLine[Y];

    // Jądro diagonalne: out = 128 + S * (L(x,y) - L(x-1,y-1))
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        L := TmpLines[Y][X].R;
        LPrev := TmpLines[ClampI(Y - 1, 0, H - 1)][ClampI(X - 1, 0, W - 1)].R;
        Val := Round(128 + Strength * (L - LPrev));
        if Val < 0 then Val := 0;
        if Val > 255 then Val := 255;
        DstLines[Y][X].R := Byte(Val);
        DstLines[Y][X].G := Byte(Val);
        DstLines[Y][X].B := Byte(Val);
      end;
  finally
    TmpBmp.Free;
  end;
end;

procedure DoEmboss(Bitmap: TBitmap; Pct: Integer);
// Wrapper: suwak 1..100 -> siła S. S = 0.25..2.5 (od delikatnego do mocnego).
var
  Tmp: TBitmap;
  Strength: Double;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  Pct := Max(1, Min(100, Pct));
  Strength := 0.25 + 2.25 * Pct / 100;

  Tmp := TBitmap.Create;
  try
    ApplyEmbossEffect(Bitmap, Tmp, Strength);
    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowEmbossDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TEmbossDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TEmbossDlg.Create(Application);
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

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'EMBOSS';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TEmbossDlg }

procedure TEmbossDlg.FormCreate(Sender: TObject);
begin
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 30;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TEmbossDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TEmbossDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TEmbossDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoEmboss(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TEmbossDlg.ApplyFull;
begin
  DoEmboss(FSourceBmp, tbAmount.Position);
end;

procedure TEmbossDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH: Integer;
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
        (TargetW - NewW) div 2, (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW, (TargetH - NewH) div 2 + NewH);
      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
