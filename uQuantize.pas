unit uQuantize;

interface

uses
  Vcl.Graphics, System.SysUtils;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

// Kwantyzacja median cut. Zgodne z Hollywood QuantizeBrush({Colors = N}).
procedure DoQuantize(Bitmap: TBitmap; Colors: Integer; Dither: Boolean);

// Zwraca paletę `Colors` kolorów wyliczoną median cut (bez modyfikowania Bitmap
// i bez mapowania pikseli). Wykorzystywana do domyślnych kolorów DuoTone.
function QuantizePalette(Bitmap: TBitmap; Colors: Integer): TArray<TColor>;

implementation

uses
  System.Generics.Collections, System.Math;

type
  TColorCount = record
    R, G, B, C: Integer;
  end;

  TRGBBox = record
    Idxs: array of Integer;
    Cnt: Integer;
  end;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure QSortIds(var Idxs: array of Integer; Lo, Hi: Integer;
  const Cols: array of TColorCount; Ch: Integer); forward;

function QuantizePalette(Bitmap: TBitmap; Colors: Integer): TArray<TColor>;
// Median cut do palety — tylko histogram + podział na pudełka + średnia ważona,
// bez mapowania pikseli. Identyczna logika jak w DoQuantize (kroki 1-3),
// więc paleta odpowiada temu, co widzi nadruk przy Colors=64.
var
  W, H, X, Y, I, J, N, BoxIdx, BestBox, BestCnt, SplitAt, Mid, CntSum: Integer;
  Row: PRGBTripleArray;
  Key: Cardinal;
  Hist: TDictionary<Cardinal, Integer>;
  Cols: array of TColorCount;
  Boxes: array of TRGBBox;
  Pal: array of TColorCount;
  Ch, R, G, B, Rmin, Gmin, Bmin, Rmax, Gmax, Bmax: Integer;
  Bi: Integer;
begin
  SetLength(Result, 0);
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Colors := Max(2, Min(64, Colors));

  Hist := TDictionary<Cardinal, Integer>.Create;
  try
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Key := (Cardinal(Row[X].R) shl 16) or (Cardinal(Row[X].G) shl 8) or Cardinal(Row[X].B);
        if Hist.ContainsKey(Key) then
          Hist[Key] := Hist[Key] + 1
        else
          Hist.Add(Key, 1);
      end;
    end;

    N := Hist.Count;
    if N = 0 then Exit;

    SetLength(Cols, N);
    I := 0;
    for Key in Hist.Keys do
    begin
      Cols[I].R := (Key shr 16) and $FF;
      Cols[I].G := (Key shr 8) and $FF;
      Cols[I].B := Key and $FF;
      Cols[I].C := Hist[Key];
      Inc(I);
    end;

    SetLength(Boxes, 1);
    SetLength(Boxes[0].Idxs, N);
    Boxes[0].Cnt := N;
    for I := 0 to N - 1 do
      Boxes[0].Idxs[I] := I;

    while Length(Boxes) < Colors do
    begin
      BestBox := 0; BestCnt := -1;
      for I := 0 to Length(Boxes) - 1 do
        if Boxes[I].Cnt > BestCnt then
        begin
          BestCnt := Boxes[I].Cnt;
          BestBox := I;
        end;
      if BestCnt < 2 then Break;

      Rmin := 255; Gmin := 255; Bmin := 255;
      Rmax := 0; Gmax := 0; Bmax := 0;
      for J := 0 to Boxes[BestBox].Cnt - 1 do
      begin
        I := Boxes[BestBox].Idxs[J];
        if Cols[I].R < Rmin then Rmin := Cols[I].R;
        if Cols[I].G < Gmin then Gmin := Cols[I].G;
        if Cols[I].B < Bmin then Bmin := Cols[I].B;
        if Cols[I].R > Rmax then Rmax := Cols[I].R;
        if Cols[I].G > Gmax then Gmax := Cols[I].G;
        if Cols[I].B > Bmax then Bmax := Cols[I].B;
      end;
      Ch := 0;
      if (Gmax - Gmin) > (Rmax - Rmin) then Ch := 1;
      if (Bmax - Bmin) > (Gmax - Gmin) then Ch := 2;

      QSortIds(Boxes[BestBox].Idxs, 0, Boxes[BestBox].Cnt - 1, Cols, Ch);

      CntSum := 0;
      for J := 0 to Boxes[BestBox].Cnt - 1 do
        CntSum := CntSum + Cols[Boxes[BestBox].Idxs[J]].C;
      Mid := CntSum div 2;
      SplitAt := 0; CntSum := 0;
      for J := 0 to Boxes[BestBox].Cnt - 2 do
      begin
        CntSum := CntSum + Cols[Boxes[BestBox].Idxs[J]].C;
        if CntSum >= Mid then
        begin
          SplitAt := J + 1;
          Break;
        end;
      end;
      if SplitAt <= 0 then SplitAt := Boxes[BestBox].Cnt div 2;
      if SplitAt <= 0 then SplitAt := 1;
      if SplitAt >= Boxes[BestBox].Cnt then SplitAt := Boxes[BestBox].Cnt div 2;
      if SplitAt <= 0 then Break;

      BoxIdx := Length(Boxes);
      SetLength(Boxes, BoxIdx + 1);
      SetLength(Boxes[BoxIdx].Idxs, Boxes[BestBox].Cnt - SplitAt);
      Boxes[BoxIdx].Cnt := Boxes[BestBox].Cnt - SplitAt;
      for J := 0 to Boxes[BoxIdx].Cnt - 1 do
        Boxes[BoxIdx].Idxs[J] := Boxes[BestBox].Idxs[SplitAt + J];
      Boxes[BestBox].Cnt := SplitAt;
      SetLength(Boxes[BestBox].Idxs, SplitAt);
    end;

    SetLength(Pal, Length(Boxes));
    for I := 0 to Length(Boxes) - 1 do
    begin
      CntSum := 0; R := 0; G := 0; B := 0;
      for J := 0 to Boxes[I].Cnt - 1 do
      begin
        Bi := Boxes[I].Idxs[J];
        R := R + Cols[Bi].R * Cols[Bi].C;
        G := G + Cols[Bi].G * Cols[Bi].C;
        B := B + Cols[Bi].B * Cols[Bi].C;
        CntSum := CntSum + Cols[Bi].C;
      end;
      if CntSum > 0 then
      begin
        Pal[I].R := R div CntSum;
        Pal[I].G := G div CntSum;
        Pal[I].B := B div CntSum;
      end
      else
        Pal[I] := Cols[Boxes[I].Idxs[0]];
    end;

    SetLength(Result, Length(Pal));
    for I := 0 to Length(Pal) - 1 do
      Result[I] := (Pal[I].B shl 16) or (Pal[I].G shl 8) or Pal[I].R;
  finally
    Hist.Free;
  end;
