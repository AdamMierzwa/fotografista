unit uRiso;

interface

uses
  Vcl.Graphics, System.Math, uPixelEngine, uI18n;

type
  TRisoColor = record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  TRisoBand = record
    R: Byte;
    G: Byte;
    B: Byte;
    Dx: Integer;
    Dy: Integer;
  end;

  TRisoPalette = array of TRisoBand;

procedure DoRisoV1(Bitmap: TBitmap; const Pal: TRisoPalette; CellMult: Integer = 1);
procedure DoRisoV2(Bitmap: TBitmap; const Pal: TRisoPalette; CellMult: Integer = 1);
procedure DoRisoV3(Bitmap: TBitmap; const Layers: array of TRisoColor);

function GetRisoPaletteCount: Integer;
function GetRisoPaletteName(Idx: Integer): string;
function GetRisoPalette(Idx: Integer): TRisoPalette;

implementation

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

  TRisoPalDef = record
    Name: string;
    Idx: array[0..3] of Integer;
    Dx: array[0..3] of Integer;
    Dy: array[0..3] of Integer;
    Count: Integer;
  end;

const
  RisoColors: array[0..13] of TRisoColor = (
    (R: 0;   G: 165; B: 195),
    (R: 200; G: 55;  B: 70),
    (R: 240; G: 200; B: 20),
    (R: 30;  G: 30;  B: 35),
    (R: 30;  G: 80;  B: 200),
    (R: 220; G: 130; B: 30),
    (R: 70;  G: 170; B: 80),
    (R: 235; G: 80;  B: 170),
    (R: 35;  G: 55;  B: 140),
    (R: 120; G: 60;  B: 180),
    (R: 20;  G: 170; B: 180),
    (R: 235; G: 110; B: 90),
    (R: 120; G: 35;  B: 55),
    (R: 140; G: 220; B: 180)
  );

  RisoPalDefs: array[0..20] of TRisoPalDef = (
    (Name: 'Cyan + Magenta';                  Idx: (0, 1, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Cyan + Yellow';                    Idx: (0, 2, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Cyan + Black';                   Idx: (0, 3, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Magenta + Yellow';                  Idx: (1, 2, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Magenta + Black';                 Idx: (1, 3, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Yellow + Black';                   Idx: (2, 3, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Cyan + Magenta + Yellow';          Idx: (0, 1, 2, 0);   Dx: (0, 2, -1, 0); Dy: (0, 1, 2, 0);  Count: 3),
    (Name: 'Cyan + Magenta + Black';         Idx: (0, 1, 3, 0);   Dx: (0, 2, -1, 0); Dy: (0, 1, 2, 0);  Count: 3),
    (Name: 'Cyan + Yellow + Black';           Idx: (0, 2, 3, 0);   Dx: (0, 2, -1, 0); Dy: (0, 1, 2, 0);  Count: 3),
    (Name: 'Magenta + Yellow + Black';         Idx: (1, 2, 3, 0);   Dx: (0, 2, -1, 0); Dy: (0, 1, 2, 0);  Count: 3),
    (Name: 'Cyan + Magenta + Yellow + Black'; Idx: (0, 1, 2, 3);   Dx: (0, 2, -1, 1); Dy: (0, 1, 2, -2); Count: 4),
    (Name: 'Blue + Orange';         Idx: (4, 5, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Green + Pink';                 Idx: (6, 7, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Navy + Yellow';                Idx: (8, 2, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Purple + Yellow';                Idx: (9, 2, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Turquoise + Coral';             Idx: (10, 11, 0, 0); Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Maroon + Mint';                Idx: (12, 13, 0, 0); Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Navy + Pink';               Idx: (8, 7, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Green + Orange';           Idx: (6, 5, 0, 0);   Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Purple + Coral';             Idx: (9, 11, 0, 0);  Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2),
    (Name: 'Turquoise + Yellow';                Idx: (10, 2, 0, 0);  Dx: (0, 2, 0, 0);  Dy: (0, 1, 0, 0);  Count: 2)
  );

procedure RGBToHSV(R, G, B: Byte; out H, S, V: Double);
var
  MaxC, MinC, Delta: Double;
  Fr, Fg, Fb: Double;
begin
  Fr := R / 255.0;
  Fg := G / 255.0;
  Fb := B / 255.0;
  MaxC := Max(Max(Fr, Fg), Fb);
  MinC := Min(Min(Fr, Fg), Fb);
  Delta := MaxC - MinC;
  V := MaxC;
  if Delta = 0 then
  begin
    H := 0;
    S := 0;
  end
  else
  begin
    S := Delta / MaxC;
    if MaxC = Fr then
      H := 60.0 * (((Fg - Fb) / Delta))
    else if MaxC = Fg then
      H := 60.0 * (((Fb - Fr) / Delta) + 2.0)
    else
      H := 60.0 * (((Fr - Fg) / Delta) + 4.0);
    if H < 0 then H := H + 360.0;
  end;
end;

procedure ClearWhite(Lines: array of PRGBTripleArray; W, H: Integer);
var
  X, Y: Integer;
begin
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Lines[Y][X].R := 255;
      Lines[Y][X].G := 255;
      Lines[Y][X].B := 255;
    end;
end;

function GetRisoPaletteCount: Integer;
begin
  Result := Length(RisoPalDefs);
end;

function GetRisoPaletteName(Idx: Integer): string;
begin
  Result := T(RisoPalDefs[Idx].Name);
end;

function GetRisoPalette(Idx: Integer): TRisoPalette;
var
  N, I: Integer;
begin
  N := RisoPalDefs[Idx].Count;
  SetLength(Result, N);
  for I := 0 to N - 1 do
  begin
    Result[I].R := RisoColors[RisoPalDefs[Idx].Idx[I]].R;
    Result[I].G := RisoColors[RisoPalDefs[Idx].Idx[I]].G;
    Result[I].B := RisoColors[RisoPalDefs[Idx].Idx[I]].B;
    Result[I].Dx := RisoPalDefs[Idx].Dx[I];
    Result[I].Dy := RisoPalDefs[Idx].Dy[I];
  end;
end;

// Risografia V1 (p_RisoCoreV1 z image_fx_effects.hws:1623):
// separacja wg luminancji na pasma, offset per warstwa, raster radialny (d2/Dmax2, Cell >= 2).
procedure DoRisoV1(Bitmap: TBitmap; const Pal: TRisoPalette; CellMult: Integer = 1);
var
  W, H, N, B, X, Y, Sx, Sy, BandIdx: Integer;
  Cell, T: Integer;
  BandSpan, BandStart, Lum, BandPos: Double;
  Tile: TScreenTile;
  Src: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  N := Length(Pal);
  if (W = 0) or (H = 0) or (N = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  BandSpan := 256.0 / N;

  Cell := Max(2, Round(Sqrt(W * H) / 700.0) * CellMult);
  T := 4 * Cell;
  Tile := InitScreenTile(T);

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

    ClearWhite(DstLines, W, H);

    for B := 0 to N - 1 do
    begin
      BandStart := B * BandSpan;
      for Y := 0 to H - 1 do
      begin
        for X := 0 to W - 1 do
        begin
          Sx := X - Pal[B].Dx;
          Sy := Y - Pal[B].Dy;
          if (Sx >= 0) and (Sx < W) and (Sy >= 0) and (Sy < H) then
          begin
            Lum := (SrcLines[Sy][Sx].R * 299 + SrcLines[Sy][Sx].G * 587
                  + SrcLines[Sy][Sx].B * 114) / 1000.0;
            BandIdx := Trunc(Lum * N / 256.0);
            if BandIdx >= N then BandIdx := N - 1;
            if BandIdx = B then
            begin
              BandPos := (Lum - BandStart) / BandSpan;
              if BandPos < 0 then BandPos := 0;
              if BandPos > 1 then BandPos := 1;
              if BandPos < 1.0 - ScreenThresh(Tile, X, Y) then
              begin
                DstLines[Y][X].R := Pal[B].R;
                DstLines[Y][X].G := Pal[B].G;
                DstLines[Y][X].B := Pal[B].B;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    Src.Free;
  end;
end;

// Risografia V2 (p_RisoCoreV2 z image_fx_effects.hws:1676):
// separacja wg barwy (hue) z wagą odległości barw i nasycenia.
procedure DoRisoV2(Bitmap: TBitmap; const Pal: TRisoPalette; CellMult: Integer = 1);
var
  W, H, N, B, X, Y, Sx, Sy: Integer;
  Cell, T: Integer;
  HueDist, HueWeight, Falloff, Coverage, HsvH, HsvS, HsvV: Double;
  Tile: TScreenTile;
  BandHues: array of Double;
  Src: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  N := Length(Pal);
  if (W = 0) or (H = 0) or (N = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(BandHues, N);
  for B := 0 to N - 1 do
    RGBToHSV(Pal[B].R, Pal[B].G, Pal[B].B, BandHues[B], HsvS, HsvV);

  Cell := Max(2, Round(Sqrt(W * H) / 700.0) * CellMult);
  T := 4 * Cell;
  Tile := InitScreenTile(T);

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

    ClearWhite(DstLines, W, H);

    for B := 0 to N - 1 do
      for Y := 0 to H - 1 do
      begin
        for X := 0 to W - 1 do
        begin
          Sx := X - Pal[B].Dx;
          Sy := Y - Pal[B].Dy;
          if (Sx >= 0) and (Sx < W) and (Sy >= 0) and (Sy < H) then
          begin
            RGBToHSV(SrcLines[Sy][Sx].R, SrcLines[Sy][Sx].G,
              SrcLines[Sy][Sx].B, HsvH, HsvS, HsvV);
            HueDist := Abs(HsvH - BandHues[B]);
            if HueDist > 180 then HueDist := 360.0 - HueDist;
            if HsvS >= 0.05 then
            begin
              Falloff := 360.0 / N;
              HueWeight := (Falloff - HueDist) / Falloff;
              if HueWeight < 0 then HueWeight := 0;
            end
            else
            begin
              // Prawie-szare (S < 0.05): hue = szum kwantyzacji kanałów (RGBToHSV
              // dzieli przez Delta~0). Deterministyczny RÓWNY podział NA POZIOMIE
              // KOMÓRKI RASTRA: cały kafelek T×T należy do jednej warstwy
              // ((X div T + Y div T) mod N) — kropka zostaje gładkim, rosnącym
              // dyskiem (Thresh mierzy do środka WŁASNEGO kafelka X mod T, Y mod T,
              // więc dysk nigdy nie wychodzi poza swój kafelek), każda farba dostaje
              // 1/N komórek. NIE (X+Y) mod N (poziom piksela): rozbiłoby kropkę na
              // 1-px przekątne pasy wszystkich farb = tekstura "solankowa" (1px < T).
              if ((X div T) + (Y div T)) mod N = B then
                HueWeight := 1.0
              else
                HueWeight := 0.0;
            end;
            if HueWeight > 0 then
            begin
              Coverage := HueWeight * (1.0 - HsvV);
              if Coverage > ScreenThresh(Tile, X, Y) then
              begin
                DstLines[Y][X].R := Pal[B].R;
                DstLines[Y][X].G := Pal[B].G;
                DstLines[Y][X].B := Pal[B].B;
              end;
            end;
          end;
        end;
      end;
  finally
    Src.Free;
  end;
end;

// Risografia V3 (p_RisoCoreV3 z image_fx_effects.hws:1739):
// najbliższy kolor warstwy (RGB) + pokrycie wg luminancji.
procedure DoRisoV3(Bitmap: TBitmap; const Layers: array of TRisoColor);
var
  W, H, X, Y, I, BestI: Integer;
  Dr, Dg, BestD, D, L: Double;
  Coverage: Double;
  Src: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) or (Length(Layers) = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

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

    ClearWhite(DstLines, W, H);

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        BestI := 0;
        BestD := 999999;
        for I := 0 to Length(Layers) - 1 do
        begin
          Dr := SrcLines[Y][X].R - Layers[I].R;
          Dg := SrcLines[Y][X].G - Layers[I].G;
          D := SrcLines[Y][X].B - Layers[I].B;
          D := Dr * Dr + Dg * Dg + D * D;
          if D < BestD then
          begin
            BestD := D;
            BestI := I;
          end;
        end;
        L := SrcLines[Y][X].R * 0.299 + SrcLines[Y][X].G * 0.587
           + SrcLines[Y][X].B * 0.114;
        Coverage := 1.0 - L / 255.0;
        if Coverage > 0.1 then
        begin
          DstLines[Y][X].R := Byte(Trunc(Layers[BestI].R * Coverage + 255 * (1.0 - Coverage)));
          DstLines[Y][X].G := Byte(Trunc(Layers[BestI].G * Coverage + 255 * (1.0 - Coverage)));
          DstLines[Y][X].B := Byte(Trunc(Layers[BestI].B * Coverage + 255 * (1.0 - Coverage)));
        end;
      end;
  finally
    Src.Free;
  end;
end;

end.
