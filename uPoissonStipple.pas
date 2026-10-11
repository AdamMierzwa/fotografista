unit uPoissonStipple;

// EKSPERYMENT: Poisson o zmiennym promieniu (Bridson, dart throwing) z zasiewem siatkowym.
// Promien lokalny r(x,y) zalezy od tonu: ciemno -> rMin, jasno -> rMax = PoissonRatio * rMin.
// Srednica kropki = rMin, wiec kropki sie nie nakladaja (dwa punkty: odleglosc >= max(r(p), r(q))).
// Zasiew: jeden kandydat na komorke siatki, akceptacja wg lokalnego promienia (bez tego jasne obszary zostaja puste).
// PoissonRatio jest zalozeniem autora eksperymentu, nie wynika z dokumentacji.
// Ziarno losowania lokalne (LCG wg RTL), wynik powtarzalny, bez globalnego RandSeed.

interface

uses
  Winapi.Windows, System.SysUtils, System.Math, Vcl.Graphics;

// Pelny obraz: srednica = SizeTenths/1000 * krotszy bok. GammaPct: 10..500 (100 = liniowa).
// ACancel: opcjonalne przerwanie (sprawdzane w petlach); nil = bez anulowania.
procedure DoPoissonStipple(Bitmap: TBitmap; SizeTenths, GammaPct: Integer; const ACancel: TFunc<Boolean> = nil);

// Srednica w pikselach (DiamPx), minimalna srednica MinDiamPx (0 = bez ograniczenia).
procedure DoPoissonStipplePx(Bitmap: TBitmap; DiamPx: Double; GammaPct: Integer; MinDiamPx: Double; const ACancel: TFunc<Boolean> = nil);

implementation

type
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

const
  PoissonRatio = 6.0;  // ZALOZENIE eksperymentu: rMax = 6 * rMin
  Attempts = 8;        // liczba prob wokol aktywnego punktu (wczesniej 30; test: ~2x mniej sprawdzen, liczba punktow i korelacja tonu bez zmian)

procedure DoPoissonStipple(Bitmap: TBitmap; SizeTenths, GammaPct: Integer; const ACancel: TFunc<Boolean>);
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) or (SizeTenths < 1) then Exit;
  DoPoissonStipplePx(Bitmap, SizeTenths / 1000.0 * Min(Bitmap.Width, Bitmap.Height), GammaPct, 0, ACancel);
end;

procedure DoPoissonStipplePx(Bitmap: TBitmap; DiamPx: Double; GammaPct: Integer; MinDiamPx: Double; const ACancel: TFunc<Boolean>);
var
  W, H, NPts, NAct, RangeCells, GW, GH: Integer;
  rMin, rMax, cell, gam, twoPi, rd: Double;
  Grid: array of Integer;          // 0 = puste, i+1 = indeks punktu
  PX, PY, PR: array of Double;
  Active: array of Integer;
  Lines: array of PRGBTripleArray;
  x0, y0, gx, gy, ia, p, a, x, y, x1, x2, y1, y2: Integer;
  RState: UInt32;
  cx, cy, rc, ang, rad: Double;
  ok: Boolean;

  function Rand32: UInt32;
  begin
    RState := UInt32((UInt64(RState) * $08088405 + 1) and $FFFFFFFF);
    Result := RState;
  end;

  function RandReal: Extended;
  const
    two2neg32: Double = ((1.0 / $10000) / $10000);  // 2^-32
  var
    F: Extended;
  begin
    F := Int64(Rand32);
    Result := F * two2neg32;
  end;

  function RandRange(ARange: Integer): Integer;
  begin
    Result := (UInt64(UInt32(ARange)) * UInt64(Rand32)) shr 32;
  end;

  function Cancelled: Boolean;
  begin
    Result := Assigned(ACancel) and ACancel();
  end;

  function RadiusAt(x, y: Integer): Double;
  var
    px: TRGBTriple;
    g: Integer;
    ink: Double;
  begin
    px := Lines[y][x];
    g := (Integer(px.R) * 299 + Integer(px.G) * 587 + Integer(px.B) * 114) div 1000;
    ink := Power(1.0 - g / 255.0, gam);
    Result := rMin + (rMax - rMin) * (1.0 - ink);
  end;

  procedure GrowPoints;
  var
    n: Integer;
  begin
    if NPts < Length(PX) then Exit;
    n := Length(PX) * 2 + 1024;
    SetLength(PX, n);
    SetLength(PY, n);
    SetLength(PR, n);
    SetLength(Active, n);
  end;

  function Accept(cx, cy, rc: Double): Boolean;
  var
    jx, jy, q, gx, gy: Integer;
    dx, dy, lim: Double;
  begin
    Result := False;
    gx := Floor(cx / cell);
    gy := Floor(cy / cell);
    for jy := Max(0, gy - RangeCells) to Min(GH - 1, gy + RangeCells) do
      for jx := Max(0, gx - RangeCells) to Min(GW - 1, gx + RangeCells) do
      begin
        q := Grid[jy * GW + jx];
        if q = 0 then Continue;
        Dec(q);
        dx := cx - PX[q];
        dy := cy - PY[q];
        lim := Max(rc, PR[q]);
        if dx * dx + dy * dy < lim * lim then Exit;
      end;
    Result := True;
  end;

  procedure AddPoint(cx, cy, rc: Double);
  var
    gx, gy: Integer;
  begin
    GrowPoints;
    PX[NPts] := cx;
    PY[NPts] := cy;
    PR[NPts] := rc;
    gx := Floor(cx / cell);
    gy := Floor(cy / cell);
    Grid[gy * GW + gx] := NPts + 1;
    Active[NAct] := NPts;
    Inc(NAct);
    Inc(NPts);
  end;

