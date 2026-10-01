unit uMipMap;

interface

uses
  System.SysUtils,
  System.Math,
  Vcl.Graphics,
  GR32;

const
  // Zapas Nyquista dla L=0 (ostre źródło, bez pre-blura): level 0 używany tylko dla
  // zoom >= MinZoomForL0. Empirycznie 0.6 (T_disp ~= 4.8px dla T=8, zapas nad granicą
  // Nyquista 4px). Jeśli test na żywym obrazie pokaże moiré przy niższych zoomach, to
  // jedyny parametr wyboru poziomu — podnieść i nic więcej nie trzeba przepisywać.
  MinZoomForL0 = 0.6;
  // Niezmiennik piramidy: najgłębszy poziom ma większy wymiar >= MinSize (patrz Build).
  MinSize = 256;
  // Blur nakładany przed każdym połowieniem (wzorzec Hollywood BlurBrush(tmp, 2.0)).
  cBlurRadius = 2.0;

type
  // Piramida mip-map dla pre-filtra podglądu rastra. Rozwiązuje znaną lukę jednego
  // stałego blura (EnsureBlurredSource): radius kalibrowany do DispW=1000 dawał za mocny
  // blur przy zoom ~0.88 i za słaby przy głębokim zoom-out (moiré rastra). Tutaj każdy
  // poziom = blur + ½ poprzedniego, więc skuteczny blur na ekranie pozostaje w przedziale
  // ~[1,2]px niezależnie od zoomu.
  //   level0 = ostre źródło (REFERENCJA do FSource, nie kopia),
  //   poziomy 1..N = TBitmap32 (kaskada blura + decymacja 2x).
  // Koszt budowy ~0.9x dzisiejszego BoxBlur (bez podwójnej konwersji TBitmap<->TBitmap32);
  // pamięć dodatkowa ponad źródło ~0.44x zamiast 1.0x.
  TMipPyramid = class
  private
    FSource: TBitmap;
    FSourceHandle: THandle;
    FWidth, FHeight: Integer;
    FLevels: array of TBitmap32;
    function GetCount: Integer;
  public
    destructor Destroy; override;
    // Zbuduj piramidę dla Source (klucz: SourceHandle). Poziomy >=1 liczone od zera.
    procedure Build(Source: TBitmap);
    // Zwolnij poziomy >=1 (zmiana zawartości); referencja FSource zostaje.
    procedure Invalidate;
    // Indeks poziomu dla danego zoomu (0..Count-1); 0 = ostre źródło.
    function LevelIndexForZoom(Zoom: Double): Integer;
    // Poziom piramidy; tylko Idx >= 1 (Idx=0 to Source jako TBitmap).
    function Level(Idx: Integer): TBitmap32;
    property Source: TBitmap read FSource;
    property SourceHandle: THandle read FSourceHandle;
    property Count: Integer read GetCount;
  end;

implementation

uses
  GR32.Blur,
  GR32_Resamplers;

destructor TMipPyramid.Destroy;
begin
  Invalidate;
  inherited Destroy;
end;

function TMipPyramid.GetCount: Integer;
begin
  Result := Length(FLevels);
end;

procedure TMipPyramid.Invalidate;
var
  I: Integer;
begin
  for I := 0 to High(FLevels) do
    FLevels[I].Free;
  SetLength(FLevels, 0);
  FSourceHandle := 0;
  FWidth := 0;
  FHeight := 0;
end;

procedure TMipPyramid.Build(Source: TBitmap);
var
  I, N, W, H: Integer;
  Parent, Half: TBitmap32;
begin
  Invalidate;
  FSource := Source;
  if (Source = nil) or (Source.Width < 1) or (Source.Height < 1) then
    Exit;

  W := Source.Width;
  H := Source.Height;
  FWidth := W;
  FHeight := H;
  FSourceHandle := Source.Handle;

  // N = liczba połowień aż większy wymiar zejdzie < MinSize. Floor (nie Ceil) gwarantuje,
  // że najgłębszy poziom ma rozdzielczość >= MinSize (deklarowany niezmiennik).
  N := Floor(Log2(Max(W, H) / MinSize));
  if N < 1 then
    N := 1;
  SetLength(FLevels, N);

  Parent := TBitmap32.Create;
  try
    Parent.Assign(Source);            // kopia level0 jako bufor roboczy poziomu 1
    for I := 1 to N do
    begin
      Blur32(Parent, cBlurRadius);    // blur in-place przed połowieniem
      Half := TBitmap32.Create;
      try
        Half.SetSize(Max(1, Parent.Width div 2), Max(1, Parent.Height div 2));
        // TLinearResampler (bilinear) ustawiony na ŹRÓDLE: DrawTo używa Resampler źródła
        // (GR32.pas:3547). Konstruktor Create(Parent) sam ustawia Parent.Resampler.
        Parent.Resampler := TLinearResampler.Create(Parent);
        Parent.DrawTo(Half, Half.BoundsRect, Parent.BoundsRect);
      except
        Half.Free;
        raise;
      end;
      FLevels[I - 1] := Half;
      if I < N then
      begin
        Parent.Free;                  // roboczy rodzic nie jest już potrzebny
        Parent := TBitmap32.Create;
        Parent.Assign(Half);          // świeża kopia poziomu I -> poziomy zostają nietknięte
      end;
    end;
  finally
    Parent.Free;
  end;
end;

function TMipPyramid.LevelIndexForZoom(Zoom: Double): Integer;
var
  Scale: Double;
begin
  if (FSource = nil) or (Length(FLevels) = 0) then
    Exit(0);
  if Zoom >= MinZoomForL0 then
    Exit(0);
  Scale := 1.0 / Zoom;
  Result := Floor(Log2(Scale));
  if Result > High(FLevels) then
    Result := High(FLevels);
  if Result < 0 then
    Result := 0;
end;

function TMipPyramid.Level(Idx: Integer): TBitmap32;
begin
  Result := nil;
  if (Idx >= 1) and (Idx <= High(FLevels)) then
    Result := FLevels[Idx - 1];
end;

end.