end;

function ChanVal(const C: TColorCount; Ch: Integer): Integer; inline;
begin
  case Ch of
    0: Result := C.R;
    1: Result := C.G;
  else
    Result := C.B;
  end;
end;

procedure QSortIds(var Idxs: array of Integer; Lo, Hi: Integer;
  const Cols: array of TColorCount; Ch: Integer);
// QuickSort wg kanału Ch — sortowanie w miejscu (median cut wymaga O(n log n),
// insertion sort był O(n²) i zamulał przy dużych zdjęciach).
var
  I, J, Tmp: Integer;
  Pivot: Integer;
begin
  while Lo < Hi do
  begin
    I := Lo;
    J := Hi;
    Pivot := ChanVal(Cols[Idxs[(Lo + Hi) div 2]], Ch);
    while I <= J do
    begin
      while ChanVal(Cols[Idxs[I]], Ch) < Pivot do Inc(I);
      while ChanVal(Cols[Idxs[J]], Ch) > Pivot do Dec(J);
      if I <= J then
      begin
        Tmp := Idxs[I];
        Idxs[I] := Idxs[J];
        Idxs[J] := Tmp;
        Inc(I);
        Dec(J);
      end;
    end;
    // mniejszą część rekurencyjnie, większą iteracyjnie
    if (J - Lo) < (Hi - I) then
    begin
      QSortIds(Idxs, Lo, J, Cols, Ch);
      Lo := I;
    end
    else
    begin
      QSortIds(Idxs, I, Hi, Cols, Ch);
      Hi := J;
    end;
  end;
end;