begin
  if Bitmap = nil then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  rMin := Max(DiamPx, MinDiamPx);
  if (W = 0) or (H = 0) or (rMin <= 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  rMax := rMin * PoissonRatio;
  gam := GammaPct / 100.0;
  twoPi := 2.0 * Pi;
  rd := rMin / 2.0;

  // Siatka: bok komorki = rMin/1.5, dwa punkty nie trafiaja do tej samej komorki.
  cell := rMin / 1.5;
  GW := Ceil(W / cell) + 1;
  GH := Ceil(H / cell) + 1;
  RangeCells := Ceil(rMax / cell) + 1;
  SetLength(Grid, GW * GH);
  FillChar(Grid[0], Length(Grid) * SizeOf(Integer), 0);

  SetLength(Lines, H);
  for y := 0 to H - 1 do
    Lines[y] := PRGBTripleArray(Bitmap.ScanLine[y]);

  RState := 20261010;
  try
    NPts := 0;
    NAct := 0;
    GrowPoints;

    // Zasiew: po jednym kandydacie na komorke siatki.
    for gy := 0 to GH - 1 do
    begin
      if Cancelled then Exit;
      for gx := 0 to GW - 1 do
      begin
        x0 := Trunc((gx + RandReal) * cell);
        y0 := Trunc((gy + RandReal) * cell);
        if (x0 >= W) or (y0 >= H) then Continue;
        rc := RadiusAt(x0, y0);
        if Accept(x0 + 0.5, y0 + 0.5, rc) then
          AddPoint(x0 + 0.5, y0 + 0.5, rc);
      end;
    end;

    // Rozrastanie.
    while NAct > 0 do
    begin
      if Cancelled then Exit;
      ia := RandRange(NAct);
      p := Active[ia];
      ok := False;
      for a := 1 to Attempts do
      begin
        ang := RandReal * twoPi;
        rad := PR[p] * (1.0 + RandReal);
        cx := PX[p] + rad * Cos(ang);
        cy := PY[p] + rad * Sin(ang);
        if (cx < 0) or (cy < 0) or (cx >= W) or (cy >= H) then Continue;
        rc := RadiusAt(Trunc(cx), Trunc(cy));
        if Accept(cx, cy, rc) then
        begin
          AddPoint(cx, cy, rc);
          ok := True;
          Break;
        end;
      end;
      if not ok then
      begin
        Active[ia] := Active[NAct - 1];
        Dec(NAct);
      end;
    end;

    // Rysowanie: biale tlo, czarne kropki o srednicy rMin.
    for y := 0 to H - 1 do
    begin
      if Cancelled then Exit;
      for x := 0 to W - 1 do
      begin
        Lines[y][x].R := 255;
        Lines[y][x].G := 255;
        Lines[y][x].B := 255;
      end;
    end;

    for p := 0 to NPts - 1 do
    begin
      if Cancelled then Exit;
      x1 := Max(0, Floor(PX[p] - rd) - 1);
      x2 := Min(W - 1, Ceil(PX[p] + rd) + 1);
      y1 := Max(0, Floor(PY[p] - rd) - 1);
      y2 := Min(H - 1, Ceil(PY[p] + rd) + 1);
      for y := y1 to y2 do
        for x := x1 to x2 do
          if Sqr(x + 0.5 - PX[p]) + Sqr(y + 0.5 - PY[p]) <= rd * rd then
          begin
            Lines[y][x].R := 0;
            Lines[y][x].G := 0;
            Lines[y][x].B := 0;
          end;
    end;
  finally
  end;
end;

end.
