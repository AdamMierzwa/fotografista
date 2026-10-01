unit uPixelEngine;

interface

uses
  System.Math;

const
  // Domyślny kąt rastra: 45°.
  // Dlaczego 45°: standard techniki druku. Siatka kropki skręcona o 45° nie
  // koreluje z osiowymi strukturami zdjęć (szczebelki, żaluzje, horyzont,
  // rzędy pikseli przy 100% zoomu). UWAGA: NIE usuwa aliasingu drobnego,
  // gęstego detalu o wysokim kontraście przy agresywnym Cell/T — to inherentna
  // cecha rastra (intermodulacja kropki × detalu daje dodatkowy wzór), nie
  // błąd. 45° obniża widoczność zjawiska (testy: syf ~17.8% -> ~16.2%), nie
  // eliminuje go. Kąt 0.0 = stara geometria (X mod T, Y mod T) — służy do
  // testów porównawczych / regresji bit-po-bicie.
  cScreenAngleDefault = 45.0;

type
  // Pre-komputowany kafelek rastra radialnego. Wspólny dla Riso V1/V2,
  // ScreenPrint i TshirtRender; zastępuje 4 identyczne kopie budowania
  // tabeli Thresh[T*T] (mod -> analityczny obrót bez interpolacji).
  TScreenTile = record
    T: Integer;      // okres rastra (w px)
    Center: Double;  // (T - 1) / 2  — środek kafelka
    Dmax2: Double;   // Sqr(Center) + Sqr(Center) — kwadrat promienia narożnego
    SinA: Double;    // pre-komputowane funkcje trygonometryczne kąta
    CosA: Double;
  end;

// Buduje kafelek dla okresu T i kąta rastra w stopniach.
// AngleDeg = 0 -> u = X, v = Y, daje bit-po-bicie identyczne wyniki co stara
// dyskretna tabela Thresh[(Y mod T) * T + (X mod T)].
function InitScreenTile(T: Integer; AngleDeg: Double = cScreenAngleDefault): TScreenTile;

// Próg pokrycia w pikselu (X, Y) obrazu (przy przesunięciu rastra Sx/Sy odjąć
// od X/Y PRZED wywołaniem). Wartość 0..1; piksel drukowany gdy pokrycie >= próg.
function ScreenThresh(const Tile: TScreenTile; X, Y: Integer): Double;

implementation

function InitScreenTile(T: Integer; AngleDeg: Double): TScreenTile;
begin
  Result.T := T;
  Result.Center := (T - 1) / 2.0;
  Result.Dmax2 := Sqr(Result.Center) + Sqr(Result.Center);
  Result.SinA := Sin(DegToRad(AngleDeg));
  Result.CosA := Cos(DegToRad(AngleDeg));
end;

function ScreenThresh(const Tile: TScreenTile; X, Y: Integer): Double;
var
  U, V, Fu, Fv: Double;
begin
  // Obrót układu (X, Y) o kąt rastra: wiersze/kolumny kropki biegną wzdłuż osi
  // U (diagonala /) i V (diagonala \). Bez interpolacji — analityczny okres.
  U := Tile.CosA * X + Tile.SinA * Y;
  V := -Tile.SinA * X + Tile.CosA * Y;
  // Faza w kafelku: (U, V) modulo okres; Floor zamiast mod, bo V < 0 dla X > Y.
  // Dla 0°: Fu = X mod T, Fv = Y mod T (dokładne, integer w double).
  Fu := U - Tile.T * Floor(U / Tile.T);
  Fv := V - Tile.T * Floor(V / Tile.T);
  // Radialny gradient: mierzy odległość od środka kafelka, unormowaną do 0..1.
  Result := (Sqr(Fu - Tile.Center) + Sqr(Fv - Tile.Center)) / Tile.Dmax2;
end;

end.
