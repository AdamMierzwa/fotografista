unit uRastrCMYK;

// Generator rastra CMYK (rastr_cmyk.hws):
// Obrócone siatki kropek C(15°) M(75°) Y(0°) K(45°) składane na białym tle.
// Krzywa area-linear: pokrycie komórki = pi·rd²/GridD² = Comp dokładnie, więc
// rd = (GridD/√π)·√Comp·Scale, a na Comp=1 rd = GridD/√π ≈ 0,564·GridD
// (Rmax = (GridSize/2)·√2·Scale używany tylko jako górna granica bbox/marginesu).
// Algorytm równoważny pętli per-piksel ze specyfikacji: każdy piksel należy do
// dokładnie jednej komórki siatki (floor w przestrzeni obróconej), więc
// stemplowanie kół per komórka daje identyczny wynik przy rząd wielkości
// mniej operacji.

interface

uses
  Vcl.Graphics, System.Math;

// Przetwarza Bitmap w miejscu: 4 siatki C/M/Y/K (Deg: 15/75/0/45) na pure white.
// Grid: 1..32, ScalePct: 25..300 (100 = 1.0).
procedure DoRastrCmyk(Bitmap: TBitmap; Grid, ScalePct: Integer);

implementation

const
  // Minimalny promień kropki (px). Przeciwdziała znikaniu kropki do pojedynczego
  // piksela szumu przy bardzo niskim pokryciu kanału. Przy krzywej area-linear
  // (rd = (GridD/√π)·√Comp·Scale) próg 0.5 aktywuje się dopiero przy
  // Comp < (cRMin·√π/(GridD·Scale))² (~0.012 dla grid=8, scale=100), czyli
  // praktycznie w pikselach prawie-białych — kropka rasteryzuje się wtedy do
  // 1 piksela, bez szumu w półtonach. Rd = Max(Rd, cRMin) utrzymuje małą, ale
  // realną kropkę. Decyzja usera: zostajemy przy stemplowaniu kółek (Hollywood),
  // bez przejścia na ScreenThresh.
  cRMin = 0.5;
  // Półpasmo corner-fill: dla Comp >= cCorner promień płynnie rośnie do Rmax,
  // który domyka narożniki komórki (odległość rogu = GridD·√2/2 = 0.707·GridD).
  // Bez tego najciemniejsze miejsca zostawiają białe rogi (intercept > 0 w cieniach).
  cCorner = 0.75;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

// Notacja ARGB (jak BrushToRGBArray): $00RRGGBB. Alpha ignorowana.
function PackArgb(R, G, B: Byte): Cardinal; inline;
begin
  Result := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
end;

