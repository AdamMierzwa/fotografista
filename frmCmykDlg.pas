unit frmCmykDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TCmykDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblC: TLabel;
    tbC: TTrackBar;
    lblCVal: TLabel;
    lblM: TLabel;
    tbM: TTrackBar;
    lblMVal: TLabel;
    lblY: TLabel;
    tbY: TTrackBar;
    lblYVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbCChange(Sender: TObject);
    procedure tbMChange(Sender: TObject);
    procedure tbYChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowCmykDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

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

procedure DoCmykMisreg(Bitmap: TBitmap; CVal, MVal, YVal, FullW, FullH: Integer);
var
  W, H: Integer;
  Src: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cdx, Cdy, Mdx, Mdy, Ydx, Ydy: Integer;
  Sx, Sy: Integer;
  K: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  // Wspólny wektor przesunięcia dla wszystkich kanałów: równe suwaki = nałożenie,
  // różne = kolorowe krawędzie (aberracja chromatyczna). 50 = neutralnie.
  K := 0.02;
  Cdx := Round((CVal - 50) / 50.0 * K * FullW);
  Cdy := Round((CVal - 50) / 50.0 * K * FullH);
  Mdx := Round((MVal - 50) / 50.0 * K * FullW);
  Mdy := Round((MVal - 50) / 50.0 * K * FullH);
  Ydx := Round((YVal - 50) / 50.0 * K * FullW);
  Ydy := Round((YVal - 50) / 50.0 * K * FullH);

  Src := TBitmap.Create;
  try
    Src.Assign(Bitmap);
    Src.PixelFormat := pf24bit;

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Src.ScanLine[Y];
      DstLines[Y] := Bitmap.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        // C: red channel z przesuniętej pozycji
        Sx := X + Cdx;
        Sy := Y + Cdy;
        if Sx < 0 then Sx := 0
        else if Sx >= W then Sx := W - 1;
        if Sy < 0 then Sy := 0
        else if Sy >= H then Sy := H - 1;
        DstLines[Y][X].R := SrcLines[Sy][Sx].R;

        // M: green channel z przesuniętej pozycji
        Sx := X + Mdx;
        Sy := Y + Mdy;
        if Sx < 0 then Sx := 0
        else if Sx >= W then Sx := W - 1;
        if Sy < 0 then Sy := 0
        else if Sy >= H then Sy := H - 1;
        DstLines[Y][X].G := SrcLines[Sy][Sx].G;

        // Y: blue channel z przesuniętej pozycji
        Sx := X + Ydx;
        Sy := Y + Ydy;
        if Sx < 0 then Sx := 0
        else if Sx >= W then Sx := W - 1;
        if Sy < 0 then Sy := 0
        else if Sy >= H then Sy := H - 1;
        DstLines[Y][X].B := SrcLines[Sy][Sx].B;
      end;
    end;
  finally
    Src.Free;
  end;
end;

function ShowCmykDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TCmykDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TCmykDlg.Create(Application);
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

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

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

{ TCmykDlg }

procedure TCmykDlg.FormCreate(Sender: TObject);
begin
  tbC.Position := 50;
  tbM.Position := 50;
  tbY.Position := 50;
  lblCVal.Caption := IntToStr(tbC.Position);
  lblMVal.Caption := IntToStr(tbM.Position);
  lblYVal.Caption := IntToStr(tbY.Position);
end;

procedure TCmykDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TCmykDlg.tbCChange(Sender: TObject);
begin
  lblCVal.Caption := IntToStr(tbC.Position);
  ApplyPreview;
end;

procedure TCmykDlg.tbMChange(Sender: TObject);
begin
  lblMVal.Caption := IntToStr(tbM.Position);
  ApplyPreview;
end;

procedure TCmykDlg.tbYChange(Sender: TObject);
begin
  lblYVal.Caption := IntToStr(tbY.Position);
  ApplyPreview;
end;

procedure TCmykDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoCmykMisreg(FWorkingPreview, tbC.Position, tbM.Position, tbY.Position,
    FSourceBmp.Width, FSourceBmp.Height);
  pboxPreview.Invalidate;
end;

procedure TCmykDlg.ApplyFull;
begin
  DoCmykMisreg(FSourceBmp, tbC.Position, tbM.Position, tbY.Position,
    FSourceBmp.Width, FSourceBmp.Height);
end;

procedure TCmykDlg.pboxPreviewPaint(Sender: TObject);
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
