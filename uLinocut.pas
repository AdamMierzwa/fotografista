unit uLinocut;

// Linoryt (2026-10-25): prog liczony na mocno zmniejszonym obrazie (decyzja,
// co jest istotne), obrys plam jako krzywe z ostrymi naroznikami (jak obrys
// skanu szkicu w programie wektorowym) i narysowanie ich w pelnej
// rozdzielczosci. Przebieg z prototypu tools\tmp\linoryt\wektor.py:
//   zmniejszenie (HALFTONE) -> szarosc -> CLAHE 6x6 -> rozmycie 3 +
//   wyostrzenie 6 + prog (jak Prog, DoLinocut) -> usuniecie plam i dziurek
//   mniejszych niz MinArea (suwak, jak w Tworzeniu nadruku) ->
//   obrys petli po krawedziach pikseli -> wygladzenie z naroznikami ->
//   wypelnienie (Graphics32, parzysto-nieparzyste) -> czysta czern/biel.
// Ksztalty nie zaleza od rozdzielczosci wyjscia, wiec podglad i fragment 1:1
// rysuja sie z tych samych ksztaltow co pelny obraz.
//
// Autorstwo (2026-10-25): procedure - zmniejszenie zdjecia, prog na
// zmniejszonym obrazie, normalizacja oswietlenia przed progiem, obrys plam
// jak przy wektoryzacji skanu szkicu, usuwanie wysepek jak w Tworzeniu
// nadruku - ulozyl autor programu, Adam Bogumił Mierzwa. Wykonanie (dobor
// CLAHE, obrys z naroznikami, kod) wedlug jego wskazowek, z jego akceptacja
// kazdego etapu na zdjeciach testowych. Kod napisany od zera, bez cudzych
// zrodel; Potrace (GPL) celowo nie uzyty. Przebieg prob i decyzji:
// ZADANIA.md, sekcja "Linoryt / drzeworyt / staloryt".

interface

uses
  Winapi.Windows, Vcl.Graphics, GR32;   // Windows przed Graphics: TBitmap = Vcl.Graphics.TBitmap

type
  TLinocutShapes = record
    SmallW, SmallH: Integer;              // siatka, na ktorej liczono obrys
    Loops: TArrayOfArrayOfFloatPoint;     // petle w jednostkach siatki
    Removed: Integer;                     // usuniete wysepki i dziurki
  end;

const
  cLinocutThresholdDefault = 50;
  cLinocutSimplifyDefault = 6;
  // min. powierzchnia plamy (px obrazu roboczego) - jak w Tworzeniu nadruku
  cLinocutMinAreaDefault = 3;
  cLinocutMinAreaMax = 50;

// Dluzszy bok obrazu roboczego dla suwaka Uproszczenie 1..10 (640..100 px).
function LinocutWorkSize(Simplify: Integer): Integer;
procedure BuildLinocutShapes(Src: TBitmap; Threshold, Simplify, MinArea: Integer;
  out Shapes: TLinocutShapes);
// Rysuje fragment (OffX, OffY, Dst.Width x Dst.Height) obrazu o rozmiarze
// FullW x FullH; Dst musi miec ustawiony rozmiar.
procedure RenderLinocutShapes(const Shapes: TLinocutShapes; Dst: TBitmap;
  FullW, FullH, OffX, OffY: Integer);
procedure DoLinocut2(Bitmap: TBitmap; Threshold, Simplify, MinArea: Integer);

implementation

uses
  System.SysUtils, System.Types, System.Math, GR32_Polygons,
  uConvolution, frmLinocutDlg;

type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;
  // wiersz TBitmap32 - GR32 TColor32Array to array[0..0] (GR32.pas:81),
  // przy $R+ indeks > 0 daje Range check error
  PColor32Row = ^TColor32Row;
  TColor32Row = array[0..MaxInt div SizeOf(TColor32) - 1] of TColor32;

const
  cClaheTiles = 6;
  cClaheClip = 2.0;
  cCornerDeg = 60.0;     // zalamanie wieksze = naroznik (zostaje ostry)
  cCornerSpan = 3;       // okno (punkty) do pomiaru kata
  cSmoothIters = 6;      // przejscia wygladzania miedzy naroznikami
  cBandRows = 512;       // rysowanie pelnego obrazu pasami

function LinocutWorkSize(Simplify: Integer): Integer;
begin
  Simplify := EnsureRange(Simplify, 1, 10);
  Result := 700 - 60 * Simplify;
end;

