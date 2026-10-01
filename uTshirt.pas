unit uTshirt;

interface

uses
  Winapi.Windows, System.SysUtils, System.Math, System.Generics.Collections,
  Vcl.Graphics, uQuantize, uPixelEngine;

type
  TShirtColors = TArray<TColor>;

// 1. Posteryzacja — QuantizeBrush(64) + paleta greedy (count * min_d2)
//    + mapowanie pikseli na kolory palety. Bitmap zostaje zmapowany,
//    zwraca paletę (długość = min(N, unikalne kolory)).
procedure TshirtPosterize(Bitmap: TBitmap; N: Integer; var Palette: TShirtColors);

// Ekstrakcja reprezentatywnej palety z obrazu (kwantyzacja 64 + greedy
//    count * min_d2). Nie modyfikuje Bitmap, nie mapuje pikseli — źródło
//    domyślnych farb przy otwarciu dialogu (odpowiednik palety z
//    p_TshirtPosterize w nadruki.hws). Długość = min(N, unikalne kolory).
function TshirtExtractPalette(Bitmap: TBitmap; N: Integer): TShirtColors;

// 2. Mapowanie: pal[j] -> inks[j] (w miejscu).
procedure TshirtReplaceColors(Bitmap: TBitmap; const Palette, Inks: TShirtColors);

// 3. Oczyszczenie detalu — usuwanie regionów < MinArea, wypełnienie
//    najczęstszym kolorem sąsiada. Zwraca liczbę usuniętych pikseli.
function TshirtClean(Bitmap: TBitmap; MinArea: Integer): Integer;

// Biały -> kolor tkaniny ($F8F6F0).
procedure TshirtWhiteToFabric(Bitmap: TBitmap);

// Raster nadruku — kwantyzacja 64 kolorów (spójna z POSTERIZE) + najbliższa
//    farba z piksela SKWANTOWANEGO + sitodruk radialny (własny TTshirtTile,
//    kąt 45°, znormalizowany Dmax2 dla obrotu 45°, niezależny od wspólnego
//    TScreenTile): pokrycie Coverage = 1 - Lum/255 z jasności piksela
//    kwantowanego; piksel malowany, gdy Coverage >= progu kropki (TshirtThresh)
//    — ciemne obszary wypełnione w całości (lite plamy), jasne przejścia mają
//    strukturę punktu. CellMult = korektor (bias) Coverage, ±0.6: 0,25 -> więcej
//    tkaniny, 1,0 -> naturalne krycie, 4,0 -> pełne krycie. Kolor farby = posteryzacja.
procedure TshirtRender(Bitmap: TBitmap; const Inks: TShirtColors; CellMult: Double);

// Full-res apply (nielimitowana wersja posteryzacji) — QuantizeBrush(64),
//    każdy piksel -> najbliższa WYBRANA farba. Farby dyktują podział,
//    nie paleta oryginału. Używane po OK.
procedure TshirtMapToInks(Bitmap: TBitmap; const Inks: TShirtColors);

// HSV -> RGB (p_TshirtHSVToRGB z nadruki.hws:32). S, V w zakresie 0..255.
function TshirtHSVToRGB(H, S, V: Double): TColor;

// Format "R=r G=g B=b" (p_TshirtColorStr$ z nadruki.hws:11).
function TshirtColorStr(C: TColor): string;

implementation

type
  TColorFreq = record
    Color: Cardinal; // 24-bit $RRGGBB
    Count: Integer;
  end;

function PackRgb24(R, G, B: Byte): Cardinal; inline;
begin
  Result := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
end;

function Rgb24ToTColor(C: Cardinal): TColor; inline;
begin
  Result := RGB(Byte(C shr 16), Byte(C shr 8), Byte(C));
end;

function TColorToRgb24(C: TColor): Cardinal; inline;
begin
  Result := PackRgb24(Byte(C and $FF), Byte((C shr 8) and $FF), Byte((C shr 16) and $FF));
end;

function Rgb24R(C: Cardinal): Integer; inline;
begin
  Result := (C shr 16) and $FF;
