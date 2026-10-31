unit uDistort;

interface

uses
  Winapi.Windows, System.SysUtils, System.Math, Vcl.Graphics;

// Amount: -100 (mocna beczka) .. 0 (bez zmian) .. +100 (mocna poduszka)
procedure ApplyLensDistort(Bmp: TBitmap; Amount: Integer);
// AngleDeg: -180..180, 0 = bez zmian; plus = luk w gore, minus = w dol.
// Caly luk wpasowany w plotno, rozmiar obrazu bez zmian.
procedure ApplyArcFit(Bmp: TBitmap; AngleDeg: Integer);
// AngleDeg: -360..360, 0 = bez zmian; RadiusPct: 10..300%, 100 = kolo wpisane
// w krotszy bok, wiecej = poza obraz; brzeg wypelnia odbicie lustrzane.
procedure ApplySwirlEx(Bmp: TBitmap; AngleDeg, RadiusPct: Integer);
// Source: 0 srodek, 1 gora-lewo, 2 dol-lewo, 3 gora-prawo, 4 dol-prawo;
// StrengthPct: 0..200, 0 = bez zmian, 100 = wyglad z wersji Hollywood;
// Density: liczba fal na dluzszym boku.
procedure ApplyWaterRipple(Bmp: TBitmap; Source, StrengthPct, Density: Integer);
// AngleDeg: ile stopni obrazu na pelne kolo (15..720); RadiusPct: 100 = do naroznikow;
// HolePct: promien wewnetrzny w % zewnetrznego; RotDeg: obrot wyniku;
// InsideOut: gora zdjecia w srodku zamiast dolu.
procedure ApplyPolar(Bmp: TBitmap; AngleDeg, RadiusPct, HolePct, RotDeg: Integer; InsideOut: Boolean);
// StrengthPct: 0..100; 0 bez kola = bez zmian. Circle: kolo wpisane w krotszy bok, poza nim czern.
procedure ApplyFisheye(Bmp: TBitmap; StrengthPct: Integer; Circle: Boolean);
// Sel: zaznaczenie na zrenicy; zmienia tylko okolice oka.
procedure ApplyRedEye(Bmp: TBitmap; const Sel: TRect);

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

procedure GetPixelBilinear(Lines: array of PRGBTripleArray; W, H: Integer; X, Y: Double; out R, G, B: Byte);
var
  X0, Y0, X1, Y1: Integer;
  Dx, Dy: Double;
  P00, P01, P10, P11: TRGBTriple;
  C0R, C0G, C0B, C1R, C1G, C1B: Double;
begin
  X0 := Floor(X);
  Y0 := Floor(Y);
  X1 := X0 + 1;
  Y1 := Y0 + 1;
  Dx := X - X0;
  Dy := Y - Y0;

  if (X0 < 0) or (Y0 < 0) or (X1 >= W) or (Y1 >= H) then
  begin
    R := 0; G := 0; B := 0;
    Exit;
  end;

  P00 := Lines[Y0][X0];
  P01 := Lines[Y0][X1];
  P10 := Lines[Y1][X0];
  P11 := Lines[Y1][X1];

  C0R := P00.R * (1 - Dx) + P01.R * Dx;
  C0G := P00.G * (1 - Dx) + P01.G * Dx;
  C0B := P00.B * (1 - Dx) + P01.B * Dx;

  C1R := P10.R * (1 - Dx) + P11.R * Dx;
  C1G := P10.G * (1 - Dx) + P11.G * Dx;
  C1B := P10.B * (1 - Dx) + P11.B * Dx;

  R := Byte(Max(0, Min(255, Round(C0R * (1 - Dy) + C1R * Dy))));
  G := Byte(Max(0, Min(255, Round(C0G * (1 - Dy) + C1G * Dy))));
  B := Byte(Max(0, Min(255, Round(C0B * (1 - Dy) + C1B * Dy))));
end;

// Wspolrzedna odbita lustrzanie w 0..N-1. Tuz ponizej N-1, bo GetPixelBilinear
// daje czern, gdy X+1 wychodzi poza obraz (dotad czarna ostatnia kolumna i wiersz).
function MirrorCoord(V: Double; N: Integer): Double;
var
  M, Period: Double;