// Wyrownanie histogramu w kafelkach z ograniczeniem kontrastu (CLAHE);
// mapy kafelkow laczone dwuliniowo miedzy srodkami kafelkow.
procedure Clahe(var G: TBytes; W, H: Integer);
var
  Tiles, I, J, X, Y, K, X0, X1, Y0, Y1, Cnt, V: Integer;
  TY, TX: array of Integer;
  CY, CX: array of Double;
  Maps: array of array of array[0..255] of Single;
  Hist: array[0..255] of Double;
  Lim, Excess, Sum, F, WY, WX, R: Double;
  RY0, RY1, RX0, RX1: array of Integer;
  RWY, RWX: array of Double;

  procedure Locate(P: Integer; const C: array of Double; out A, B: Integer; out Wt: Double);
  var
    N: Integer;
  begin
    N := Length(C);
    if P <= C[0] then begin A := 0; B := 0; Wt := 0; Exit; end;
    if P >= C[N - 1] then begin A := N - 1; B := N - 1; Wt := 0; Exit; end;
    A := 0;
    while (A < N - 2) and (C[A + 1] <= P) do Inc(A);
    B := A + 1;
    Wt := (P - C[A]) / (C[B] - C[A]);
  end;

begin
  Tiles := Min(cClaheTiles, Min(W, H));
  if Tiles < 1 then Exit;
  SetLength(TY, Tiles + 1); SetLength(TX, Tiles + 1);
  for I := 0 to Tiles do
  begin
    TY[I] := I * H div Tiles;
    TX[I] := I * W div Tiles;
  end;
  SetLength(Maps, Tiles, Tiles);
  for I := 0 to Tiles - 1 do
    for J := 0 to Tiles - 1 do
    begin
      FillChar(Hist, SizeOf(Hist), 0);
      Cnt := 0;
      for Y := TY[I] to TY[I + 1] - 1 do
        for X := TX[J] to TX[J + 1] - 1 do
        begin
          Hist[G[Y * W + X]] := Hist[G[Y * W + X]] + 1;
          Inc(Cnt);
        end;
      Lim := cClaheClip * Max(1, Cnt) / 256;
      Excess := 0;
      for K := 0 to 255 do
        if Hist[K] > Lim then
        begin
          Excess := Excess + Hist[K] - Lim;
          Hist[K] := Lim;
        end;
      Sum := 0;
      for K := 0 to 255 do
        Sum := Sum + Hist[K] + Excess / 256;
      F := 0;
      for K := 0 to 255 do
      begin
        F := F + Hist[K] + Excess / 256;
        if Sum > 0 then
          Maps[I][J][K] := F / Sum * 255
        else
          Maps[I][J][K] := K;
      end;
    end;

  SetLength(CY, Tiles); SetLength(CX, Tiles);
  for I := 0 to Tiles - 1 do
  begin
    CY[I] := (TY[I] + TY[I + 1]) / 2;
    CX[I] := (TX[I] + TX[I + 1]) / 2;
  end;
  SetLength(RY0, H); SetLength(RY1, H); SetLength(RWY, H);
  for Y := 0 to H - 1 do
    Locate(Y, CY, RY0[Y], RY1[Y], RWY[Y]);
  SetLength(RX0, W); SetLength(RX1, W); SetLength(RWX, W);
  for X := 0 to W - 1 do
    Locate(X, CX, RX0[X], RX1[X], RWX[X]);

  for Y := 0 to H - 1 do
  begin
    Y0 := RY0[Y]; Y1 := RY1[Y]; WY := RWY[Y];
    for X := 0 to W - 1 do
    begin
      X0 := RX0[X]; X1 := RX1[X]; WX := RWX[X];
      V := G[Y * W + X];
      R := Maps[Y0][X0][V] * (1 - WY) * (1 - WX) + Maps[Y0][X1][V] * (1 - WY) * WX
         + Maps[Y1][X0][V] * WY * (1 - WX) + Maps[Y1][X1][V] * WY * WX;
      G[Y * W + X] := Byte(EnsureRange(Round(R), 0, 255));
    end;
  end;
end;

// Usuwa spojne obszary (sasiedztwo 4) o wartosci Value mniejsze niz MinArea,
// zamieniajac je na przeciwna wartosc. Wynik = liczba usunietych obszarow.
function DropSmall(var M: TArray<Boolean>; W, H: Integer; Value: Boolean; MinArea: Integer): Integer;
var
  Seen: TArray<Boolean>;
  Stack, Comp: TArray<Integer>;
  SP, CN, I, P, X, Y, Q: Integer;