end;

function Rgb24G(C: Cardinal): Integer; inline;
begin
  Result := (C shr 8) and $FF;
end;

function Rgb24B(C: Cardinal): Integer; inline;
begin
  Result := C and $FF;
end;

procedure SetPixel(L: PRGBTripleArray; X: Integer; C: Cardinal); inline;
begin
  L[X].R := Byte(Rgb24R(C));
  L[X].G := Byte(Rgb24G(C));
  L[X].B := Byte(Rgb24B(C));
end;

function GetPixel(L: PRGBTripleArray; X: Integer): Cardinal; inline;
begin
  Result := PackRgb24(L[X].R, L[X].G, L[X].B);
end;

function TshirtColorStr(C: TColor): string;
begin
  Result := Format('R=%d G=%d B=%d',
    [Byte(C and $FF), Byte((C shr 8) and $FF), Byte((C shr 16) and $FF)]);
end;

function TshirtHSVToRGB(H, S, V: Double): TColor;
var
  Sector: Integer;
  F, P, Q, T: Double;
  Rr, Gg, Bb: Double;
begin
  if S = 0 then
  begin
    Rr := V; Gg := V; Bb := V;
  end
  else
  begin
    Sector := Trunc(H / 60.0);
    F := H / 60.0 - Sector;
    P := V * (255.0 - S) / 255.0;
    Q := V * (255.0 - S * F) / 255.0;
    T := V * (255.0 - S * (1.0 - F)) / 255.0;
    case Sector of
      0: begin Rr := V; Gg := T; Bb := P; end;
      1: begin Rr := Q; Gg := V; Bb := P; end;
      2: begin Rr := P; Gg := V; Bb := T; end;
      3: begin Rr := P; Gg := Q; Bb := V; end;
      4: begin Rr := T; Gg := P; Bb := V; end;
    else
      begin Rr := V; Gg := P; Bb := Q; end;
    end;
  end;
  Result := RGB(Trunc(Rr + 0.5), Trunc(Gg + 0.5), Trunc(Bb + 0.5));
end;

function TshirtExtractPalette(Bitmap: TBitmap; N: Integer): TShirtColors;
var
  W, H, I, J, Total, PalMax, BestJ, P, K: Integer;
  MinD2, BestVal, Val: Double;
  Dr, Dg, Db, D2: Integer;
  Qb: TBitmap;
  Freq: TDictionary<Cardinal, Integer>;
  Keys: TArray<Cardinal>;
  ColList: array of TColorFreq;
  Used: array of Boolean;
  Tmp: TColorFreq;
  Lines: array of PRGBTripleArray;
  C, PC: Cardinal;
  PalRgb: array of Cardinal;