begin
  M := N - 1;
  if M <= 0 then Exit(0);
  Period := 2 * M;
  V := Abs(V);
  V := V - Period * Floor(V / Period);
  if V > M then V := Period - V;
  Result := Min(V, M - 0.000001);
end;

// 2026-10-31: dawne warianty to punkty na jednej skali: -25, -60, -100 i +25,
// +60, +100; wzor bez zmian (beczka R^3, poduszka R^2, narozniki na miejscu).
procedure ApplyLensDistort(Bmp: TBitmap; Amount: Integer);
var
  W, H: Integer;
  A, B, C, D_coeff: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, MaxR: Double;
  Nx, Ny, R, R2, R3, Scale: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or (Amount = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  A := 0.0;
  B := 0.0;
  C := 0.0;
  if Amount < 0 then
  begin
    A := Amount / 500.0;
    D_coeff := 1.0 - A;
  end
  else
  begin
    B := Amount / 500.0;
    D_coeff := 1.0 - B;
  end;

  Cx := W / 2.0;
  Cy := H / 2.0;
  MaxR := Sqrt(Cx * Cx + Cy * Cy);

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Nx := (X - Cx) / MaxR;
        Ny := (Y - Cy) / MaxR;
        R2 := Nx * Nx + Ny * Ny;
        R := Sqrt(R2);
        if R > 0.0001 then
        begin
          R3 := R2 * R;
          Scale := A * R3 + B * R2 + C * R + D_coeff;
          // Przemapowanie wsteczne (beczka): dzielenie przez Scale
          SrcX := Cx + (Nx / Scale) * MaxR;
          SrcY := Cy + (Ny / Scale) * MaxR;
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, MirrorCoord(SrcX, W), MirrorCoord(SrcY, H), Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// 2026-10-31: dawne warianty to katy 45, 90, 180, 270, 360, -180 przy promieniu
// 100%; wzor bez zmian.
procedure ApplySwirlEx(Bmp: TBitmap; AngleDeg, RadiusPct: Integer);
var
  W, H: Integer;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, MaxR: Double;
  Dx, Dy, R, Theta, Factor, NewTheta: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or (AngleDeg = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  Cx := W / 2.0;
  Cy := H / 2.0;
  MaxR := Min(Cx, Cy) * RadiusPct / 100.0;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        R := Sqrt(Dx * Dx + Dy * Dy);
        if (R < MaxR) and (MaxR > 0) then
        begin
          Theta := ArcTan2(Dy, Dx);
          Factor := (1.0 - (R / MaxR));
          NewTheta := Theta - AngleDeg * (Pi / 180.0) * Factor * Factor;
          SrcX := Cx + R * Cos(NewTheta);
          SrcY := Cy + R * Sin(NewTheta);
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, MirrorCoord(SrcX, W), MirrorCoord(SrcY, H), Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// 2026-10-31: wzor odtworzony z WaterRippleBrush z wersji Hollywood (pozycja
// Geste: korelacja 0,81 z wynikiem Hollywood, zdjecie 1920x1080, srodek): przesuniecie
// wzdluz promienia = szczyt * sin(2 pi d / fala) * (1 - d / zasieg). Hollywood ma
// szczyt = amplituda * fala, wiec zalezy od rozdzielczosci; tu ulamek dluzszego
// boku z tamtego zdjecia (1920 / 9000), zeby podglad i wynik wygladaly tak samo.
// Zasieg = najdalszy brzeg obrazu od zrodla w poziomie albo pionie.
procedure ApplyWaterRipple(Bmp: TBitmap; Source, StrengthPct, Density: Integer);
const
  cPeakAt100 = 1920.0 / 9000.0;
var
  W, H, X, Y: Integer;
  Base, Wavelength, Peak, Reach, CxNorm, CyNorm, Cx, Cy: Double;
  Dx, Dy, D, Shift, SrcX, SrcY: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or (StrengthPct = 0) or (Density <= 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  CxNorm := 0.5;
  CyNorm := 0.5;
  case Source of
    1: begin CxNorm := 0.1; CyNorm := 0.1; end;
    2: begin CxNorm := 0.1; CyNorm := 0.9; end;
    3: begin CxNorm := 0.9; CyNorm := 0.1; end;
    4: begin CxNorm := 0.9; CyNorm := 0.9; end;
  end;
  Cx := CxNorm * W;
  Cy := CyNorm * H;

  Base := Max(W, H);
  Wavelength := Base / Density;
  Peak := Base * cPeakAt100 * StrengthPct / 100.0;
  Reach := Max(Max(Cx, W - Cx), Max(Cy, H - Cy));

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        D := Sqrt(Dx * Dx + Dy * Dy);
        if (D > 0.0001) and (D < Reach) then
        begin
          Shift := Peak * Sin(2.0 * Pi * D / Wavelength) * (1.0 - D / Reach);
          SrcX := X + Dx / D * Shift;
          SrcY := Y + Dy / D * Shift;
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, MirrorCoord(SrcX, W), MirrorCoord(SrcY, H), Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// 2026-10-31: zastepuje wybor kata i obrotu z listy: stary wzor trzyma srodek
// luku pod obrazem i plotno tej samej wielkosci, wiec konce luku wypadaly poza
// kadr. Tu obwiednia calego luku (do 180 stopni) wpasowana w plotno. Minus =
// lustro w pionie przed i po przemapowaniu.
procedure ApplyArcFit(Bmp: TBitmap; AngleDeg: Integer);
var
  W, H, X, Y: Integer;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  Rad, R0, Xm, Y0, Y1, Bw, Bh, S, Ox, Oy: Double;
  Yd, Px, Py, R, Theta, SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or (AngleDeg = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  Rad := Abs(AngleDeg) * Pi / 180.0;
  R0 := W / Rad;
  Xm := (R0 + H) * Sin(Rad / 2);
  Y0 := -(R0 + H);
  Y1 := -R0 * Cos(Rad / 2);
  Bw := 2 * Xm;
  Bh := Y1 - Y0;
  S := Min(1.0, Min(W / Bw, H / Bh));
  Ox := (W - Bw * S) / 2;
  Oy := (H - Bh * S) / 2;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      if AngleDeg < 0 then Yd := H - 1 - Y else Yd := Y;
      for X := 0 to W - 1 do
      begin
        Px := (X - Ox) / S - Xm;
        Py := (Yd - Oy) / S + Y0;
        R := Sqrt(Px * Px + Py * Py);
        Theta := ArcTan2(Px, -Py);

        SrcX := W / 2.0 + Theta * R0;
        SrcY := H - (R - R0);
        if AngleDeg < 0 then SrcY := H - 1 - SrcY;

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// 2026-10-31: suwaki zamiast 12 wariantow (to byly tylko kombinacje kata i promieni).
// Mapowanie jak w Hollywood PolarDistortBrush: kat -> X zrodla, promien -> Y zrodla.
// Wszystko poza zakresem wypelnia odbicie lustrzane; przy 360 stopniach widoczny
// szew (lewy i prawy brzeg zdjecia sie nie zgadzaja), przy 180 obraz jest symetryczny.
procedure ApplyPolar(Bmp: TBitmap; AngleDeg, RadiusPct, HolePct, RotDeg: Integer; InsideOut: Boolean);
var
  W, H, X, Y: Integer;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  Cx, Cy, Rmax, Rmin: Double;
  Dx, Dy, R, Theta, Tx, Ty: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or (AngleDeg <= 0) or (RadiusPct <= 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  Cx := W / 2.0;
  Cy := H / 2.0;
  Rmax := Sqrt(Cx * Cx + Cy * Cy) * RadiusPct / 100.0;
  Rmin := Rmax * EnsureRange(HolePct, 0, 90) / 100.0;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        R := Sqrt(Dx * Dx + Dy * Dy);
        Theta := ArcTan2(Dy, Dx) * 180.0 / Pi - RotDeg;
        if Theta < -180.0 then Theta := Theta + 360.0
        else if Theta > 180.0 then Theta := Theta - 360.0;

        Tx := (Theta + AngleDeg / 2.0) / AngleDeg;
        Ty := (R - Rmin) / (Rmax - Rmin);
        if not InsideOut then Ty := 1.0 - Ty;

        GetPixelBilinear(SrcLines, W, H, MirrorCoord(Tx * (W - 1), W),
          MirrorCoord(Ty * (H - 1), H), Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// Rybie oko (2026-10-31): zrodlo w odwzorowaniu perspektywicznym, wynik katowy -
// promien wyniku d odpowiada katowi d * Theta, a w zrodle tan(kat) / tan(Theta).
// Bez kola narozniki zostaja na miejscu. Theta do 85 stopni; tan rosnie gwaltownie.
procedure ApplyFisheye(Bmp: TBitmap; StrengthPct: Integer; Circle: Boolean);
const
  cMaxThetaDeg = 75.0;
var
  W, H, X, Y: Integer;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  Cx, Cy, Diag, OutR, Theta, TanTheta: Double;
  Dx, Dy, D, Rr, F, SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) or ((StrengthPct <= 0) and not Circle) then Exit;
  Bmp.PixelFormat := pf24bit;

  Cx := W / 2.0;
  Cy := H / 2.0;
  Diag := Sqrt(Cx * Cx + Cy * Cy);
  if Circle then OutR := Min(Cx, Cy) else OutR := Diag;
  Theta := cMaxThetaDeg * StrengthPct / 100.0 * Pi / 180.0;
  TanTheta := Tan(Theta);

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        D := Sqrt(Dx * Dx + Dy * Dy);
        Rr := D / OutR;
        if Circle and (Rr > 1.0) then
        begin
          DstLines[Y][X].R := 0;
          DstLines[Y][X].G := 0;
          DstLines[Y][X].B := 0;
          Continue;
        end;
        if D > 0.0001 then
        begin
          // Sila 0 z kolem: granica wzoru - zdjecie bez zmian, tylko wyciete w kolo.
          // Skala OutR: krawedz kola to krotszy bok, wiec nie siega poza zdjecie.
          if Theta > 0 then F := Tan(Rr * Theta) / TanTheta else F := Rr;
          SrcX := Cx + Dx / D * F * OutR;
          SrcY := Cy + Dy / D * F * OutR;
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, MirrorCoord(SrcX, W), MirrorCoord(SrcY, H), Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

// Usuwanie czerwonych oczu (2026-10-31). Sel: zaznaczona zrenica. Kolor nie jest
// parametrem: odblask i teczowke odczytujemy z obszaru, a maska to jeden gladki
// kontur, wiec nie ma plamek. Maly jasny punkt odblasku zostaje.
procedure ApplyRedEye(Bmp: TBitmap; const Sel: TRect);
const
  cRays = 72;
  cSelScale = 0.8;      // elipsa mniejsza od zaznaczenia; wybrane na probkach
  cExpandPx = 1.0;
  cFeatherPx = 1.5;
  cDark = 38.0;
  cSearchFrom = 0.75;   // wnetrze elipsy zawsze nalezy do zrenicy
  cSearchTo = 1.2;
  cSearchStep = 0.03;
  cFarRun = 4;
type
  TChannelHist = array[0..2, 0..255] of Integer;
var
  W, H, X0, Y0, X1, Y1, CW, CH, X, Y, I, J, K, Chn, BestX, BestY, Run, Total, Count, Steps: Integer;
  Cx, Cy, Rx, Ry, UnitD, Dn, Nx, Ny, L, Sat, BestL, Thr, Dg, T, A, Pos, Frac, Edge, M, Ln, Res: Double;
  Lines: array of PRGBTripleArray;
  Src, Blur: array of array[0..2] of Double;
  Glint: array of Double;
  HGlow, HIris: TChannelHist;
  NGlow, NIris: Integer;
  Glow, Iris: array[0..2] of Double;
  Radius, TmpR: array[0..cRays - 1] of Double;
  Win: array[0..10] of Double;
  Px: PRGBTriple;

  function SmoothS(AA, BB, V: Double): Double;
  begin
    Result := EnsureRange((V - AA) / (BB - AA), 0.0, 1.0);
    Result := Result * Result * (3 - 2 * Result);
  end;

  procedure MedianOfHist(const Hist: TChannelHist; N: Integer; var Med: array of Double);
  var
    C, V, Sum: Integer;
  begin
    for C := 0 to 2 do
    begin
      Sum := 0;
      for V := 0 to 255 do
      begin
        Inc(Sum, Hist[C, V]);
        if Sum * 2 >= N then
        begin
          Med[C] := V;
          Break;
        end;
      end;
    end;
  end;

  procedure MeanAlongRays;
  var
    Ai, Bi: Integer;
    Sum: Double;
  begin
    for Ai := 0 to cRays - 1 do
    begin
      Sum := 0;
      for Bi := -3 to 3 do
        Sum := Sum + Radius[(Ai + Bi + cRays) mod cRays];
      TmpR[Ai] := Sum / 7;
    end;
    Radius := TmpR;
  end;

begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (Sel.Width < 4) or (Sel.Height < 4) then Exit;
  Bmp.PixelFormat := pf24bit;

  Cx := (Sel.Left + Sel.Right - 1) / 2.0;
  Cy := (Sel.Top + Sel.Bottom - 1) / 2.0;
  Rx := Sel.Width / 2.0 * cSelScale;
  Ry := Sel.Height / 2.0 * cSelScale;
  UnitD := 1.0 / Min(Rx, Ry);

  X0 := Max(0, Floor(Cx - Rx * 2.2));
  Y0 := Max(0, Floor(Cy - Ry * 2.2));
  X1 := Min(W - 1, Ceil(Cx + Rx * 2.2));
  Y1 := Min(H - 1, Ceil(Cy + Ry * 2.2));
  CW := X1 - X0 + 1;
  CH := Y1 - Y0 + 1;

  SetLength(Lines, CH);
  SetLength(Src, CW * CH);
  SetLength(Blur, CW * CH);
  SetLength(Glint, CW * CH);
  for Y := 0 to CH - 1 do
  begin
    Lines[Y] := Bmp.ScanLine[Y0 + Y];
    for X := 0 to CW - 1 do
    begin
      Src[Y * CW + X][0] := Lines[Y][X0 + X].R;
      Src[Y * CW + X][1] := Lines[Y][X0 + X].G;
      Src[Y * CW + X][2] := Lines[Y][X0 + X].B;
    end;
  end;

  // Rozmycie 3 x 3 do szukania konturu; najjasniejszy punkt i odblask
  BestL := -1;
  BestX := 0;
  BestY := 0;
  for Y := 0 to CH - 1 do
    for X := 0 to CW - 1 do
    begin
      for Chn := 0 to 2 do
      begin
        Blur[Y * CW + X][Chn] := 0;
        Count := 0;
        for J := Max(0, Y - 1) to Min(CH - 1, Y + 1) do
          for I := Max(0, X - 1) to Min(CW - 1, X + 1) do
          begin
            Blur[Y * CW + X][Chn] := Blur[Y * CW + X][Chn] + Src[J * CW + I][Chn];
            Inc(Count);
          end;
        Blur[Y * CW + X][Chn] := Blur[Y * CW + X][Chn] / Count;
      end;
      L := 0.299 * Src[Y * CW + X][0] + 0.587 * Src[Y * CW + X][1] + 0.114 * Src[Y * CW + X][2];
      Sat := Max(Abs(Src[Y * CW + X][0] - L), Max(Abs(Src[Y * CW + X][1] - L), Abs(Src[Y * CW + X][2] - L)));
      Glint[Y * CW + X] := SmoothS(190, 235, L) * (1 - SmoothS(25, 60, Sat));
      if (Hypot((X0 + X - Cx) / Rx, (Y0 + Y - Cy) / Ry) < 0.9) and (L > BestL) then
      begin
        BestL := L;
        BestX := X;
        BestY := Y;
      end;
    end;

  // Kolor odblasku ze srodka elipsy, kolor teczowki z pierscienia wokol niej
  FillChar(HGlow, SizeOf(HGlow), 0);
  FillChar(HIris, SizeOf(HIris), 0);
  NGlow := 0;
  NIris := 0;
  for Y := 0 to CH - 1 do
    for X := 0 to CW - 1 do
    begin
      if Hypot((X - BestX) / Rx, (Y - BestY) / Ry) > 0.3 then
        Glint[Y * CW + X] := 0;
      Dn := Hypot((X0 + X - Cx) / Rx, (Y0 + Y - Cy) / Ry);
      if (Dn < 0.7) and (Glint[Y * CW + X] < 0.1) then
      begin
        for Chn := 0 to 2 do
          Inc(HGlow[Chn, Round(Src[Y * CW + X][Chn])]);
        Inc(NGlow);
      end
      else if (Dn > 1.5) and (Dn < 1.9) then
      begin
        for Chn := 0 to 2 do
          Inc(HIris[Chn, Round(Src[Y * CW + X][Chn])]);
        Inc(NIris);
      end;
    end;
  if NGlow = 0 then Exit;

  // Kontur: dla kazdego kata koniec odblasku, potem wygladzenie po kacie.
  // Bez pierscienia (brzeg zdjecia) zostaje sama elipsa.
  for I := 0 to cRays - 1 do
    Radius[I] := cSearchFrom;
  if NIris >= 8 then
  begin
    MedianOfHist(HGlow, NGlow, Glow);
    MedianOfHist(HIris, NIris, Iris);
    Thr := 0.6 * Sqrt(Sqr(Glow[0] - Iris[0]) + Sqr(Glow[1] - Iris[1]) + Sqr(Glow[2] - Iris[2]));
    Steps := Round((cSearchTo - cSearchFrom) / cSearchStep);
    for I := 0 to cRays - 1 do
    begin
      A := 2 * Pi * I / cRays;
      Radius[I] := cSearchTo;
      Run := 0;
      for J := 0 to Steps do
      begin
        T := cSearchFrom + J * cSearchStep;
        X := EnsureRange(Integer(Round(Cx + Cos(A) * Rx * T)) - X0, 0, CW - 1);
        Y := EnsureRange(Integer(Round(Cy + Sin(A) * Ry * T)) - Y0, 0, CH - 1);
        Dg := Sqrt(Sqr(Blur[Y * CW + X][0] - Glow[0]) + Sqr(Blur[Y * CW + X][1] - Glow[1]) +
          Sqr(Blur[Y * CW + X][2] - Glow[2]));
        if Dg >= Thr then Inc(Run) else Run := 0;
        if Run = cFarRun then
        begin
          Radius[I] := cSearchFrom + (J - cFarRun + 1) * cSearchStep;
          Break;
        end;
      end;
    end;
    // Mediana po 11 katach, potem dwa razy srednia po 7
    for I := 0 to cRays - 1 do
    begin
      for K := 0 to 10 do
        Win[K] := Radius[(I + K - 5 + cRays) mod cRays];
      for K := 1 to 10 do
      begin
        T := Win[K];
        J := K - 1;
        while (J >= 0) and (Win[J] > T) do
        begin
          Win[J + 1] := Win[J];
          Dec(J);
        end;
        Win[J + 1] := T;
      end;
      TmpR[I] := Win[5];
    end;
    Radius := TmpR;
    MeanAlongRays;
    MeanAlongRays;
  end;

  // Usuniecie koloru i przyciemnienie do ciemnej szarosci z odrobina tekstury
  for Y := 0 to CH - 1 do
    for X := 0 to CW - 1 do
    begin
      Nx := (X0 + X - Cx) / Rx;
      Ny := (Y0 + Y - Cy) / Ry;
      Dn := Hypot(Nx, Ny);
      A := ArcTan2(Ny, Nx);
      if A < 0 then A := A + 2 * Pi;
      Pos := A / (2 * Pi) * cRays;
      I := Trunc(Pos) mod cRays;
      Frac := Pos - Trunc(Pos);
      Edge := Radius[I] * (1 - Frac) + Radius[(I + 1) mod cRays] * Frac;
      M := 1 - SmoothS(Edge + (cExpandPx - cFeatherPx) * UnitD, Edge + (cExpandPx + cFeatherPx) * UnitD, Dn);
      M := M * (1 - Glint[Y * CW + X]);
      if M <= 0 then Continue;
      L := 0.299 * Src[Y * CW + X][0] + 0.587 * Src[Y * CW + X][1] + 0.114 * Src[Y * CW + X][2];
      Ln := cDark * (0.75 + 0.5 * L / 255.0);
      Px := @Lines[Y][X0 + X];
      for Chn := 0 to 2 do
      begin
        Res := L * (1 - M) + Ln * M + (Src[Y * CW + X][Chn] - L) * (1 - M);
        Total := EnsureRange(Integer(Round(Res)), 0, 255);
        case Chn of
          0: Px^.R := Total;
          1: Px^.G := Total;
          2: Px^.B := Total;
        end;
      end;
    end;
end;

end.