begin
  Result := 0;
  SetLength(Seen, W * H);
  SetLength(Stack, W * H);
  SetLength(Comp, W * H);
  for I := 0 to W * H - 1 do
  begin
    if Seen[I] or (M[I] <> Value) then Continue;
    SP := 0; CN := 0;
    Stack[SP] := I; Inc(SP); Seen[I] := True;
    while SP > 0 do
    begin
      Dec(SP); P := Stack[SP];
      Comp[CN] := P; Inc(CN);
      X := P mod W; Y := P div W;
      if X > 0 then begin Q := P - 1; if (not Seen[Q]) and (M[Q] = Value) then begin Seen[Q] := True; Stack[SP] := Q; Inc(SP); end; end;
      if X < W - 1 then begin Q := P + 1; if (not Seen[Q]) and (M[Q] = Value) then begin Seen[Q] := True; Stack[SP] := Q; Inc(SP); end; end;
      if Y > 0 then begin Q := P - W; if (not Seen[Q]) and (M[Q] = Value) then begin Seen[Q] := True; Stack[SP] := Q; Inc(SP); end; end;
      if Y < H - 1 then begin Q := P + W; if (not Seen[Q]) and (M[Q] = Value) then begin Seen[Q] := True; Stack[SP] := Q; Inc(SP); end; end;
    end;
    if CN < MinArea then
    begin
      for P := 0 to CN - 1 do
        M[Comp[P]] := not Value;
      Inc(Result);
    end;
  end;
end;

// Petle po krawedziach pikseli, wnetrze (biel) po lewej. Wierzcholki w
// naroznikach siatki (W+1)x(H+1); przy styku po przekatnej wierzcholek ma
// dwie krawedzie wychodzace - wybierana ta jak w prototypie (najmniejszy
// iloczyn wektorowy z poprzednim kierunkiem).
function TraceLoops(const M: TArray<Boolean>; W, H: Integer): TArrayOfArrayOfFloatPoint;
var
  VW, NV, X, Y, V, Cur, Start, Nxt, PDX, PDY, DX, DY, N: Integer;
  Out1, Out2: TArray<Integer>;
  Loop: TArrayOfFloatPoint;
  Cnt: Integer;

  function Inside(AX, AY: Integer): Boolean;
  begin
    Result := (AX >= 0) and (AY >= 0) and (AX < W) and (AY < H) and M[AY * W + AX];
  end;

  procedure AddEdge(AX, AY, BX, BY: Integer);
  var
    A, B: Integer;
  begin
    A := AY * VW + AX; B := BY * VW + BX;
    if Out1[A] < 0 then Out1[A] := B else Out2[A] := B;
  end;

  function Cross(B: Integer): Integer;
  begin
    Result := PDX * ((B div VW) - (Cur div VW)) - PDY * ((B mod VW) - (Cur mod VW));
  end;

begin
  Result := nil;
  VW := W + 1;
  NV := VW * (H + 1);
  SetLength(Out1, NV); SetLength(Out2, NV);
  for V := 0 to NV - 1 do begin Out1[V] := -1; Out2[V] := -1; end;
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      if M[Y * W + X] then
      begin
        if not Inside(X, Y - 1) then AddEdge(X + 1, Y, X, Y);
        if not Inside(X, Y + 1) then AddEdge(X, Y + 1, X + 1, Y + 1);
        if not Inside(X - 1, Y) then AddEdge(X, Y, X, Y + 1);
        if not Inside(X + 1, Y) then AddEdge(X + 1, Y + 1, X + 1, Y);
      end;

  N := 0;
  for Start := 0 to NV - 1 do
    while Out1[Start] >= 0 do
    begin
      SetLength(Loop, 64); Cnt := 0;
      Cur := Start; PDX := 0; PDY := 0;
      repeat
        if Out1[Cur] < 0 then Break;
        if (Out2[Cur] >= 0) and ((PDX <> 0) or (PDY <> 0)) and
           (Cross(Out2[Cur]) < Cross(Out1[Cur])) then
        begin
          Nxt := Out2[Cur]; Out2[Cur] := -1;
        end
        else
        begin
          Nxt := Out1[Cur]; Out1[Cur] := Out2[Cur]; Out2[Cur] := -1;
        end;
        if Cnt = Length(Loop) then SetLength(Loop, Cnt * 2);
        Loop[Cnt] := FloatPoint(Cur mod VW, Cur div VW); Inc(Cnt);
        DX := (Nxt mod VW) - (Cur mod VW); DY := (Nxt div VW) - (Cur div VW);
        PDX := DX; PDY := DY;
        Cur := Nxt;
      until Cur = Start;
      if Cnt >= 4 then
      begin
        SetLength(Loop, Cnt);
        SetLength(Result, N + 1);
        Result[N] := Copy(Loop, 0, Cnt);
        Inc(N);
      end;
    end;