procedure DoQuantize(Bitmap: TBitmap; Colors: Integer; Dither: Boolean);
// Posteryzacja — kwantyzacja całego obrazu do `Colors` kolorów (łącznie),
// algorytm median cut. Zgodne z Hollywood QuantizeBrush({Colors = N}).
// Dithering: Floyd–Steinberg rozprasza błąd między kolorami palety.
var
  W, H, X, Y, I, J, N, BoxIdx, BestBox, BestCnt, SplitAt, Mid, CntSum: Integer;
  Row: PRGBTripleArray;
  Key: Cardinal;
  Hist: TDictionary<Cardinal, Integer>;
  Cols: array of TColorCount;
  Boxes: array of TRGBBox;
  Pal: array of TColorCount;
  Ch: Integer;
  ErrLineR, ErrNextR, ErrLineG, ErrNextG, ErrLineB, ErrNextB: array of Integer;
  R, G, B, QErrR, QErrG, QErrB, Rmin, Gmin, Bmin, Rmax, Gmax, Bmax: Integer;
  BestDist, Dist, dR, dG, dB, Bi, NewR, NewG, NewB: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Colors := Max(2, Min(64, Colors));

  // 1. Histogram unikalnych kolorów
  Hist := TDictionary<Cardinal, Integer>.Create;
  try
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Key := (Cardinal(Row[X].R) shl 16) or (Cardinal(Row[X].G) shl 8) or Cardinal(Row[X].B);
        if Hist.ContainsKey(Key) then
          Hist[Key] := Hist[Key] + 1
        else
          Hist.Add(Key, 1);
      end;
    end;

    N := Hist.Count;
    if N = 0 then Exit;

    SetLength(Cols, N);
    I := 0;
    for Key in Hist.Keys do
    begin
      Cols[I].R := (Key shr 16) and $FF;
      Cols[I].G := (Key shr 8) and $FF;
      Cols[I].B := Key and $FF;
      Cols[I].C := Hist[Key];
      Inc(I);
    end;

    // 2. Median cut — dziel pudełko o największej liczbie kolorów
    //    wzdłuż najdłuższej osi, w medianie ważonej licznikami.
    SetLength(Boxes, 1);
    SetLength(Boxes[0].Idxs, N);
    Boxes[0].Cnt := N;
    for I := 0 to N - 1 do
      Boxes[0].Idxs[I] := I;

    while Length(Boxes) < Colors do
    begin
      // pudełko do podziału = o największej liczbie kolorów
      BestBox := 0; BestCnt := -1;
      for I := 0 to Length(Boxes) - 1 do
        if Boxes[I].Cnt > BestCnt then
        begin
          BestCnt := Boxes[I].Cnt;
          BestBox := I;
        end;
      if BestCnt < 2 then Break;

      // najdłuższa oś (0=R, 1=G, 2=B)
      Rmin := 255; Gmin := 255; Bmin := 255;
      Rmax := 0; Gmax := 0; Bmax := 0;
      for J := 0 to Boxes[BestBox].Cnt - 1 do
      begin
        I := Boxes[BestBox].Idxs[J];
        if Cols[I].R < Rmin then Rmin := Cols[I].R;
        if Cols[I].G < Gmin then Gmin := Cols[I].G;
        if Cols[I].B < Bmin then Bmin := Cols[I].B;
        if Cols[I].R > Rmax then Rmax := Cols[I].R;
        if Cols[I].G > Gmax then Gmax := Cols[I].G;
        if Cols[I].B > Bmax then Bmax := Cols[I].B;
      end;
      Ch := 0;
      if (Gmax - Gmin) > (Rmax - Rmin) then Ch := 1;
      if (Bmax - Bmin) > (Gmax - Gmin) then Ch := 2;

      // sortowanie w pudełku wg osi Ch (QuickSort)
      QSortIds(Boxes[BestBox].Idxs, 0, Boxes[BestBox].Cnt - 1, Cols, Ch);

      // punkt podziału — mediana ważona licznikami
      CntSum := 0;
      for J := 0 to Boxes[BestBox].Cnt - 1 do
        CntSum := CntSum + Cols[Boxes[BestBox].Idxs[J]].C;
      Mid := CntSum div 2;
      SplitAt := 0; CntSum := 0;
      for J := 0 to Boxes[BestBox].Cnt - 2 do
      begin
        CntSum := CntSum + Cols[Boxes[BestBox].Idxs[J]].C;
        if CntSum >= Mid then
        begin
          SplitAt := J + 1;
          Break;
        end;
      end;
      if SplitAt <= 0 then SplitAt := Boxes[BestBox].Cnt div 2;
      if SplitAt <= 0 then SplitAt := 1;
      if SplitAt >= Boxes[BestBox].Cnt then SplitAt := Boxes[BestBox].Cnt div 2;
      if SplitAt <= 0 then Break;

      // nowe pudełko = prawa część
      BoxIdx := Length(Boxes);
      SetLength(Boxes, BoxIdx + 1);
      SetLength(Boxes[BoxIdx].Idxs, Boxes[BestBox].Cnt - SplitAt);
      Boxes[BoxIdx].Cnt := Boxes[BestBox].Cnt - SplitAt;
      for J := 0 to Boxes[BoxIdx].Cnt - 1 do
        Boxes[BoxIdx].Idxs[J] := Boxes[BestBox].Idxs[SplitAt + J];
      Boxes[BestBox].Cnt := SplitAt;
      SetLength(Boxes[BestBox].Idxs, SplitAt);
    end;

    // 3. Paleta — średnia ważona kolorów w każdym pudełku
    SetLength(Pal, Length(Boxes));
    for I := 0 to Length(Boxes) - 1 do
    begin
      CntSum := 0; R := 0; G := 0; B := 0;
      for J := 0 to Boxes[I].Cnt - 1 do
      begin
        Bi := Boxes[I].Idxs[J];
        R := R + Cols[Bi].R * Cols[Bi].C;
        G := G + Cols[Bi].G * Cols[Bi].C;
        B := B + Cols[Bi].B * Cols[Bi].C;
        CntSum := CntSum + Cols[Bi].C;
      end;
      if CntSum > 0 then
      begin
        Pal[I].R := R div CntSum;
        Pal[I].G := G div CntSum;
        Pal[I].B := B div CntSum;
      end
      else
        Pal[I] := Cols[Boxes[I].Idxs[0]];
    end;

    // 4. Mapowanie pikseli do najbliższego koloru palety
    if Dither then
    begin
      SetLength(ErrLineR, W + 2); SetLength(ErrNextR, W + 2);
      SetLength(ErrLineG, W + 2); SetLength(ErrNextG, W + 2);
      SetLength(ErrLineB, W + 2); SetLength(ErrNextB, W + 2);
      for X := 0 to W + 1 do
      begin
        ErrLineR[X] := 0; ErrNextR[X] := 0;
        ErrLineG[X] := 0; ErrNextG[X] := 0;
        ErrLineB[X] := 0; ErrNextB[X] := 0;
      end;

      for Y := 0 to H - 1 do
      begin
        Row := Bitmap.ScanLine[Y];
        for X := 0 to W - 1 do
        begin
          R := Row[X].R + ErrLineR[X] div 16;
          G := Row[X].G + ErrLineG[X] div 16;
          B := Row[X].B + ErrLineB[X] div 16;
          if R < 0 then R := 0 else if R > 255 then R := 255;
          if G < 0 then G := 0 else if G > 255 then G := 255;
          if B < 0 then B := 0 else if B > 255 then B := 255;

          // najbliższy kolor palety
          BestDist := MaxInt; Bi := 0;
          for I := 0 to Length(Pal) - 1 do
          begin
            dR := R - Pal[I].R; dG := G - Pal[I].G; dB := B - Pal[I].B;
            Dist := dR * dR + dG * dG + dB * dB;
            if Dist < BestDist then
            begin
              BestDist := Dist;
              Bi := I;
            end;
          end;
          NewR := Pal[Bi].R; NewG := Pal[Bi].G; NewB := Pal[Bi].B;
          QErrR := R - NewR; QErrG := G - NewG; QErrB := B - NewB;

          Row[X].R := ClampByte(NewR);
          Row[X].G := ClampByte(NewG);
          Row[X].B := ClampByte(NewB);

          ErrLineR[X + 1] := ErrLineR[X + 1] + QErrR * 7;
          if X > 0 then ErrNextR[X - 1] := ErrNextR[X - 1] + QErrR * 3;
          ErrNextR[X] := ErrNextR[X] + QErrR * 5;
          ErrNextR[X + 1] := ErrNextR[X + 1] + QErrR;

          ErrLineG[X + 1] := ErrLineG[X + 1] + QErrG * 7;
          if X > 0 then ErrNextG[X - 1] := ErrNextG[X - 1] + QErrG * 3;
          ErrNextG[X] := ErrNextG[X] + QErrG * 5;
          ErrNextG[X + 1] := ErrNextG[X + 1] + QErrG;

          ErrLineB[X + 1] := ErrLineB[X + 1] + QErrB * 7;
          if X > 0 then ErrNextB[X - 1] := ErrNextB[X - 1] + QErrB * 3;
          ErrNextB[X] := ErrNextB[X] + QErrB * 5;
          ErrNextB[X + 1] := ErrNextB[X + 1] + QErrB;
        end;
        for X := 0 to W + 1 do
        begin
          ErrLineR[X] := ErrNextR[X]; ErrNextR[X] := 0;
          ErrLineG[X] := ErrNextG[X]; ErrNextG[X] := 0;
          ErrLineB[X] := ErrNextB[X]; ErrNextB[X] := 0;
        end;
      end;
    end
    else
    begin
      for Y := 0 to H - 1 do
      begin
        Row := Bitmap.ScanLine[Y];
        for X := 0 to W - 1 do
        begin
          BestDist := MaxInt; Bi := 0;
          for I := 0 to Length(Pal) - 1 do
          begin
            dR := Row[X].R - Pal[I].R;
            dG := Row[X].G - Pal[I].G;
            dB := Row[X].B - Pal[I].B;
            Dist := dR * dR + dG * dG + dB * dB;
            if Dist < BestDist then
            begin
              BestDist := Dist;
              Bi := I;
            end;
          end;
          Row[X].R := ClampByte(Pal[Bi].R);
          Row[X].G := ClampByte(Pal[Bi].G);
          Row[X].B := ClampByte(Pal[Bi].B);
        end;
      end;
    end;
  finally
    Hist.Free;
  end;
end;

end.
