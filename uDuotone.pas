unit uDuotone;

interface

uses
  System.SysUtils, System.Math, Vcl.Graphics, uQuantize;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

function ClampByte(V: Double): Byte;
procedure DoDuotone(Bitmap: TBitmap; Color1, Color2: TColor);
procedure DoTritone(Bitmap: TBitmap; Color1, Color2, Color3: TColor);
procedure DoQuadTone(Bitmap: TBitmap; Color1, Color2, Color3, Color4: TColor);
function PhotoDefaultColors(Bitmap: TBitmap; ColorCount: Integer): TArray<TColor>;

implementation

function ColorR(C: TColor): Byte; inline;
begin Result := C and $FF; end;

function ColorG(C: TColor): Byte; inline;
begin Result := (C shr 8) and $FF; end;

function ColorB(C: TColor): Byte; inline;
begin Result := (C shr 16) and $FF; end;

function ClampByte(V: Double): Byte;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Round(V);
end;

// Rzeczywisty zakres jasności zdjęcia (percentyle PctLo/PctHi histogramu lumy).
// Gradient rozkłada progi w tym zakresie, nie na sztywnej skali 0-255 — dzięki
// temu ciemne/jasne zdjęcia wykorzystują pełną skalę kolorów.
procedure LumaRangePct(Bitmap: TBitmap; PctLo, PctHi: Double; out Lo, Hi: Double);
var
  W, H, X, Y, I: Integer;
  Row: PRGBTripleArray;
  Cnt: array[0..255] of Integer;
  Total, Acc, Target: Int64;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  Lo := 0;
  Hi := 255;
  if (W = 0) or (H = 0) then Exit;

  FillChar(Cnt, SizeOf(Cnt), 0);
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
      Inc(Cnt[(Row[X].R * 299 + Row[X].G * 587 + Row[X].B * 114) div 1000]);
  end;
  Total := W * H;

  Target := Round((Total * PctLo) / 100.0);
  Acc := 0;
  for I := 0 to 255 do
  begin
    Acc := Acc + Cnt[I];
    if Acc >= Target then
    begin
      Lo := I;
      Break;
    end;
  end;

  Target := Round((Total * PctHi) / 100.0);
  Acc := 0;
  for I := 0 to 255 do
  begin
    Acc := Acc + Cnt[I];
    if Acc >= Target then
    begin
      Hi := I;
      Break;
    end;
  end;

  if Hi <= Lo then
  begin
    Lo := 0;
    Hi := 255;
  end;
end;

procedure DoDuotone(Bitmap: TBitmap; Color1, Color2: TColor);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  sr, sg, sb, dr, dg, db: Single;
  gray, t, Lo, Hi: Double;
begin
  sr := ColorR(Color1);
  sg := ColorG(Color1);
  sb := ColorB(Color1);
  dr := ColorR(Color2) - sr;
  dg := ColorG(Color2) - sg;
  db := ColorB(Color2) - sb;

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  LumaRangePct(Bitmap, 5, 95, Lo, Hi);

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      gray := Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114;
      t := (gray - Lo) / (Hi - Lo);
      if t < 0 then t := 0
      else if t > 1 then t := 1;
      Row[X].R := ClampByte(sr + dr * t);
      Row[X].G := ClampByte(sg + dg * t);
      Row[X].B := ClampByte(sb + db * t);
    end;
  end;
end;

procedure DoTritone(Bitmap: TBitmap; Color1, Color2, Color3: TColor);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  c1r, c1g, c1b, c2r, c2g, c2b, c3r, c3g, c3b: Single;
  gray, t, s, Lo, Hi: Double;
  r, g, b: Double;
begin
  c1r := ColorR(Color1); c1g := ColorG(Color1); c1b := ColorB(Color1);
  c2r := ColorR(Color2); c2g := ColorG(Color2); c2b := ColorB(Color2);
  c3r := ColorR(Color3); c3g := ColorG(Color3); c3b := ColorB(Color3);

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  LumaRangePct(Bitmap, 5, 95, Lo, Hi);

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      gray := Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114;
      t := (gray - Lo) / (Hi - Lo);
      if t < 0 then t := 0
      else if t > 1 then t := 1;

      if t < 0.5 then
      begin
        s := t * 2.0;
        r := c1r + (c2r - c1r) * s;
        g := c1g + (c2g - c1g) * s;
        b := c1b + (c2b - c1b) * s;
      end
      else
      begin
        s := (t - 0.5) * 2.0;
        r := c2r + (c3r - c2r) * s;
        g := c2g + (c3g - c2g) * s;
        b := c2b + (c3b - c2b) * s;
      end;

      Row[X].R := ClampByte(r);
      Row[X].G := ClampByte(g);
      Row[X].B := ClampByte(b);
    end;
  end;
end;

procedure DoQuadTone(Bitmap: TBitmap; Color1, Color2, Color3, Color4: TColor);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  c1r, c1g, c1b, c2r, c2g, c2b, c3r, c3g, c3b, c4r, c4g, c4b: Single;
  gray, t, s, Lo, Hi: Double;
  r, g, b: Double;
begin
  c1r := ColorR(Color1); c1g := ColorG(Color1); c1b := ColorB(Color1);
  c2r := ColorR(Color2); c2g := ColorG(Color2); c2b := ColorB(Color2);
  c3r := ColorR(Color3); c3g := ColorG(Color3); c3b := ColorB(Color3);
  c4r := ColorR(Color4); c4g := ColorG(Color4); c4b := ColorB(Color4);

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  LumaRangePct(Bitmap, 5, 95, Lo, Hi);

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      gray := Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114;
      t := (gray - Lo) / (Hi - Lo);
      if t < 0 then t := 0
      else if t > 1 then t := 1;

      if t < 0.33 then
      begin
        s := t * 3.0;
        r := c1r + (c2r - c1r) * s;
        g := c1g + (c2g - c1g) * s;
        b := c1b + (c2b - c1b) * s;
      end
      else if t < 0.66 then
      begin
        s := (t - 0.33) * 3.0;
        r := c2r + (c3r - c2r) * s;
        g := c2g + (c3g - c2g) * s;
        b := c2b + (c3b - c2b) * s;
      end
      else
      begin
        s := (t - 0.66) / 0.34;
        r := c3r + (c4r - c3r) * s;
        g := c3g + (c4g - c3g) * s;
        b := c3b + (c4b - c3b) * s;
      end;

      Row[X].R := ClampByte(r);
      Row[X].G := ClampByte(g);
      Row[X].B := ClampByte(b);
    end;
  end;
end;

function PhotoDefaultColors(Bitmap: TBitmap; ColorCount: Integer): TArray<TColor>;
var
  I, J: Integer;
  Tmp: Double;
  TmpC: TColor;
  Luma: TArray<Double>;
begin
  SetLength(Result, 0);
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  Result := QuantizePalette(Bitmap, ColorCount);
  if Length(Result) < 2 then Exit;

  SetLength(Luma, Length(Result));
  for I := 0 to Length(Result) - 1 do
    Luma[I] := ColorR(Result[I]) * 0.299 + ColorG(Result[I]) * 0.587 + ColorB(Result[I]) * 0.114;

  for I := 1 to Length(Result) - 1 do
  begin
    TmpC := Result[I];
    Tmp := Luma[I];
    J := I - 1;
    while (J >= 0) and (Luma[J] > Tmp) do
    begin
      Result[J + 1] := Result[J];
      Luma[J + 1] := Luma[J];
      Dec(J);
    end;
    Result[J + 1] := TmpC;
    Luma[J + 1] := Tmp;
  end;
end;

end.