end;

// Schodki -> srodki krawedzi; narozniki (lokalne maksimum kata > cCornerDeg)
// zostaja na miejscu, reszta wygladzana (1-2-1).
function SmoothLoop(const P: TArrayOfFloatPoint): TArrayOfFloatPoint;
var
  N, I, It, IP, IN_: Integer;
  Q, Qs: TArrayOfFloatPoint;
  Ang: array of Double;
  Corner: array of Boolean;
  FX, FY, BX, BY, LF, LB, C: Double;
begin
  N := Length(P);
  SetLength(Q, N);
  for I := 0 to N - 1 do
  begin
    Q[I].X := (P[I].X + P[(I + 1) mod N].X) / 2;
    Q[I].Y := (P[I].Y + P[(I + 1) mod N].Y) / 2;
  end;
  if N < 6 then Exit(Q);
  SetLength(Ang, N);
  for I := 0 to N - 1 do
  begin
    FX := Q[(I + cCornerSpan) mod N].X - Q[I].X;
    FY := Q[(I + cCornerSpan) mod N].Y - Q[I].Y;
    BX := Q[I].X - Q[(I - cCornerSpan + N * 2) mod N].X;
    BY := Q[I].Y - Q[(I - cCornerSpan + N * 2) mod N].Y;
    LF := Sqrt(FX * FX + FY * FY); LB := Sqrt(BX * BX + BY * BY);
    C := (FX * BX + FY * BY) / (LF * LB + 1e-9);
    Ang[I] := RadToDeg(ArcCos(EnsureRange(C, -1.0, 1.0)));
  end;
  SetLength(Corner, N);
  for I := 0 to N - 1 do
    Corner[I] := (Ang[I] > cCornerDeg) and (Ang[I] >= Ang[(I - 1 + N) mod N]) and
                 (Ang[I] >= Ang[(I + 1) mod N]);
  SetLength(Qs, N);
  for It := 1 to cSmoothIters do
  begin
    for I := 0 to N - 1 do
      if Corner[I] then
        Qs[I] := Q[I]
      else
      begin
        IP := (I - 1 + N) mod N; IN_ := (I + 1) mod N;
        Qs[I].X := (Q[IP].X + 2 * Q[I].X + Q[IN_].X) / 4;
        Qs[I].Y := (Q[IP].Y + 2 * Q[I].Y + Q[IN_].Y) / 4;
      end;
    Q := Copy(Qs, 0, N);
  end;
  Result := Q;
end;

procedure BuildLinocutShapes(Src: TBitmap; Threshold, Simplify, MinArea: Integer;
  out Shapes: TLinocutShapes);
var
  L, W, H, X, Y, Cut, I: Integer;
  S: Double;
  Small: TBitmap;
  Row: PRGBTripleArray;
  G: TBytes;
  M: TArray<Boolean>;
  Raw: TArrayOfArrayOfFloatPoint;
