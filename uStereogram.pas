unit uStereogram;

interface

uses
  Vcl.Graphics;

procedure DoStereogram(Bitmap: TBitmap; Mode, Period, Depth, Seed: Integer);

implementation

uses
  System.Math;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

procedure DoStereogram(Bitmap: TBitmap; Mode, Period, Depth, Seed: Integer);
// mode=0: autostereogram (SIRDS) — losowe szare kropki replikowane z shiftem
//         wg luminancji (wzorzec: image_fx_effects.hws:636-660)
// mode=1: anaglif — kanał R przesunięty w lewo, G/B w prawo o shift=lum*depth/255
//         (wzorzec: image_fx_effects.hws:665-694)
// Period: odstep powtarzania kafelka (tylko SIRDS; anaglif ignoruje)
// Depth:  maksymalne przesuniecie w px
// Seed:   >=0 = deterministyczny (RandSeed), -1 = losowy (Randomize)
var
  W, H, X, Y: Integer;
  Dst: TBitmap;
  SrcRow, DstRow: PRGBTripleArray;
  Luminance: array of Integer;
  D, Shift, FromX, LeftX, RightX: Integer;
  G, R, G2, Idx: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Depth := Max(0, Min(30, Depth));
  if Seed >= 0 then
    System.RandSeed := Seed
  else
    System.Randomize;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Dst := TBitmap.Create;
  try
    Dst.PixelFormat := pf24bit;
    Dst.SetSize(W, H);

    if Mode = 0 then
    begin
      // SIRDS
      Period := Max(1, Min(W, Period));
      for Y := 0 to H - 1 do
      begin
        SrcRow := Bitmap.ScanLine[Y];
        DstRow := Dst.ScanLine[Y];
        for X := 0 to Period - 1 do
        begin
          G := Random(256);
          DstRow[X].R := G;
          DstRow[X].G := G;
          DstRow[X].B := G;
        end;
        for X := Period to W - 1 do
        begin
          D := (SrcRow[X].R * 299 + SrcRow[X].G * 587 + SrcRow[X].B * 114) div 1000;
          Shift := D * Depth div 255;
          FromX := X - Period + Shift;
          if FromX < 0 then FromX := 0;
          DstRow[X] := DstRow[FromX];
        end;
      end;
    end
    else
    begin
      // Anaglif: luminancja + przesuniecie R w lewo, G/B w prawo
      SetLength(Luminance, W * H);
      for Y := 0 to H - 1 do
      begin
        SrcRow := Bitmap.ScanLine[Y];
        for X := 0 to W - 1 do
          Luminance[Y * W + X] := (SrcRow[X].R * 299 + SrcRow[X].G * 587 + SrcRow[X].B * 114) div 1000;
      end;
      for Y := 0 to H - 1 do
      begin
        DstRow := Dst.ScanLine[Y];
        for X := 0 to W - 1 do
        begin
          Idx := Y * W + X;
          D := Luminance[Idx];
          Shift := D * Depth div 255;
          LeftX := X - Shift;
          if LeftX < 0 then LeftX := 0;
          RightX := X + Shift;
          if RightX >= W then RightX := W - 1;
          R := Luminance[Y * W + LeftX];
          G2 := Luminance[Y * W + RightX];
          DstRow[X].R := Byte(R);
          DstRow[X].G := Byte(G2);
          DstRow[X].B := Byte(G2);
        end;
      end;
      Luminance := nil;
    end;

    Bitmap.Assign(Dst);
  finally
    Dst.Free;
  end;
end;

end.