begin
  Result := nil;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) or (N <= 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  Qb := TBitmap.Create;
  try
    Qb.Assign(Bitmap);
    Qb.PixelFormat := pf24bit;
    DoQuantize(Qb, 64, False);

    Freq := TDictionary<Cardinal, Integer>.Create;
    try
      SetLength(Lines, H);
      for J := 0 to H - 1 do
        Lines[J] := Qb.ScanLine[J];
      for J := 0 to H - 1 do
        for I := 0 to W - 1 do
        begin
          C := GetPixel(Lines[J], I);
          if Freq.ContainsKey(C) then
            Freq[C] := Freq[C] + 1
          else
            Freq.Add(C, 1);
        end;

      Keys := Freq.Keys.ToArray;
      Total := Length(Keys);
      SetLength(ColList, Total);
      for I := 0 to Total - 1 do
      begin
        ColList[I].Color := Keys[I];
        ColList[I].Count := Freq[Keys[I]];
      end;

      // sortowanie wg count malejąco (selection sort, <=64 elementy)
      for I := 0 to Total - 2 do
        for J := I + 1 to Total - 1 do
          if ColList[J].Count > ColList[I].Count then
          begin
            Tmp := ColList[I];
            ColList[I] := ColList[J];
            ColList[J] := Tmp;
          end;

      PalMax := Min(N, Total);
      if PalMax = 0 then Exit;

      SetLength(PalRgb, PalMax);
      SetLength(Used, Total);
      PalRgb[0] := ColList[0].Color;
      Used[0] := True;

      for P := 1 to PalMax - 1 do
      begin
        BestJ := -1;
        BestVal := -1.0;
        for J := 0 to Total - 1 do
        begin
          if Used[J] then Continue;
          C := ColList[J].Color;
          MinD2 := 195075.0;
          for K := 0 to P - 1 do
          begin
            PC := PalRgb[K];
            Dr := Rgb24R(C) - Rgb24R(PC);
            Dg := Rgb24G(C) - Rgb24G(PC);
            Db := Rgb24B(C) - Rgb24B(PC);
            D2 := Dr * Dr + Dg * Dg + Db * Db;
            if D2 < MinD2 then MinD2 := D2;
          end;
          Val := ColList[J].Count * (MinD2 / 195075.0);
          if Val > BestVal then
          begin
            BestVal := Val;
            BestJ := J;
          end;
        end;
        if BestJ >= 0 then
        begin
          PalRgb[P] := ColList[BestJ].Color;
          Used[BestJ] := True;
        end;
      end;

      SetLength(Result, PalMax);
      for K := 0 to PalMax - 1 do
        Result[K] := Rgb24ToTColor(PalRgb[K]);
    finally
      Freq.Free;
    end;
  finally
    Qb.Free;
  end;
end;

procedure TshirtPosterize(Bitmap: TBitmap; N: Integer; var Palette: TShirtColors);
var
  W, H, I, J, Total, PalMax, BestJ, P, K: Integer;
  MinD2, BestVal, Val: Double;
  Dr, Dg, Db, D2: Integer;
  Qb: TBitmap;
  Freq: TDictionary<Cardinal, Integer>;
  Keys: TArray<Cardinal>;
  ColList: array of TColorFreq;
  Used: array of Boolean;
  Tmp: TColorFreq;
  Map: TDictionary<Cardinal, Cardinal>;
  Lines: array of PRGBTripleArray;
  DLines: array of PRGBTripleArray;
  C, PC, Mapped: Cardinal;
  PalRgb: array of Cardinal;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  Qb := TBitmap.Create;
  try
    Qb.Assign(Bitmap);
    Qb.PixelFormat := pf24bit;
    DoQuantize(Qb, 64, False);

    Freq := TDictionary<Cardinal, Integer>.Create;
    try
      SetLength(Lines, H);
      for J := 0 to H - 1 do
        Lines[J] := Qb.ScanLine[J];
      for J := 0 to H - 1 do
        for I := 0 to W - 1 do
        begin
          C := GetPixel(Lines[J], I);
          if Freq.ContainsKey(C) then
            Freq[C] := Freq[C] + 1
          else
            Freq.Add(C, 1);
        end;

      Keys := Freq.Keys.ToArray;
      Total := Length(Keys);
      SetLength(ColList, Total);
      for I := 0 to Total - 1 do
      begin
        ColList[I].Color := Keys[I];
        ColList[I].Count := Freq[Keys[I]];
      end;

      // sortowanie wg count malejąco (selection sort, <=64 elementy)
      for I := 0 to Total - 2 do
        for J := I + 1 to Total - 1 do
          if ColList[J].Count > ColList[I].Count then
          begin
            Tmp := ColList[I];
            ColList[I] := ColList[J];
            ColList[J] := Tmp;
          end;

      PalMax := Min(N, Total);
      if PalMax = 0 then Exit;

      SetLength(PalRgb, PalMax);
      SetLength(Used, Total);
      PalRgb[0] := ColList[0].Color;
      Used[0] := True;

      for P := 1 to PalMax - 1 do
      begin
        BestJ := -1;
        BestVal := -1.0;
        for J := 0 to Total - 1 do
        begin
          if Used[J] then Continue;
          C := ColList[J].Color;
          MinD2 := 195075.0;
          for K := 0 to P - 1 do
          begin
            PC := PalRgb[K];
            Dr := Rgb24R(C) - Rgb24R(PC);
            Dg := Rgb24G(C) - Rgb24G(PC);
            Db := Rgb24B(C) - Rgb24B(PC);
            D2 := Dr * Dr + Dg * Dg + Db * Db;
            if D2 < MinD2 then MinD2 := D2;
          end;
          Val := ColList[J].Count * (MinD2 / 195075.0);
          if Val > BestVal then
          begin
            BestVal := Val;
            BestJ := J;
          end;
        end;
        if BestJ >= 0 then
        begin
          PalRgb[P] := ColList[BestJ].Color;
          Used[BestJ] := True;
        end;
      end;

      // mapowanie: każdy kolor -> najbliższy kolor palety
      Map := TDictionary<Cardinal, Cardinal>.Create;
      try
        for J := 0 to Total - 1 do
        begin
          C := ColList[J].Color;
          MinD2 := 195075.0;
          Mapped := PalRgb[0];
          for K := 0 to PalMax - 1 do
          begin
            PC := PalRgb[K];
            Dr := Rgb24R(C) - Rgb24R(PC);
            Dg := Rgb24G(C) - Rgb24G(PC);
            Db := Rgb24B(C) - Rgb24B(PC);
            D2 := Dr * Dr + Dg * Dg + Db * Db;
            if D2 < MinD2 then
            begin
              MinD2 := D2;
              Mapped := PC;
            end;
          end;
          Map.Add(C, Mapped);
        end;

        // zapis zmapowanych pikseli do Bitmap (czytaj z Qb, pisz do Bitmap)
        SetLength(DLines, H);
        for J := 0 to H - 1 do
          DLines[J] := Bitmap.ScanLine[J];
        for J := 0 to H - 1 do
        begin
          Lines[J] := Qb.ScanLine[J];
          for I := 0 to W - 1 do
          begin
            C := GetPixel(Lines[J], I);
            if Map.TryGetValue(C, Mapped) then
              SetPixel(DLines[J], I, Mapped);
          end;
        end;

        SetLength(Palette, PalMax);
        for K := 0 to PalMax - 1 do
          Palette[K] := Rgb24ToTColor(PalRgb[K]);
      finally
        Map.Free;
      end;
    finally
      Freq.Free;
    end;
  finally
    Qb.Free;
  end;
end;

procedure TshirtReplaceColors(Bitmap: TBitmap; const Palette, Inks: TShirtColors);
var
  W, H, X, Y, J: Integer;
  PalRgb: array of Cardinal;
  InkRgb: array of Cardinal;
  Lines: array of PRGBTripleArray;
  C: Cardinal;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Length(Inks) = 0 then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(PalRgb, Length(Palette));
  SetLength(InkRgb, Length(Inks));
  for J := 0 to Length(Palette) - 1 do
  begin
    PalRgb[J] := TColorToRgb24(Palette[J]);
    if J < Length(Inks) then
      InkRgb[J] := TColorToRgb24(Inks[J]);
  end;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
  begin
    Lines[Y] := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      C := GetPixel(Lines[Y], X);
      for J := 0 to Length(PalRgb) - 1 do
        if PalRgb[J] = C then
        begin
          if J < Length(InkRgb) then
            SetPixel(Lines[Y], X, InkRgb[J]);
          Break;
        end;
    end;
  end;
end;

function TshirtClean(Bitmap: TBitmap; MinArea: Integer): Integer;
var
  W, H, X, Y, Idx, Cx, Cy, Nidx, Sp, NextLab, Sz, I, L, Np, Pi, BestN, Nid: Integer;
  Color, Nc, BestC: Cardinal;
  Lines: array of PRGBTripleArray;
  Labels: array of Integer;
  RegSize: array of Integer;
  RegCol: array of Cardinal;
  RegPix: array of array of Integer;
  Stack: array of Integer;
  Neigh: TDictionary<Cardinal, Integer>;
begin
  Result := 0;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if MinArea <= 1 then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  SetLength(Labels, W * H);
  for I := 0 to W * H - 1 do
    Labels[I] := -1;

  NextLab := 0;
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Idx := Y * W + X;
      if Labels[Idx] >= 0 then Continue;
      Color := GetPixel(Lines[Y], X);

      SetLength(Stack, 8);
      Sp := 0;
      Stack[Sp] := Idx;
      Inc(Sp);
      Labels[Idx] := NextLab;
      Sz := 1;

      SetLength(RegPix, NextLab + 1);
      SetLength(RegPix[NextLab], 8);
      RegPix[NextLab][0] := Idx;
      Np := 1;

      while Sp > 0 do
      begin
        Dec(Sp);
        Idx := Stack[Sp];
        Cx := Idx - (Idx div W) * W;
        Cy := (Idx - Cx) div W;

        // lewy
        if Cx > 0 then
        begin
          Nidx := Idx - 1;
          if (Labels[Nidx] < 0) and (GetPixel(Lines[Nidx div W], Nidx mod W) = Color) then
          begin
            Labels[Nidx] := NextLab;
            if Sp >= Length(Stack) then SetLength(Stack, Length(Stack) * 2);
            Stack[Sp] := Nidx;
            Inc(Sp);
            Inc(Sz);
            if Sz < MinArea then
            begin
              if Np >= Length(RegPix[NextLab]) then SetLength(RegPix[NextLab], Length(RegPix[NextLab]) * 2);
              RegPix[NextLab][Np] := Nidx;
              Inc(Np);
            end;
          end;
        end;
        // prawy
        if Cx < W - 1 then
        begin
          Nidx := Idx + 1;
          if (Labels[Nidx] < 0) and (GetPixel(Lines[Nidx div W], Nidx mod W) = Color) then
          begin
            Labels[Nidx] := NextLab;
            if Sp >= Length(Stack) then SetLength(Stack, Length(Stack) * 2);
            Stack[Sp] := Nidx;
            Inc(Sp);
            Inc(Sz);
            if Sz < MinArea then
            begin
              if Np >= Length(RegPix[NextLab]) then SetLength(RegPix[NextLab], Length(RegPix[NextLab]) * 2);
              RegPix[NextLab][Np] := Nidx;
              Inc(Np);
            end;
          end;
        end;
        // góra
        if Cy > 0 then
        begin
          Nidx := Idx - W;
          if (Labels[Nidx] < 0) and (GetPixel(Lines[Nidx div W], Nidx mod W) = Color) then
          begin
            Labels[Nidx] := NextLab;
            if Sp >= Length(Stack) then SetLength(Stack, Length(Stack) * 2);
            Stack[Sp] := Nidx;
            Inc(Sp);
            Inc(Sz);
            if Sz < MinArea then
            begin
              if Np >= Length(RegPix[NextLab]) then SetLength(RegPix[NextLab], Length(RegPix[NextLab]) * 2);
              RegPix[NextLab][Np] := Nidx;
              Inc(Np);
            end;
          end;
        end;
        // dół
        if Cy < H - 1 then
        begin
          Nidx := Idx + W;
          if (Labels[Nidx] < 0) and (GetPixel(Lines[Nidx div W], Nidx mod W) = Color) then
          begin
            Labels[Nidx] := NextLab;
            if Sp >= Length(Stack) then SetLength(Stack, Length(Stack) * 2);
            Stack[Sp] := Nidx;
            Inc(Sp);
            Inc(Sz);
            if Sz < MinArea then
            begin
              if Np >= Length(RegPix[NextLab]) then SetLength(RegPix[NextLab], Length(RegPix[NextLab]) * 2);
              RegPix[NextLab][Np] := Nidx;
              Inc(Np);
            end;
          end;
        end;
      end;

      SetLength(RegSize, NextLab + 1);
      SetLength(RegCol, NextLab + 1);
      RegSize[NextLab] := Sz;
      RegCol[NextLab] := Color;
      if Sz < MinArea then
        SetLength(RegPix[NextLab], Np);
      Inc(NextLab);
    end;

  // usuwanie małych regionów
  Neigh := TDictionary<Cardinal, Integer>.Create;
  try
    for L := 0 to NextLab - 1 do
    begin
      if RegSize[L] >= MinArea then Continue;
      Np := Length(RegPix[L]);
      BestC := RegCol[L];
      BestN := 0;
      Neigh.Clear;
      for Pi := 0 to Np - 1 do
      begin
        Idx := RegPix[L][Pi];
        Cx := Idx - (Idx div W) * W;
        Cy := (Idx - Cx) div W;
        if Cx > 0 then
        begin
          Nid := Idx - 1;
          if (Labels[Nid] >= 0) and (RegSize[Labels[Nid]] >= MinArea) then
          begin
            Nc := GetPixel(Lines[Nid div W], Nid mod W);
            if Neigh.ContainsKey(Nc) then
              Neigh[Nc] := Neigh[Nc] + 1
            else
              Neigh.Add(Nc, 1);
            if Neigh[Nc] > BestN then
            begin
              BestN := Neigh[Nc];
              BestC := Nc;
            end;
          end;
        end;
        if Cx < W - 1 then
        begin
          Nid := Idx + 1;
          if (Labels[Nid] >= 0) and (RegSize[Labels[Nid]] >= MinArea) then
          begin
            Nc := GetPixel(Lines[Nid div W], Nid mod W);
            if Neigh.ContainsKey(Nc) then
              Neigh[Nc] := Neigh[Nc] + 1
            else
              Neigh.Add(Nc, 1);
            if Neigh[Nc] > BestN then
            begin
              BestN := Neigh[Nc];
              BestC := Nc;
            end;
          end;
        end;
        if Cy > 0 then
        begin
          Nid := Idx - W;
          if (Labels[Nid] >= 0) and (RegSize[Labels[Nid]] >= MinArea) then
          begin
            Nc := GetPixel(Lines[Nid div W], Nid mod W);
            if Neigh.ContainsKey(Nc) then
              Neigh[Nc] := Neigh[Nc] + 1
            else
              Neigh.Add(Nc, 1);
            if Neigh[Nc] > BestN then
            begin
              BestN := Neigh[Nc];
              BestC := Nc;
            end;
          end;
        end;
        if Cy < H - 1 then
        begin
          Nid := Idx + W;
          if (Labels[Nid] >= 0) and (RegSize[Labels[Nid]] >= MinArea) then
          begin
            Nc := GetPixel(Lines[Nid div W], Nid mod W);
            if Neigh.ContainsKey(Nc) then
              Neigh[Nc] := Neigh[Nc] + 1
            else
              Neigh.Add(Nc, 1);
            if Neigh[Nc] > BestN then
            begin
              BestN := Neigh[Nc];
              BestC := Nc;
            end;
          end;
        end;
      end;
      for Pi := 0 to Np - 1 do
      begin
        Idx := RegPix[L][Pi];
        SetPixel(Lines[Idx div W], Idx mod W, BestC);
      end;
      Result := Result + Np;
    end;
  finally
    Neigh.Free;
  end;
end;

procedure TshirtWhiteToFabric(Bitmap: TBitmap);
var
  W, H, X, Y: Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;
  SetLength(Lines, H);
  for Y := 0 to H - 1 do
  begin
    Lines[Y] := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
      if (Lines[Y][X].R = 255) and (Lines[Y][X].G = 255) and (Lines[Y][X].B = 255) then
        SetPixel(Lines[Y], X, PackRgb24(248, 246, 240));
  end;
end;

// ===== Lokalny raster nadruku (niezależny od wspólnego TScreenTile) =====
// Wspólny ScreenThresh normalizuje przez Dmax2 = Sqr(Center)+Sqr(Center), co
// jest poprawne tylko dla kąta 0°; dla obrotu 45° narożnik kafla leży dalej
// od środka, więc część pikseli ma próg >1.0 i NIGDY nie jest malowana
// (stała siatka dziur = "serwetka"). Tu Dmax2 = 2*Sqr(T-Center) jest analityczną
// GÓRNĄ granicą odległości^2 fazy, więc próg nigdy nie przekracza 1.0 i
// Coverage=1.0 pokrywa 100% kafla (bez dziur).
// To OSOBNA logika nadruku — wspólny rdzeń uPixelEngine pozostaje nietknięty.

type
  TTshirtTile = record
    T: Integer;
    Center: Double;
    Dmax2: Double;
  end;

function TshirtInitTile(T: Integer): TTshirtTile;
begin
  Result.T := T;
  Result.Center := (T - 1) / 2.0;
  // Analityczna GÓRNA granica odległości^2 fazy od środka: |Fu-Center| <
  // T-Center (faza zawsze < T), więc maksimum = 2*Sqr(T-Center). Gwarantuje,
  // że próg nigdy nie przekroczy 1.0 i Coverage=1.0 pokrywa 100% kafla.
  Result.Dmax2 := 2 * Sqr(T - Result.Center);
end;

function TshirtThresh(const Tile: TTshirtTile; X, Y: Integer): Double;
const
  SinA = 0.7071067811865475;
  CosA = 0.7071067811865475;
var
  U, V, Fu, Fv: Double;
begin
  U := CosA * X + SinA * Y;
  V := -SinA * X + CosA * Y;
  Fu := U - Tile.T * Floor(U / Tile.T);
  Fv := V - Tile.T * Floor(V / Tile.T);
  Result := (Sqr(Fu - Tile.Center) + Sqr(Fv - Tile.Center)) / Tile.Dmax2;
end;

procedure TshirtRender(Bitmap: TBitmap; const Inks: TShirtColors; CellMult: Double);
var
  W, H, X, Y, N, I, BestI, T: Integer;
  Dr, Dg, Db, D, BestD, Lum, Coverage, Bias: Double;
  Qb, SrcBmp: TBitmap;
  QLines, DstLines: array of PRGBTripleArray;
  InkRgb: array of Cardinal;
  Tile: TTshirtTile;
  Painted: Boolean;
  Qpx: Cardinal;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  N := Length(Inks);
  if (W = 0) or (H = 0) or (N < 2) then Exit;
  Bitmap.PixelFormat := pf24bit;

  // Sitodruk radialny (własny TTshirtTile, kąt 45°) — bez siatki kwadratów.
  // Krycie Coverage = 1 - Lum/255 z jasności piksela kwantowanego: ciemne
  // obszary dążą do 100% wypełnienia (lite plamy). CellMult działa jako
  // KOREKTOR (bias) dodawany do Coverage — przesunięcie, nie mnożenie,
  // żeby nie wybijać dziur w cieniach: 0,25 -> więcej tkaniny, 1,0 -> naturalne
  // krycie, 4,0 -> pełne krycie. Rozmiar kropki T jest bazowy (z wielkości
  // obrazu) i niezależny od suwaka.
  T := Max(4, Round(Sqrt(W * H) / 700.0) * 4);
  Tile := TshirtInitTile(T);
  Bias := (CellMult - 1.0) * 0.6;                // korektor krycia, ±0.6

  SetLength(InkRgb, N);
  for I := 0 to N - 1 do
    InkRgb[I] := TColorToRgb24(Inks[I]);

  Qb := TBitmap.Create;
  SrcBmp := TBitmap.Create;
  try
    SrcBmp.Assign(Bitmap);
    SrcBmp.PixelFormat := pf24bit;
    Qb.Assign(SrcBmp);
    Qb.PixelFormat := pf24bit;
    // Kwantyzacja 64 kolorów (spójna z POSTERIZE) jako etap pośredni;
    // farba wybierana później wg najbliższego dystansu do ink.
    DoQuantize(Qb, 64, False);

    SetLength(QLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      QLines[Y] := Qb.ScanLine[Y];
      DstLines[Y] := Bitmap.ScanLine[Y];
    end;

    // tło tkaniny
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
        SetPixel(DstLines[Y], X, PackRgb24(248, 246, 240));

    // Raster sitodruku radialnego (TTshirtTile, kąt 45°): najbliższa farba
    // (BestI) liczona dla piksela SKWANTOWANEGO (QLines). Pokrycie
    // Coverage = 1 - Lum/255 z jasności piksela kwantowanego skorygowane
    // suwakiem (Bias, przesunięcie — nie mnożenie, więc cienie nie znikają);
    // piksel malowany, gdy Coverage >= progu kropki (TshirtThresh). Kolor
    // farby = posteryzacja (BestI), tkanina w prześwicie.
    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        BestI := -1;
        BestD := 1000000.0;
        Qpx := GetPixel(QLines[Y], X);
        for I := 0 to N - 1 do
        begin
          Dr := Rgb24R(Qpx) - Rgb24R(InkRgb[I]);
          Dg := Rgb24G(Qpx) - Rgb24G(InkRgb[I]);
          Db := Rgb24B(Qpx) - Rgb24B(InkRgb[I]);
          D := Dr * Dr + Dg * Dg + Db * Db;
          if D < BestD then
          begin
            BestD := D;
            BestI := I;
          end;
        end;
        if BestI >= 0 then
        begin
          Lum := (Rgb24R(Qpx) * 299 + Rgb24G(Qpx) * 587 + Rgb24B(Qpx) * 114) / 1000.0;
          if Lum < 0 then Lum := 0;
          if Lum > 255 then Lum := 255;
          Coverage := 1.0 - Lum / 255.0;
          Coverage := Coverage + Bias;
          if Coverage < 0 then Coverage := 0;
          if Coverage > 1 then Coverage := 1;
          Painted := Coverage >= TshirtThresh(Tile, X, Y);
          if Painted then
            SetPixel(DstLines[Y], X, InkRgb[BestI]);
        end;
      end;
    end;
  finally
    Qb.Free;
    SrcBmp.Free;
  end;
end;

procedure TshirtMapToInks(Bitmap: TBitmap; const Inks: TShirtColors);
var
  W, H, X, Y, I, N, BestI: Integer;
  MinD2, D2: Double;
  Dr, Dg, Db: Integer;
  Qb: TBitmap;
  QLines, Lines: array of PRGBTripleArray;
  InkRgb: array of Cardinal;
  Lookup: TDictionary<Cardinal, Cardinal>;
  C, BestC: Cardinal;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  N := Length(Inks);
  if (W = 0) or (H = 0) or (N = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(InkRgb, N);
  for I := 0 to N - 1 do
    InkRgb[I] := TColorToRgb24(Inks[I]);

  Qb := TBitmap.Create;
  try
    Qb.Assign(Bitmap);
    Qb.PixelFormat := pf24bit;
    DoQuantize(Qb, 64, False);

    SetLength(QLines, H);
    SetLength(Lines, H);
    for Y := 0 to H - 1 do
    begin
      QLines[Y] := Qb.ScanLine[Y];
      Lines[Y] := Bitmap.ScanLine[Y];
    end;

    Lookup := TDictionary<Cardinal, Cardinal>.Create;
    try
      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
        begin
          C := GetPixel(QLines[Y], X);
          if Lookup.ContainsKey(C) then Continue;
          MinD2 := 195075.0;
          BestI := 0;
          for I := 0 to N - 1 do
          begin
            Dr := Rgb24R(C) - Rgb24R(InkRgb[I]);
            Dg := Rgb24G(C) - Rgb24G(InkRgb[I]);
            Db := Rgb24B(C) - Rgb24B(InkRgb[I]);
            D2 := Dr * Dr + Dg * Dg + Db * Db;
            if D2 < MinD2 then
            begin
              MinD2 := D2;
              BestI := I;
            end;
          end;
          Lookup.Add(C, InkRgb[BestI]);
        end;

      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
        begin
          C := GetPixel(QLines[Y], X);
          if Lookup.TryGetValue(C, BestC) then
            SetPixel(Lines[Y], X, BestC);
        end;
    finally
      Lookup.Free;
    end;
  finally
    Qb.Free;
  end;
end;

end.