begin
  Shapes.SmallW := 0; Shapes.SmallH := 0; Shapes.Loops := nil; Shapes.Removed := 0;
  if (Src = nil) or (Src.Width = 0) or (Src.Height = 0) then Exit;
  L := LinocutWorkSize(Simplify);
  S := Min(1.0, L / Max(Src.Width, Src.Height));
  W := Max(8, Round(Src.Width * S));
  H := Max(8, Round(Src.Height * S));

  Small := TBitmap.Create;
  try
    Small.PixelFormat := pf24bit;
    Small.SetSize(W, H);
    // HALFTONE bezposrednio (Canvas.StretchDraw przestawia tryb na
    // STRETCH_DELETESCANS - Vcl.Graphics.pas:8459-8461)
    SetStretchBltMode(Small.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(Small.Canvas.Handle, 0, 0, nil);
    Winapi.Windows.StretchBlt(Small.Canvas.Handle, 0, 0, W, H,
      Src.Canvas.Handle, 0, 0, Src.Width, Src.Height, SRCCOPY);

    SetLength(G, W * H);
    for Y := 0 to H - 1 do
    begin
      Row := Small.ScanLine[Y];
      for X := 0 to W - 1 do
        G[Y * W + X] := (Row[X].rgbtRed * 299 + Row[X].rgbtGreen * 587 +
          Row[X].rgbtBlue * 114) div 1000;
    end;
    Clahe(G, W, H);
    for Y := 0 to H - 1 do
    begin
      Row := Small.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].rgbtRed := G[Y * W + X];
        Row[X].rgbtGreen := G[Y * W + X];
        Row[X].rgbtBlue := G[Y * W + X];
      end;
    end;

    // kroki Progu (DoLinocut): rozmycie 3, wyostrzenie 6, prog Threshold*2
    BoxBlur(Small, Small, 3);
    SharpenFixedRadius(Small, 6);
    Cut := Threshold * 2;
    SetLength(M, W * H);
    for Y := 0 to H - 1 do
    begin
      Row := Small.ScanLine[Y];
      for X := 0 to W - 1 do
        M[Y * W + X] := Row[X].rgbtRed > Cut;
    end;
  finally
    Small.Free;
  end;

  MinArea := EnsureRange(MinArea, 0, cLinocutMinAreaMax);
  Shapes.Removed := DropSmall(M, W, H, True, MinArea) +
    DropSmall(M, W, H, False, MinArea);

  Raw := TraceLoops(M, W, H);
  SetLength(Shapes.Loops, Length(Raw));
  for I := 0 to High(Raw) do
    Shapes.Loops[I] := SmoothLoop(Raw[I]);
  Shapes.SmallW := W;
  Shapes.SmallH := H;
end;

procedure RenderLinocutShapes(const Shapes: TLinocutShapes; Dst: TBitmap;
  FullW, FullH, OffX, OffY: Integer);
var
  B32: TBitmap32;
  Pts: TArrayOfArrayOfFloatPoint;
  I, J, X, Y: Integer;
  FX, FY: Double;
  Src: PColor32Row;
  Row: PRGBTripleArray;
  V: Byte;
begin
  if (Dst.Width = 0) or (Dst.Height = 0) then Exit;
  Dst.PixelFormat := pf24bit;
  B32 := TBitmap32.Create;
  try
    B32.SetSize(Dst.Width, Dst.Height);
    B32.Clear(clBlack32);
    if (Shapes.SmallW > 0) and (Length(Shapes.Loops) > 0) then
    begin
      FX := FullW / Shapes.SmallW;
      FY := FullH / Shapes.SmallH;
      SetLength(Pts, Length(Shapes.Loops));
      for I := 0 to High(Shapes.Loops) do
      begin
        SetLength(Pts[I], Length(Shapes.Loops[I]));
        for J := 0 to High(Shapes.Loops[I]) do
          Pts[I][J] := FloatPoint(Shapes.Loops[I][J].X * FX - OffX,
            Shapes.Loops[I][J].Y * FY - OffY);
      end;
      PolyPolygonFS(B32, Pts, clWhite32, pfAlternate);
    end;
    // wygladzona krawedz -> czysta czern/biel (prog w polowie)
    for Y := 0 to Dst.Height - 1 do
    begin
      Src := PColor32Row(B32.ScanLine[Y]);
      Row := Dst.ScanLine[Y];
      for X := 0 to Dst.Width - 1 do
      begin
        if ((Src[X] shr 8) and $FF) > 127 then V := 255 else V := 0;
        Row[X].rgbtRed := V; Row[X].rgbtGreen := V; Row[X].rgbtBlue := V;
      end;
    end;
  finally
    B32.Free;
  end;
end;

procedure DoLinocut2(Bitmap: TBitmap; Threshold, Simplify, MinArea: Integer);
var
  Shapes: TLinocutShapes;
  Band: TBitmap;
  W, H, Y0, BH, Y: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;
  BuildLinocutShapes(Bitmap, Threshold, Simplify, MinArea, Shapes);
  Band := TBitmap.Create;
  try
    Band.PixelFormat := pf24bit;
    Y0 := 0;
    while Y0 < H do
    begin
      BH := Min(cBandRows, H - Y0);
      Band.SetSize(W, BH);
      RenderLinocutShapes(Shapes, Band, W, H, 0, Y0);
      for Y := 0 to BH - 1 do
        Move(Band.ScanLine[Y]^, Bitmap.ScanLine[Y0 + Y]^, W * SizeOf(TRGBTriple));
      Inc(Y0, BH);
    end;
  finally
    Band.Free;
  end;
end;

end.
