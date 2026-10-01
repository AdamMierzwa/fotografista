unit frmEdgeDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TEdgeDlg = class(TFotoForm)
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

function ShowEdgeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoEdge(Bitmap: TBitmap; Pct: Integer);

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

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure DoEdge(Bitmap: TBitmap; Pct: Integer);
// Detekcja krawędzi — szkic (czarny na białym), Sobel na luminancji.
// Luminancja L = (299R+587G+114B)/1000.
// mag = sqrt(Gx^2 + Gy^2) na L (brzegi klampowane).
// out = 255 - clamp(mag * factor), factor = Pct/100 * 0.25.
// Biały tam, gdzie brak krawędzi; ciemny na konturach. Suwak = czułość.
// Sobel na luminancji (nie na kanałach RGB) — efekt szkicu, nie negatywu.
var
  W, H, X, Y, L, Gx, Gy: Integer;
  Factor: Double;
  TmpBmp: TBitmap;
  SrcLines, TmpLines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Pct := Max(1, Min(100, Pct));
  Factor := Pct / 100.0 * 0.25;

  TmpBmp := TBitmap.Create;
  try
    TmpBmp.PixelFormat := pf24bit;
    TmpBmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(TmpLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bitmap.ScanLine[Y];
      TmpLines[Y] := TmpBmp.ScanLine[Y];
    end;

    // Luminancja do TmpBmp (R=G=B=L)
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        L := (299 * SrcLines[Y][X].R + 587 * SrcLines[Y][X].G + 114 * SrcLines[Y][X].B) div 1000;
        TmpLines[Y][X].R := L;
        TmpLines[Y][X].G := L;
        TmpLines[Y][X].B := L;
      end;

    // Sobel na luminancji
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        Gx :=
            TmpLines[ClampI(Y-1,0,H-1)][ClampI(X+1,0,W-1)].R
          - TmpLines[ClampI(Y-1,0,H-1)][ClampI(X-1,0,W-1)].R
          + 2*TmpLines[Y][ClampI(X+1,0,W-1)].R
          - 2*TmpLines[Y][ClampI(X-1,0,W-1)].R
          + TmpLines[ClampI(Y+1,0,H-1)][ClampI(X+1,0,W-1)].R
          - TmpLines[ClampI(Y+1,0,H-1)][ClampI(X-1,0,W-1)].R;

        Gy :=
            TmpLines[ClampI(Y+1,0,H-1)][ClampI(X-1,0,W-1)].R
          - TmpLines[ClampI(Y-1,0,H-1)][ClampI(X-1,0,W-1)].R
          + 2*TmpLines[ClampI(Y+1,0,H-1)][X].R
          - 2*TmpLines[ClampI(Y-1,0,H-1)][X].R
          + TmpLines[ClampI(Y+1,0,H-1)][ClampI(X+1,0,W-1)].R
          - TmpLines[ClampI(Y-1,0,H-1)][ClampI(X+1,0,W-1)].R;

        L := ClampByte(Round(Sqrt(Gx * Gx + Gy * Gy) * Factor));
        SrcLines[Y][X].R := Byte(255 - L);
        SrcLines[Y][X].G := Byte(255 - L);
        SrcLines[Y][X].B := Byte(255 - L);
      end;
  finally
    TmpBmp.Free;
  end;
end;

function ShowEdgeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TEdgeDlg;
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
    Dlg := TEdgeDlg.Create(Application);
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
      gMacroPending.Code := 'EDGE';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TEdgeDlg }

procedure TEdgeDlg.FormCreate(Sender: TObject);
begin
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 50;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TEdgeDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TEdgeDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TEdgeDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoEdge(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TEdgeDlg.ApplyFull;
begin
  DoEdge(FSourceBmp, tbAmount.Position);
end;

procedure TEdgeDlg.pboxPreviewPaint(Sender: TObject);
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
