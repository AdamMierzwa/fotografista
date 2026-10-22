unit uComicTools;

// Wspolne, stabilne klocki stylow Komiksu. Kazdy styl jest osobnym unitem
// (uComic*.pas); zmiana tutaj dotyka wszystkich stylow, ktore z nich
// korzystaja - po zmianie sprawdzic je wszystkie.

interface

uses
  Vcl.Graphics;

procedure ComicGauss(const Src: array of Single; var Dst: array of Single;
  Ww, Hw: Integer; Sigma: Double);
procedure ComicBilateral(var PY, PCb, PCr: TArray<Single>; Ww, Hw: Integer;
  SigmaD, SigmaR: Double; Iters: Integer);
procedure ComicLevelKeys(const PY: TArray<Single>; Levels: Integer;
  var Key: TArray<Integer>);

implementation

uses
  System.Math, System.Generics.Collections;

// Klucz plamy stylow Pop-art (2026-10-22): poziom jasnosci 0..Levels-1.
// Granice poziomow z rozkladu jasnosci obrazu - kwantyle I/Levels (rowne
// udzialy pola, interpolacja liniowa jak numpy.quantile); piksel dostaje
// liczbe granic <= jego jasnosci. Wczesniej stale granice co 255/Levels: w
// ciemnym lub jasnym obrazie wiekszosc pola wpadala w jeden poziom (jedna
// wielka plama), kilka progow tonow trafialo na te sama plame i ton zostawal
// pusty (czarne tlo portretu: brak czerni i gestych kropek / akcentu).
// Prototyp: tools\tmp\comic_proto\mono_progi.py, gazeta_progi.py (wariant C).
procedure ComicLevelKeys(const PY: TArray<Single>; Levels: Integer;
  var Key: TArray<Integer>);
var
  N, I, K, Lo: Integer;
  S: TArray<Single>;
  Edges: TArray<Double>;
  Pos, Fr: Double;
begin
  N := Length(PY);
  SetLength(Key, N);
  if N = 0 then Exit;
  S := Copy(PY);
  TArray.Sort<Single>(S);
  SetLength(Edges, Levels - 1);
  for I := 1 to Levels - 1 do
  begin
    Pos := (N - 1) * I / Levels;
    Lo := Floor(Pos);
    Fr := Pos - Lo;
    if Lo + 1 < N then
      Edges[I - 1] := S[Lo] + (S[Lo + 1] - S[Lo]) * Fr
    else
      Edges[I - 1] := S[Lo];
  end;
  for K := 0 to N - 1 do
  begin
    I := 0;
    while (I < Levels - 1) and (PY[K] >= Edges[I]) do
      Inc(I);
    Key[K] := I;
  end;
end;


// Rozmycie Gaussa (rozdzielne) obrazu Ww x Hw, brzegi powielane.
procedure ComicGauss(const Src: array of Single; var Dst: array of Single;
  Ww, Hw: Integer; Sigma: Double);
var
  Kern, Tmp: array of Single;
  Rad, I, Xx, Yy: Integer;
  S, Sum: Double;
begin
  Rad := Max(1, Ceil(3 * Sigma));
  SetLength(Kern, 2 * Rad + 1);
  Sum := 0;
  for I := -Rad to Rad do
  begin
    Kern[I + Rad] := Exp(-(I * I) / (2 * Sigma * Sigma));
    Sum := Sum + Kern[I + Rad];
  end;
  for I := 0 to 2 * Rad do
    Kern[I] := Kern[I] / Sum;
  SetLength(Tmp, Ww * Hw);
  for Yy := 0 to Hw - 1 do
    for Xx := 0 to Ww - 1 do
    begin
      S := 0;
      for I := -Rad to Rad do
        S := S + Kern[I + Rad] * Src[Yy * Ww + EnsureRange(Xx + I, 0, Ww - 1)];
      Tmp[Yy * Ww + Xx] := S;
    end;
  for Yy := 0 to Hw - 1 do
    for Xx := 0 to Ww - 1 do
    begin
      S := 0;
      for I := -Rad to Rad do
        S := S + Kern[I + Rad] * Tmp[EnsureRange(Yy + I, 0, Hw - 1) * Ww + Xx];
      Dst[Yy * Ww + Xx] := S;
    end;
end;

// Iterowany, rozdzielny filtr bilateralny na YCbCr (Winnemoller 2006): w kazdej
// iteracji przebieg poziomy, potem pionowy. Waga przestrzenna z SigmaD (px),
// tonalna z odleglosci w YCbCr (SigmaR, jednostki 0..255, tablica 0..511).
procedure ComicBilateral(var PY, PCb, PCr: TArray<Single>; Ww, Hw: Integer;
  SigmaD, SigmaR: Double; Iters: Integer);
var
  RangeW: array[0..511] of Single;
  Wsp: array of Single;
  NY, NCb, NCr, T: TArray<Single>;
  Rad, I, It, Pass, Xx, Yy, C, P, Di: Integer;
  Sw, Sy, Scb, Scr, Wt, Dy, Dcb, Dcr: Double;
begin
  for I := 0 to 511 do
    RangeW[I] := Exp(-(I * I) / (2 * SigmaR * SigmaR));
  Rad := Max(1, Ceil(2 * SigmaD));
  SetLength(Wsp, 2 * Rad + 1);
  for I := -Rad to Rad do
    Wsp[I + Rad] := Exp(-(I * I) / (2 * SigmaD * SigmaD));
  SetLength(NY, Ww * Hw);
  SetLength(NCb, Ww * Hw);
  SetLength(NCr, Ww * Hw);
  for It := 1 to Iters do
    for Pass := 0 to 1 do  // 0 = poziomo, 1 = pionowo
    begin
      for Yy := 0 to Hw - 1 do
        for Xx := 0 to Ww - 1 do
        begin
          C := Yy * Ww + Xx;
          Sw := 0;
          Sy := 0;
          Scb := 0;
          Scr := 0;
          for I := -Rad to Rad do
          begin
            if Pass = 0 then
              P := Yy * Ww + EnsureRange(Xx + I, 0, Ww - 1)
            else
              P := EnsureRange(Yy + I, 0, Hw - 1) * Ww + Xx;
            Dy := PY[P] - PY[C];
            Dcb := PCb[P] - PCb[C];
            Dcr := PCr[P] - PCr[C];
            Di := Min(511, Round(Sqrt(Dy * Dy + Dcb * Dcb + Dcr * Dcr)));
            Wt := Wsp[I + Rad] * RangeW[Di];
            Sw := Sw + Wt;
            Sy := Sy + Wt * PY[P];
            Scb := Scb + Wt * PCb[P];
            Scr := Scr + Wt * PCr[P];
          end;
          NY[C] := Sy / Sw;
          NCb[C] := Scb / Sw;
          NCr[C] := Scr / Sw;
        end;
      T := PY; PY := NY; NY := T;
      T := PCb; PCb := NCb; NCb := T;
      T := PCr; PCr := NCr; NCr := T;
    end;
end;

end.