procedure DoRastrCmyk(Bitmap: TBitmap; Grid, ScalePct: Integer);
var
  W, H, X, Y, Ch, Kc, Kr, Ku0, Ku1, Kv0, Kv1: Integer;
  GridD, Rmax, Margin, A, Ca, Sa, Umin, Umax, Vmin, Vmax, Uc, Vc, Xf, Yf: Double;
  Xc, Yc, X0, X1, Y0, Y1, Xx, Yy, Idx: Integer;
  WinX0, WinY0, WinX1, WinY1, Wx, Wy: Integer;
  SumR, SumG, SumB: Cardinal;
  Nc: Integer;
  Rd, TC, Dist, Cov: Double;
  Ri, Gi, Bi: Integer;
  R, G, B, Mx, Kval, Base, Comp: Double;
  Lines: array of PRGBTripleArray;
  Src: array of Cardinal;    // kopia źródła (bo stemplujemy out)
  OutPx: array of Cardinal;  // wynik w ARGB
  Ang: array[0..3] of Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) or (Grid < 1) then Exit;
  Bitmap.PixelFormat := pf24bit;

  // C M Y K (spec §3)
  Ang[0] := Pi / 12.0;         // 15°
  Ang[1] := 5.0 * Pi / 12.0;   // 75°
  Ang[2] := 0.0;               // 0°
  Ang[3] := Pi / 4.0;          // 45°

  GridD := Grid;
  Rmax := (GridD / 2.0) * Sqrt(2.0) * (ScalePct / 100.0);
  Margin := GridD + Rmax + 1.0;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  SetLength(Src, W * H);
  SetLength(OutPx, W * H);

  // tło: czysta biel (spec §5.1), jednocześnie kopia źródła
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Idx := Y * W + X;
      Src[Idx] := PackArgb(Lines[Y][X].R, Lines[Y][X].G, Lines[Y][X].B);
      OutPx[Idx] := $FFFFFF;
    end;

  for Ch := 0 to 3 do
  begin
    A := Ang[Ch];
    Ca := Cos(A);
    Sa := Sin(A);

    // obrys obrazu po obrocie (cztery rogi)
    Umin := Min(0.0, Min(W * Ca, Min(-H * Sa, W * Ca - H * Sa)));
    Umax := Max(0.0, Max(W * Ca, Max(-H * Sa, W * Ca - H * Sa)));
    Vmin := Min(0.0, Min(W * Sa, Min(H * Ca, W * Sa + H * Ca)));
    Vmax := Max(0.0, Max(W * Sa, Max(H * Ca, W * Sa + H * Ca)));

    // indeksy komórek; dolna granica przez negację, bo Trunc() obcina do zera
    Ku0 := -Trunc((Margin - Umin) / GridD);
    Kv0 := -Trunc((Margin - Vmin) / GridD);
    Ku1 := Trunc((Umax + Margin) / GridD);
    Kv1 := Trunc((Vmax + Margin) / GridD);

    for Kc := Kv0 to Kv1 do
    begin
      Vc := Kc * GridD + GridD / 2.0;
      for Kr := Ku0 to Ku1 do
      begin
        Uc := Kr * GridD + GridD / 2.0;
        // obrót środka komórki do przestrzeni obrazu (spec §5b, kąt -a)
        Xf := Uc * Ca + Vc * Sa;
        Yf := -Uc * Sa + Vc * Ca;
        Xc := Trunc(Xf + 0.5);          // ⌊·⌉ zaokrąglenie wg spec
        Yc := Trunc(Yf + 0.5);
        if Xc < 0 then Xc := 0;
        if Yc < 0 then Yc := 0;
        if Xc > W - 1 then Xc := W - 1;
        if Yc > H - 1 then Yc := H - 1;

        // K1: srednia komorki GxG zamiast probki 1 piksela srodka (spec §4).
        // Okno osiowe GxG wokol (Xc,Yc), clamp do ramki. Srednia komorki jest
        // blizej fizyki druku (rozlew tuszu na powierzchni) i eliminuje plamki:
        // pojedynczy piksel w srodku komorki na drobnym detalu (okna katedry,
        // maswerki, przeswity) losowo dawal mocne C/M w roznych fazach siatki
        // -> nasycone kolorowe plamki (zmierzone: 2.32% fioletu, orig 0.00%).
        WinX0 := Xc - Grid div 2;
        WinX1 := WinX0 + Grid - 1;
        WinY0 := Yc - Grid div 2;
        WinY1 := WinY0 + Grid - 1;
        if WinX0 < 0 then WinX0 := 0;
        if WinY0 < 0 then WinY0 := 0;
        if WinX1 > W - 1 then WinX1 := W - 1;
        if WinY1 > H - 1 then WinY1 := H - 1;
        SumR := 0; SumG := 0; SumB := 0;
        for Wy := WinY0 to WinY1 do
          for Wx := WinX0 to WinX1 do
          begin
            Idx := Wy * W + Wx;
            SumR := SumR + ((Src[Idx] shr 16) and $FF);
            SumG := SumG + ((Src[Idx] shr 8) and $FF);
            SumB := SumB + (Src[Idx] and $FF);
          end;
        Nc := (WinX1 - WinX0 + 1) * (WinY1 - WinY0 + 1);
        R := (SumR / Nc) / 255.0;
        G := (SumG / Nc) / 255.0;
        B := (SumB / Nc) / 255.0;
        Mx := Max(R, Max(G, B));
        Kval := 1.0 - Mx;
        if Ch < 3 then
        begin
          if Kval >= 1.0 then
            Comp := 0.0
          else
          begin
            Base := R;
            if Ch = 1 then Base := G;
            if Ch = 2 then Base := B;
            Comp := (1.0 - Base - Kval) / (1.0 - Kval);
          end;
        end
        else
          Comp := Kval;

        // area-linear: pokrycie komórki = pi*rd^2/GridD^2 = Comp dokładnie;
        // rdMax na Comp=1 = GridD/sqrt(pi) ~ 0.564*GridD. (Rmax sluzy tylko do
        // margeinu ponizej — jest wieksze niz rdMax, wiec bbox pozostaje dobry.)
        Rd := (GridD / Sqrt(Pi)) * Sqrt(Comp) * (ScalePct / 100.0);
        // corner-fill (smoothstep): dla Comp >= cCorner domykaj rogi komorki,
        // doszlifowujac rd do Rmax (0.707*GridD) — wtedy cien staje sie pelny,
        // bez bialych rogow. Ponizej cCorner pozostaje czysta area-linear.
        if Comp > cCorner then
        begin
          TC := (Comp - cCorner) / (1.0 - cCorner);
          TC := TC * TC * (3.0 - 2.0 * TC);
          Rd := Rd + (Rmax - Rd) * TC;
        end;
        if Rd <= 0.0 then Continue;
        if Rd < cRMin then Rd := cRMin;

        // coverage-AA (K2): umiarko dorzuca światła do kropki bez piłowania.
        // Zamiast binarnego testu d^2 <= Rd^2 liczymy signed distance od środka
        // piksela (Xx+0.5, Yy+0.5) do krawędzi kropki i mapujemy na pokrycie:
        //   Cov = 0.5 - Dist  (0..1, liniowo w paśmie ~1px wokół krawędzi).
        // Środek kropki bierzemy z floatów (Xf, Yf), nie z zaokrąglonego (Xc,Yc)
        // — piksel na krawędzi dostaje częściowy tusz zamiast ostrego 0/1.
        // Nakładka substraktywna: kanał mnożymy przez (1-Cov) (K: wszystkie),
        // więc pełne pokrycie = stare & maska, a krawędź schodzi płynnie do bieli.
        X0 := Trunc(Xf - Rd) - 1;
        X1 := Trunc(Xf + Rd) + 2;
        Y0 := Trunc(Yf - Rd) - 1;
        Y1 := Trunc(Yf + Rd) + 2;
        if X0 < 0 then X0 := 0;
        if Y0 < 0 then Y0 := 0;
        if X1 > W - 1 then X1 := W - 1;
        if Y1 > H - 1 then Y1 := H - 1;

        for Yy := Y0 to Y1 do
          for Xx := X0 to X1 do
          begin
            // signed distance od środka piksela do krawędzi kropki (>0 = na zewnątrz)
            Dist := Sqrt((Xx + 0.5 - Xf) * (Xx + 0.5 - Xf) + (Yy + 0.5 - Yf) * (Yy + 0.5 - Yf)) - Rd;
            Cov := 0.5 - Dist;
            if Cov <= 0.0 then Continue;
            if Cov > 1.0 then Cov := 1.0;
            Idx := Yy * W + Xx;
            case Ch of
              0: // Cyan odejmuje czerwień ($00RRGGBB)
                begin
                  Ri := (OutPx[Idx] shr 16) and $FF;
                  Ri := Trunc(Ri * (1.0 - Cov));
                  OutPx[Idx] := (OutPx[Idx] and $0000FFFF) or (Cardinal(Ri) shl 16);
                end;
              1: // Magenta odejmuje zieleń
                begin
                  Gi := (OutPx[Idx] shr 8) and $FF;
                  Gi := Trunc(Gi * (1.0 - Cov));
                  OutPx[Idx] := (OutPx[Idx] and $00FF00FF) or (Cardinal(Gi) shl 8);
                end;
              2: // Yellow odejmuje niebieski
                begin
                  Bi := (OutPx[Idx] and $FF);
                  Bi := Trunc(Bi * (1.0 - Cov));
                  OutPx[Idx] := (OutPx[Idx] and $00FFFF00) or Cardinal(Bi);
                end;
              3: // Black odejmuje wszystko
                begin
                  Ri := (OutPx[Idx] shr 16) and $FF;
                  Gi := (OutPx[Idx] shr 8) and $FF;
                  Bi := OutPx[Idx] and $FF;
                  Ri := Trunc(Ri * (1.0 - Cov));
                  Gi := Trunc(Gi * (1.0 - Cov));
                  Bi := Trunc(Bi * (1.0 - Cov));
                  OutPx[Idx] := (Cardinal(Ri) shl 16) or (Cardinal(Gi) shl 8) or Cardinal(Bi);
                end;
            end;
          end;
      end;
    end;
  end;

  // zapis wyniku do bitmapy
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Idx := Y * W + X;
      Lines[Y][X].R := Byte((OutPx[Idx] shr 16) and $FF);
      Lines[Y][X].G := Byte((OutPx[Idx] shr 8) and $FF);
      Lines[Y][X].B := Byte(OutPx[Idx] and $FF);
    end;
end;

end.