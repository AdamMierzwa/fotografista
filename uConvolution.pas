unit uConvolution;

interface

uses
  Vcl.Graphics;

procedure BoxBlur(const Src: TBitmap; Dst: TBitmap; Radius: Integer);

// Graduated blur wspólny dla bokeh (Shape=0, radialny) i makieta (Shape=1, pas poziomy).
// Wszystkie współrzędne/rozmiary są znormalizowane (0..1). Modyfikuje Bitmap w miejscu.
// Radius bluru skaluje się do szerokości obrazu (REFERENCE_WIDTH), więc podgląd 400px
// i pełny oryginał dają spójny efekt względny.
procedure RenderGraduatedBlur(Bitmap: TBitmap; Strength, Shape: Integer;
  cx_norm, cy_norm, size_norm, falloff_norm, band_y_norm: Double);

implementation

uses
  System.Math,
  GR32,
  GR32.Blur;

const
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure BoxBlur(const Src: TBitmap; Dst: TBitmap; Radius: Integer);
var
  Bmp32: TBitmap32;
begin
  if (Radius < 1) or (Src.Width < 1) or (Src.Height < 1) then
  begin
    Dst.Assign(Src);
    Exit;
  end;

  // Wymiana na GR32: Gaussian blur (Blur32) zamiast ręcznego box blur.
  // Konwersja TBitmap<->TBitmap32 przez adapter GR32.ImageFormats.TBitmap.
  Bmp32 := TBitmap32.Create;
  try
    Bmp32.Assign(Src);
    Blur32(Bmp32, Radius);
    Dst.Assign(Bmp32);
    // Adapter stawia Dst.PixelFormat = pf32bit; wracamy do 24-bit, bo konsumenci
    // czytają ScanLine jako 3 bajty/piksel (PRGBTripleArray).
    Dst.PixelFormat := pf24bit;
  finally
    Bmp32.Free;
  end;
end;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

procedure RenderGraduatedBlur(Bitmap: TBitmap; Strength, Shape: Integer;
  cx_norm, cy_norm, size_norm, falloff_norm, band_y_norm: Double);
// Wzorzec z Hollywood p_RenderGraduatedBlur: 4 poziomy rozmycia (0, 15%, 40%, 100%),
// per-pixel interpolacja liniowa między poziomami wg odległości od środka/pasa.
//   t = sqrt(((x-cx)/R)^2 + ((y-cy)/R)^2)      dla bokeh (Shape=0)
//   t = |y - band_center_y| / band_h           dla makieta (Shape=1)
//   t clamped 0..1, potem t = t^power (power = 0.5 + falloff*2.5),
//   lf = t*3, lerp między poziomem li i li+1.
var
  W, H, X, Y, i, li, MaxR: Integer;
  Levels: array[0..3] of TBitmap;
  LevelLines: array[0..3] of array of PRGBTripleArray;
  OutBmp: TBitmap;
  OutLines: array of PRGBTripleArray;
  Radii: array[0..3] of Integer;
  CenterX, CenterY, BandCenY, Rad, BandH, PowExp: Double;
  dx, dy, t, lf, Frac: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;

  Strength := Max(1, Min(100, Strength));
  MaxR := Max(2, Round(Strength / 100.0 * 50 * W / REFERENCE_WIDTH));

  Radii[0] := 0;
  Radii[1] := Max(1, Round(MaxR * 0.15));
  Radii[2] := Max(1, Round(MaxR * 0.4));
  Radii[3] := Max(1, MaxR);
  if Radii[3] = Radii[2] then Inc(Radii[3]);

  Levels[0] := Bitmap;
  for i := 1 to 3 do
  begin
    Levels[i] := TBitmap.Create;
    try
      Levels[i].PixelFormat := pf24bit;
      Levels[i].SetSize(W, H);
      BoxBlur(Bitmap, Levels[i], Radii[i]);
    except
      Levels[i].Free;
      Levels[i] := nil;
      raise;
    end;
  end;

  try
    for i := 0 to 3 do
    begin
      SetLength(LevelLines[i], H);
      for Y := 0 to H - 1 do
        LevelLines[i][Y] := Levels[i].ScanLine[Y];
    end;

    OutBmp := TBitmap.Create;
    try
      OutBmp.PixelFormat := pf24bit;
      OutBmp.SetSize(W, H);
      SetLength(OutLines, H);
      for Y := 0 to H - 1 do
        OutLines[Y] := OutBmp.ScanLine[Y];

      CenterX := cx_norm * W;
      CenterY := cy_norm * H;
      BandCenY := band_y_norm * H;
      Rad := Max(5, size_norm * 1.5 * Min(W, H));
      BandH := Max(5, size_norm * 0.4 * H);
      PowExp := 0.5 + falloff_norm * 2.5;

      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
        begin
          if Shape = 0 then
          begin
            dx := (X - CenterX) / Rad;
            dy := (Y - CenterY) / Rad;
            t := Sqrt(dx * dx + dy * dy);
          end
          else
            t := Abs(Y - BandCenY) / BandH;

          if t < 0 then t := 0
          else if t > 1 then t := 1;
          t := Power(t, PowExp);

          lf := t * 3.0;
          li := Trunc(lf);
          if li >= 3 then li := 2;
          Frac := lf - li;

          OutLines[Y][X].R := ClampByte(Round(
            LevelLines[li][Y][X].R * (1.0 - Frac) + LevelLines[li + 1][Y][X].R * Frac));
          OutLines[Y][X].G := ClampByte(Round(
            LevelLines[li][Y][X].G * (1.0 - Frac) + LevelLines[li + 1][Y][X].G * Frac));
          OutLines[Y][X].B := ClampByte(Round(
            LevelLines[li][Y][X].B * (1.0 - Frac) + LevelLines[li + 1][Y][X].B * Frac));
        end;

      Bitmap.Assign(OutBmp);
    finally
      OutBmp.Free;
    end;
  finally
    for i := 1 to 3 do
    begin
      Levels[i].Free;
      Levels[i] := nil;
    end;
  end;
end;

end.
