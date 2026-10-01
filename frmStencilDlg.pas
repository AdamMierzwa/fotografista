unit frmStencilDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Themes, uConvolution, uI18n, uTitleBar;

type
  TStencilDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblSmooth: TLabel;
    tbSmooth: TTrackBar;
    lblSmoothVal: TLabel;
    lblEdge: TLabel;
    tbEdge: TTrackBar;
    lblEdgeVal: TLabel;
    lblThresh: TLabel;
    tbThresh: TTrackBar;
    lblThreshVal: TLabel;
    lblWear: TLabel;
    tbWear: TTrackBar;
    lblWearVal: TLabel;
    lblInk: TLabel;
    pboxInk: TPaintBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbSmoothChange(Sender: TObject);
    procedure tbEdgeChange(Sender: TObject);
    procedure tbThreshChange(Sender: TObject);
    procedure tbWearChange(Sender: TObject);
    procedure pboxInkPaint(Sender: TObject);
    procedure pboxInkMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pboxInkMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PreviewTimerTick(Sender: TObject);
    procedure ZoomTimerTick(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FZoomBmp: TBitmap;
    FSm: Integer;
    FEd: Integer;
    FTh: Integer;
    FInk: TColor;
    FInkIndex: Integer;
    FWear: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    FEffBmp: TBitmap;
    FEffValid: Boolean;
    FEffX, FEffY, FEffW, FEffH: Integer;
    FPreviewTimer, FZoomTimer: TTimer;
    FPreviewDirty, FZoomDirty: Boolean;
    procedure SchedulePreview;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
    procedure LayoutInkPalette;
    function InkIndexAt(X, Y: Integer): Integer;
    procedure SelectInk(I: Integer);
  end;

function ShowStencilDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

// Paleta tuszu Powielacza — historyczne tusze powielaczowe, w kolejności kratki
// (od góry): Czerń (PRL) = domyślna, Fiolet (Zachód), Granat (offset),
// Czerwień (stemple), Zieleń, Sepia. TColor = $00BBGGRR.
const
  cInkCount = 6;
  cInkPad = 4;
  cInkRowH = 22;
  cInkSwatch = 18;
  cInkColors: array[0..cInkCount - 1] of TColor = (
    $001E1E1E,   // Czerń (PRL)        #1E1E1E
    $007C3B4A,   // Fiolet (Zachód)    #4A3B7C
    $007A4624,   // Granat (offset)    #24467A
    $0020208A,   // Czerwień (stemple) #8A2020
    $003A5E2F,   // Zieleń             #2F5E3A
    $002B4A6B    // Sepia              #6B4A2B
  );

function InkDisplayName(I: Integer): string;
begin
  case I of
    0: Result := T('Black (PRL)');
    1: Result := T('Violet (West)');
    2: Result := T('Navy (offset)');
    3: Result := T('Red (stamps)');
    4: Result := T('Green');
    5: Result := T('Sepia');
  else
    Result := '';
  end;
end;

function InkDisplayHint(I: Integer): string;
begin
  case I of
    0: Result := T('PRL samizdat - white-protein duplicator, sooty ink, smeared stencil');
    1: Result := T('Western spirit duplicator - crystal violet dye, alcohol smell');
    2: Result := T('Offset duplicator master - office copy');
    3: Result := T('Stamps, headings and official forms');
    4: Result := T('Western offices - less common ink');
    5: Result := T('Faded, aged copy');
  else
    Result := '';
  end;
end;

// Kolor tuszu: obraz po ostatnim progu jest binarny (0 = tusz, 255 = papier).
// Rekolor pointwise: piksele tuszowe -> kolor tuszu, papier zostaje biały.
// Wear (0..100) symuluje zużycie matrycy — im wyżej, tym tusz jaśniejszy
// (mieszany z bielą), czyli późniejsza, bledsza kopia.
procedure TintBinary(Bitmap: TBitmap; Ink: TColor; Wear: Integer);
var
  W, H, X, Y, L: Integer;
  Ir, Ig, Ib: Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  if Wear < 0 then Wear := 0;
  if Wear > 100 then Wear := 100;

  Ir := Ink and $0000FF;
  Ig := (Ink shr 8) and $FF;
  Ib := (Ink shr 16) and $FF;
  if Wear > 0 then
  begin
    Ir := Ir + MulDiv(255 - Ir, Wear, 100);
    Ig := Ig + MulDiv(255 - Ig, Wear, 100);
    Ib := Ib + MulDiv(255 - Ib, Wear, 100);
  end;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      L := Lines[Y][X].R;   // po ostatnim progu tylko 0 albo 255 (G=B=R)
      if L < 128 then
      begin
        Lines[Y][X].R := Byte(Ir);
        Lines[Y][X].G := Byte(Ig);
        Lines[Y][X].B := Byte(Ib);
      end;
    end;
end;

// Krawędzie metodą Laplacjana przez okno — wzorzec ApplyCharcoalEffect
// (frmCharcoalDlg.pas): kernel (2R+1)x(2R+1), wszystkie wpisy -1, środek N-1,
// N = (2R+1)^2, suma kernela = 0. Tożsamość: edge = N*center - winSum, gdzie
// winSum = suma (2R+1)x(2R+1) z dopełnieniem clamp-to-edge (replikacja brzegów),
// identyczna z pełną konwolucją. Clamp do 0..255 (jak Węgiel), bo to jedyny
// udokumentowany mechanizm krawędzi w tym kodzie — EdgeBrush Hollywood jest
// czarną skrzynką ("search radius").
// WYDAJNOŚĆ: zamiast summed-area table `array of array of Int64`
// (~8 B/px + tysiące alokacji wierszy + kopia EdgeBmp W×H) liczymy tę samą sumę
// dwuprzebiegowo na płaskim buforze Int32:
//   1) HSum[sy*W+X] = pozioma suma okna w wierszu sy (max (2R+1)*255 = 5355),
//   2) ColSum[X]    = pionowa suma okna HSum[clamp(Y-R)..clamp(Y+R)][X]
//                     (max (2R+1)^2*255 = 112455 — mieści się w Int32),
// a wynik edge zapisujemy W MIEJSCU (HSum zbudowane z całego obrazu PRZED
// nadpisaniem, więc odczyt i zapis tej samej bitmapy nie kolidują).
// Dla R<=10 wszystkie wartości pośrednie <= 112455, więc Int32 jest bezpieczny
// (Int32 byłby błędny dla samego SAT — suma narasta z całym obrazem — ale nie
// dla sumy okna). Dodawanie całkowite jest łączne: wynik bit-identyczny z SAT.
procedure DoStencilEdge(Bitmap: TBitmap; Edge: Integer);
var
  W, H, X, Y, R, N, C, EdgeVal: Integer;
  PW, I, sy, dy: Integer;
  WinSum: Integer;
  HSum, ColSum, RowExt: TArray<Integer>;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  R := Max(1, Min(10, Edge));
  N := (2 * R + 1) * (2 * R + 1);

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  PW := W + 2 * R;

  // Rozszerzony wiersz: RowExt[i] = src[clamp(i-R)] — dokładnie to samo
  // dopełnienie clamp-to-edge, które w wersji z SAT budował padding.
  SetLength(RowExt, PW);

  // Przebieg 1: poziome sumy okna per wiersz źródłowy.
  // Obraz jest grayscale, więc liczymy po kanale R (wszystkie równe).
  SetLength(HSum, W * H);
  for sy := 0 to H - 1 do
  begin
    for I := 0 to PW - 1 do
    begin
      X := I - R;
      if X < 0 then X := 0 else if X > W - 1 then X := W - 1;
      RowExt[I] := Lines[sy][X].R;
    end;
    WinSum := 0;
    for I := 0 to 2 * R do
      Inc(WinSum, RowExt[I]);
    HSum[sy * W] := WinSum;
    for X := 1 to W - 1 do
    begin
      Inc(WinSum, RowExt[X + 2 * R] - RowExt[X - 1]);
      HSum[sy * W + X] := WinSum;
    end;
  end;

  // Przebieg 2: pionowa suma okna + od razu wartość krawędzi.
  SetLength(ColSum, W);
  for X := 0 to W - 1 do
    ColSum[X] := 0;
  // Y = 0: wiersze clamp(0+dy) dla dy = -R..R.
  for dy := -R to R do
  begin
    sy := dy;
    if sy < 0 then sy := 0 else if sy > H - 1 then sy := H - 1;
    for X := 0 to W - 1 do
      Inc(ColSum[X], HSum[sy * W + X]);
  end;

  for Y := 0 to H - 1 do
  begin
    if Y > 0 then
    begin
      sy := Y - 1 - R;                    // wiersz wypadający z okna (Y-1 -> Y)
      if sy < 0 then sy := 0 else if sy > H - 1 then sy := H - 1;
      for X := 0 to W - 1 do
        Dec(ColSum[X], HSum[sy * W + X]);
      sy := Y + R;                        // wiersz wchodzący do okna
      if sy < 0 then sy := 0 else if sy > H - 1 then sy := H - 1;
      for X := 0 to W - 1 do
        Inc(ColSum[X], HSum[sy * W + X]);
    end;
    for X := 0 to W - 1 do
    begin
      C := Lines[Y][X].R;
      EdgeVal := N * C - ColSum[X];
      if EdgeVal < 0 then EdgeVal := 0
      else if EdgeVal > 255 then EdgeVal := 255;
      Lines[Y][X].R := Byte(EdgeVal);
      Lines[Y][X].G := Byte(EdgeVal);
      Lines[Y][X].B := Byte(EdgeVal);
    end;
  end;
end;

// Normalizacja stretch min->0, max->255 — wzorzec ApplyCharcoalEffect (krok 3).
// EdgeBrush Hollywood zwraca pełny zakres 0..255 (jasne linie na czarnym tle,
// żeby po Invert powstały ciemne linie na białym); bez tego Laplacjan ma zasięg
// ~0..50 i po Invert wszystko jest > threshold -> cały obraz biały.
procedure NormalizeGrayscale(Bitmap: TBitmap);
var
  W, H, X, Y, V, MinV, MaxV: Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  MinV := 255; MaxV := 0;
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      V := Lines[Y][X].R;
      if V < MinV then MinV := V;
      if V > MaxV then MaxV := V;
    end;

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      V := Round((Lines[Y][X].R - MinV) * 255.0 / Max(MaxV - MinV, 1));
      if V < 0 then V := 0;
      if V > 255 then V := 255;
      Lines[Y][X].R := Byte(V);
      Lines[Y][X].G := Byte(V);
      Lines[Y][X].B := Byte(V);
    end;
end;

// Binarne progowanie: jasny > prog -> bialy, inaczej czarny.
procedure ThresholdBinary(Bitmap: TBitmap; Prog: Integer);
var
  W, H, X, Y, L: Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      L := Lines[Y][X].R;
      if L > Prog then
      begin
        Lines[Y][X].R := 255; Lines[Y][X].G := 255; Lines[Y][X].B := 255;
      end
      else
      begin
        Lines[Y][X].R := 0; Lines[Y][X].G := 0; Lines[Y][X].B := 0;
      end;
    end;
end;

// Binarne rozmycie + progowanie (erozja/dylatacja wg p_StencilCore).
// Erozja: blur(2) + prog 112, dylatacja: blur(2) + prog 144.
procedure BlurThenThreshold(Bitmap: TBitmap; Radius, Prog: Integer);
begin
  // Rozmycie w miejscu. BoxBlur najpierw kopiuje całe Src do TBitmap32, a
  // dopiero potem zapisuje wynik do Dst (uConvolution.pas:51-58), więc Src=Dst
  // jest bezpieczne i daje ten sam wynik — bez tymczasowej bitmapy i kopii W×H.
  BoxBlur(Bitmap, Bitmap, Radius);
  ThresholdBinary(Bitmap, Prog);
end;

// Powielacz (wierny port p_StencilCore z image_fx_effects.hws:829).
// grayscale -> Blur(smooth) -> EdgeBrush(edge) -> Invert -> prog
// -> opening: erozja (blur 2, >112) -> dylatacja (blur 2, >144). open_r=2.
procedure DoStencil(Bitmap: TBitmap; Smooth, Edge, Thresh: Integer; Ink: TColor; Wear: Integer);
var
  W, H: Integer;
  Tmp: TBitmap;
  Lines: array of PRGBTripleArray;
  X, Y, Lum, V: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  Tmp := TBitmap.Create;
  try
    Tmp.Assign(Bitmap);
    Tmp.PixelFormat := pf24bit;

    // BrushToGray(tmp)
    SetLength(Lines, H);
    for Y := 0 to H - 1 do
    begin
      Lines[Y] := Tmp.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Lum := (299 * Lines[Y][X].R + 587 * Lines[Y][X].G + 114 * Lines[Y][X].B) div 1000;
        Lines[Y][X].R := Byte(Lum);
        Lines[Y][X].G := Byte(Lum);
        Lines[Y][X].B := Byte(Lum);
      end;
    end;

    // BlurBrush(tmp, smooth) — tylko gdy smooth > 0 (sam blur, bez progowania).
    // W miejscu (BoxBlur czyta całe źródło przed zapisem) — bez tymczasowej
    // bitmapy i pełnej kopii W×H.
    if Smooth > 0 then
      BoxBlur(Tmp, Tmp, Smooth);

    // EdgeBrush(tmp, edge) — DoG
    DoStencilEdge(Tmp, Edge);

    // InvertBrush(tmp)
    SetLength(Lines, H);
    for Y := 0 to H - 1 do
    begin
      Lines[Y] := Tmp.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        V := 255 - Lines[Y][X].R;
        Lines[Y][X].R := Byte(V);
        Lines[Y][X].G := Byte(V);
        Lines[Y][X].B := Byte(V);
      end;
    end;

    // Prog: > threshold -> bialy, inaczej czarny
    ThresholdBinary(Tmp, Thresh);

    // Opening: erozja (blur 2, >112) usuwa izolowane kropki
    BlurThenThreshold(Tmp, 2, 112);

    // Dylatacja (blur 2, >144) — odrost grubości
    BlurThenThreshold(Tmp, 2, 144);

    // Rekolor binarnego wyniku na wybrany tusz (+ symulacja zużycia matrycy)
    TintBinary(Tmp, Ink, Wear);

    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowStencilDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TStencilDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Bottom, Delta: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TStencilDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    // Nawigator: cały obraz skalowany do 400 px (jak pozostałe dialogi).
    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;

    Scaled := TBitmap.Create;
    try
      Scaled.PixelFormat := pf24bit;
      Scaled.SetSize(pw, ph);
      Scaled.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

      Dlg.FOriginalPreview := TBitmap.Create;
      Dlg.FOriginalPreview.PixelFormat := pf24bit;
      Dlg.FOriginalPreview.SetSize(pw, ph);
      Dlg.FOriginalPreview.Canvas.Draw(0, 0, Scaled);

      Dlg.FWorkingPreview := TBitmap.Create;
      Dlg.FWorkingPreview.PixelFormat := pf24bit;
      Dlg.FWorkingPreview.SetSize(pw, ph);
    finally
      Scaled.Free;
    end;

    // Podgląd 100%: te same wymiary co nawigator (pw x ph, orientacja zdjęcia).
    // Fragment = 1:1 pikseli oryginału.
    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);

    // Początkowy środek podglądu = środek obrazu.
    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;

    // Layout: nawigator po lewej, podgląd 100% obok. Trzy wiersze kontrolek
    // (ziarnistość, krawędzie, próg) są dociskane w dół, gdy podglądy są
    // wyższe niż w DFM.
    Dlg.pboxPreview.Width := pw;
    Dlg.pboxPreview.Height := ph;
    Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxPreview.Top := Dlg.TitleBarGap + Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.pboxZoom.Top := Dlg.pboxPreview.Top;
    Dlg.pboxZoom.Width := Dlg.FZoomW;
    Dlg.pboxZoom.Height := Dlg.FZoomH;

    Bottom := Dlg.pboxPreview.Top + Max(Dlg.pboxPreview.Height, Dlg.pboxZoom.Height)
      + Dlg.RowGap * 2;
    Delta := Bottom - Dlg.lblSmooth.Top;
    if Delta > 0 then
    begin
      Dlg.lblSmooth.Top := Dlg.lblSmooth.Top + Delta;
      Dlg.tbSmooth.Top := Dlg.tbSmooth.Top + Delta;
      Dlg.lblSmoothVal.Top := Dlg.lblSmoothVal.Top + Delta;
      Dlg.lblEdge.Top := Dlg.lblEdge.Top + Delta;
      Dlg.tbEdge.Top := Dlg.tbEdge.Top + Delta;
      Dlg.lblEdgeVal.Top := Dlg.lblEdgeVal.Top + Delta;
      Dlg.lblThresh.Top := Dlg.lblThresh.Top + Delta;
      Dlg.tbThresh.Top := Dlg.tbThresh.Top + Delta;
      Dlg.lblThreshVal.Top := Dlg.lblThreshVal.Top + Delta;
      Dlg.lblWear.Top := Dlg.lblWear.Top + Delta;
      Dlg.tbWear.Top := Dlg.tbWear.Top + Delta;
      Dlg.lblWearVal.Top := Dlg.lblWearVal.Top + Delta;
      Dlg.btnOK.Top := Dlg.btnOK.Top + Delta;
      Dlg.btnCancel.Top := Dlg.btnCancel.Top + Delta;
    end;

    // Kratka tuszu w prawej kolumnie (poniżej podglądu 100%). Górna krawędź
    // pokrywa się z górą kolumny suwaków; szerokość mierzona z nazw, bo
    // tłumaczenia mają różną długość.
    Dlg.LayoutInkPalette;
    Dlg.lblInk.Top := Dlg.lblSmooth.Top;
    Dlg.pboxInk.Top := Dlg.lblInk.Top + Dlg.lblInk.Height + Dlg.RowGap;
    // Tymczasowa kotwica przed FitToContent: prawa krawędź kolumny suwaków,
    // żeby okno policzyło szerokość z tablicą mieszczącą się obok kontrolek.
    Dlg.pboxInk.Left := Dlg.tbSmooth.Left + Dlg.tbSmooth.Width + Dlg.CtrlGap * 3;
    Dlg.lblInk.Left := Dlg.pboxInk.Left;

    // Pola ustawiane jawnie — NIE polegać na OnChange z FormCreate, bo
    // SetPosition nie odpala zdarzenia gdy wartość równa się już wartości
    // z DFM (Vcl.ComCtrls.pas:13862), a wtedy FTh zostałoby 0 i próg
    // przepuściłby wszystko na biało.
    Dlg.FSm := Dlg.tbSmooth.Position;
    Dlg.FEd := Dlg.tbEdge.Position;
    Dlg.FTh := Dlg.tbThresh.Position;
    Dlg.FInk := cInkColors[Dlg.FInkIndex];
    Dlg.FWear := Dlg.tbWear.Position;
    Dlg.ApplyPreview;
    // Podgląd startowy policzony od razu — wyczyść stan koalescencji, żeby
    // ewentualny tik timera z FormCreate (tbSmooth.Position := 3) nie powtórzył
    // ciężkiego renderu tuż po otwarciu okna.
    Dlg.FPreviewDirty := False;
    Dlg.FPreviewTimer.Enabled := False;
    Dlg.FZoomDirty := False;
    Dlg.FZoomTimer.Enabled := False;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wyśrodkowanie pary podglądów w szerokości okna. Szerokość okna wyznacza
    // najszerszy element (tbSmooth/tbEdge/tbThresh) — bez centrowania para
    // leży przy lewej krawędzi, a po prawej zostaje pas pustego tła.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    // Tablica wyśrodkowana pod podglądem 100%, ale nie wchodzi na suwaki:
    // dla małego zdjęcia okno poszerza się (FitToContent) zamiast nachodzić.
    Dlg.pboxInk.Left := Max(Dlg.pboxZoom.Left + (Dlg.pboxZoom.Width - Dlg.pboxInk.Width) div 2,
      Dlg.tbSmooth.Left + Dlg.tbSmooth.Width + Dlg.CtrlGap * 3);
    Dlg.lblInk.Left := Dlg.pboxInk.Left + (Dlg.pboxInk.Width - Dlg.lblInk.Width) div 2;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TStencilDlg }

procedure TStencilDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej
  // zmianie. To ustawienie robił dawniej FitPreviewToDialog (uPreviewFit.pas:38),
  // usunięty przy porcie wzorca podglądu.
  DoubleBuffered := True;
  // Koalescencja podglądu: ciężki rdzeń DoStencil liczy się raz po ustaniu
  // zmian, a nie na każdy tik suwaka / każdy piksel ruchu myszy. Ramka w
  // nawigatorze rusza się natychmiast (patrz SchedulePreview, ZoomTimerTick).
  FPreviewTimer := TTimer.Create(Self);
  FPreviewTimer.Interval := 120;
  FPreviewTimer.Enabled := False;
  FPreviewTimer.OnTimer := PreviewTimerTick;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  tbSmooth.Position := 3;
  tbEdge.Position := 3;
  tbThresh.Position := 128;
  lblSmoothVal.Caption := IntToStr(tbSmooth.Position);
  lblEdgeVal.Caption := IntToStr(tbEdge.Position);
  lblThreshVal.Caption := IntToStr(tbThresh.Position);
  tbWear.Position := 0;
  lblWearVal.Caption := IntToStr(tbWear.Position);
  FInkIndex := 0;
  FInk := cInkColors[FInkIndex];
  FWear := tbWear.Position;
  LayoutInkPalette;
end;

procedure TStencilDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TStencilDlg.tbSmoothChange(Sender: TObject);
begin
  lblSmoothVal.Caption := IntToStr(tbSmooth.Position);
  FSm := tbSmooth.Position;
  SchedulePreview;
end;

procedure TStencilDlg.tbEdgeChange(Sender: TObject);
begin
  lblEdgeVal.Caption := IntToStr(tbEdge.Position);
  FEd := tbEdge.Position;
  SchedulePreview;
end;

procedure TStencilDlg.tbThreshChange(Sender: TObject);
begin
  lblThreshVal.Caption := IntToStr(tbThresh.Position);
  FTh := tbThresh.Position;
  SchedulePreview;
end;

procedure TStencilDlg.tbWearChange(Sender: TObject);
begin
  lblWearVal.Caption := IntToStr(tbWear.Position);
  FWear := tbWear.Position;
  SchedulePreview;
end;

// Wymiary kratki liczone z najdłuższej nazwy w bieżącym języku — bez sztywnych
// pikseli, bo tłumaczenia mają różną długość (reguła layoutu TFotoForm).
procedure TStencilDlg.LayoutInkPalette;
var
  I, TW, MaxW: Integer;
begin
  if pboxInk = nil then Exit;
  pboxInk.Canvas.Font := pboxInk.Font;
  MaxW := 0;
  for I := 0 to cInkCount - 1 do
  begin
    TW := pboxInk.Canvas.TextWidth(InkDisplayName(I));
    if TW > MaxW then MaxW := TW;
  end;
  pboxInk.Height := cInkPad * 2 + cInkCount * cInkRowH;
  pboxInk.Width := cInkPad * 2 + cInkSwatch + 8 + MaxW;
end;

function TStencilDlg.InkIndexAt(X, Y: Integer): Integer;
begin
  if Y < cInkPad then Exit(-1);
  Result := (Y - cInkPad) div cInkRowH;
  if (X < 0) or (X >= pboxInk.Width) or (Result < 0) or (Result >= cInkCount) then
    Result := -1;
end;

procedure TStencilDlg.SelectInk(I: Integer);
begin
  if (I < 0) or (I >= cInkCount) or (I = FInkIndex) then Exit;
  FInkIndex := I;
  FInk := cInkColors[I];
  pboxInk.Invalidate;
  ApplyPreview;
end;

procedure TStencilDlg.pboxInkMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    SelectInk(InkIndexAt(X, Y));
end;

procedure TStencilDlg.pboxInkMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  I: Integer;
begin
  I := InkIndexAt(X, Y);
  if I >= 0 then
    pboxInk.Hint := InkDisplayHint(I)
  else
    pboxInk.Hint := '';
end;

// Kratka tuszu: kwadrat koloru + nazwa, ramka zaznaczenia czarno-biała
// (jak ramka kursora w nawigatorze).
procedure TStencilDlg.pboxInkPaint(Sender: TObject);
var
  I, Y, TX, TY: Integer;
  R: TRect;
begin
  with pboxInk.Canvas do
  begin
    Font := pboxInk.Font;
    Brush.Color := StyleServices(pboxInk).GetSystemColor(clBtnFace);
    Brush.Style := bsSolid;
    FillRect(pboxInk.ClientRect);
    Pen.Style := psSolid;
    Pen.Width := 1;
    for I := 0 to cInkCount - 1 do
    begin
      Y := cInkPad + I * cInkRowH;
      R := Rect(cInkPad, Y + (cInkRowH - cInkSwatch) div 2,
        cInkPad + cInkSwatch, Y + (cInkRowH - cInkSwatch) div 2 + cInkSwatch);
      Brush.Style := bsSolid;
      Brush.Color := cInkColors[I];
      FillRect(R);
      Brush.Style := bsClear;
      Pen.Color := clGray;
      Rectangle(R);
      if I = FInkIndex then
      begin
        Pen.Color := clBlack;
        Rectangle(Rect(R.Left - 2, R.Top - 2, R.Right + 2, R.Bottom + 2));
        Brush.Style := bsSolid;
        Brush.Color := clWhite;
        FrameRect(Rect(R.Left - 3, R.Top - 3, R.Right + 3, R.Bottom + 3));
        Brush.Style := bsClear;
      end;
      TX := cInkPad + cInkSwatch + 8;
      TY := Y + (cInkRowH - TextHeight('Wg')) div 2;
      Font.Color := StyleServices(pboxInk).GetStyleFontColor(sfTextLabelNormal);
      TextOut(TX, TY, InkDisplayName(I));
    end;
    Brush.Style := bsSolid;
  end;
end;

procedure TStencilDlg.SchedulePreview;
begin
  FPreviewDirty := True;
  // NIE restartuj timera. Restart przy każdym OnChange (suwak generuje ich
  // dziesiątki na sekundę) sprawiał, że odliczanie nigdy nie dobiegało końca i
  // podgląd odświeżał się dopiero po zatrzymaniu suwaka. Timer z włączonym
  // "enabled only if not enabled" odpala się okresowo, a kolejne zmiany tylko
  // podnoszą flagę — render widzi zawsze najświeższy stan pól.
  if (FPreviewTimer <> nil) and (not FPreviewTimer.Enabled) then
    FPreviewTimer.Enabled := True;
end;

procedure TStencilDlg.PreviewTimerTick(Sender: TObject);
begin
  FPreviewTimer.Enabled := False;
  if FPreviewDirty then
  begin
    FPreviewDirty := False;
    ApplyPreview;
  end;
end;

procedure TStencilDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TStencilDlg.ApplyPreview;
begin
  // OnChange z FormCreate (tbSmooth.Position := 3) odpala się PRZED
  // utworzeniem bitmap -> guard jak w innych dialogach.
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoStencil(FWorkingPreview, FSm, FEd, FTh, FInk, FWear);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TStencilDlg.ApplyFull;
begin
  DoStencil(FSourceBmp, tbSmooth.Position, tbEdge.Position, tbThresh.Position, FInk, tbWear.Position);
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TStencilDlg.CursorRect: TRect;
var
  Sx, Sy: Double;
begin
  Sx := FNavW / FSourceBmp.Width;
  Sy := FNavH / FSourceBmp.Height;
  Result.Left := Max(0, Round(FZoomX * Sx));
  Result.Top := Max(0, Round(FZoomY * Sy));
  Result.Right := Min(FNavW, Round((FZoomX + FZoomW) * Sx));
  Result.Bottom := Min(FNavH, Round((FZoomY + FZoomH) * Sy));
end;

// Odświeża tylko obszar objęty aRect (współrzędne nawigatora).
procedure TStencilDlg.InvalidateNavRect(aRect: TRect);
var
  P: TWinControl;
begin
  P := pboxPreview.Parent;
  if (P = nil) or (P.Handle = 0) then Exit;
  InflateRect(aRect, 1, 1);
  if aRect.Left < 0 then aRect.Left := 0;
  if aRect.Top < 0 then aRect.Top := 0;
  if aRect.Right > FNavW then aRect.Right := FNavW;
  if aRect.Bottom > FNavH then aRect.Bottom := FNavH;
  OffsetRect(aRect, pboxPreview.Left, pboxPreview.Top);
  InvalidateRect(P.Handle, @aRect, False);
end;

procedure TStencilDlg.RebuildZoom(X, Y: Integer);
var
  MaxX, MaxY: Integer;
  R, C, UR: TRect;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  MaxX := FSourceBmp.Width - FZoomW;
  MaxY := FSourceBmp.Height - FZoomH;
  if MaxX < 0 then MaxX := 0;
  if MaxY < 0 then MaxY := 0;
  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  if X > MaxX then X := MaxX;
  if Y > MaxY then Y := MaxY;
  // Pozycja bez zmian (kursor w tym samym pikselu) — nie przeliczamy niczego.
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  R := CursorRect;   // stara pozycja ramki
  FZoomX := X;
  FZoomY := Y;
  // Ramka rusza się natychmiast (tanie). Ciężki render 100% (DoStencil na
  // regionie) idzie przez FZoomTimer, żeby szybki ruch myszy nie odpalał
  // pełnego przeliczenia na każdy piksel. Timer NIE jest restartowany przy
  // każdym ruchu (restart = nigdy nie dobiega końca przy ciągłym MouseMove);
  // odpala się okresowo, a cache regionu w RenderFragment sprawia, że przy
  // ruchu mniejszym niż margines idzie tylko tanie CopyRect.
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  FZoomDirty := True;
  if (FZoomTimer <> nil) and (not FZoomTimer.Enabled) then
    FZoomTimer.Enabled := True;
end;

// Podgląd 100% — efekt Mimeograph nie redukuje się do per-pikselowego LUT
// (blur -> Laplacjan SAT -> invert -> próg -> opening dylatacji), więc wierny
// 1:1 robimy uruchamiając realny rdzeń (DoStencil) na regionie źródła
// powiększonym o margines = smooth + edge + opening (2+2). Wszystkie etapy są
// lokalne (rozmycia/konwolucje o promieniu <= promień, clamp-to-edge przy
// brzegu), więc z marginesem wewnętrzny fragment jest identyczny z pełnym
// przeliczeniem. Żeby jazda myszą nie przeliczała efektu od zera, region jest
// większy od okna (zapas) i cache'owany w FEffBmp: dopóki okno mieści się w
// zapamiętanym regionie, robimy tylko tani CopyRect.
procedure TStencilDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Margin := FSm + FEd + 6;
  // Poza marginesem efektu zapas na ruch myszy (region cache), aby okno
  // zdążyło się przesunąć bez przeliczania efektu od nowa.
  if Margin < 64 then Margin := 64;
  if (not FEffValid) or (FEffBmp = nil)
    or (FZoomX < FEffX) or (FZoomY < FEffY)
    or (FZoomX + FZoomW > FEffX + FEffW)
    or (FZoomY + FZoomH > FEffY + FEffH) then
  begin
    X0 := FZoomX - Margin;
    Y0 := FZoomY - Margin;
    X1 := FZoomX + FZoomW + Margin;
    Y1 := FZoomY + FZoomH + Margin;
    if X0 < 0 then X0 := 0;
    if Y0 < 0 then Y0 := 0;
    if X1 > FSourceBmp.Width - 1 then X1 := FSourceBmp.Width - 1;
    if Y1 > FSourceBmp.Height - 1 then Y1 := FSourceBmp.Height - 1;
    CW := X1 - X0 + 1;
    CH := Y1 - Y0 + 1;
    if (CW <= 0) or (CH <= 0) then Exit;
    if FEffBmp = nil then
      FEffBmp := TBitmap.Create;
    FEffBmp.PixelFormat := pf24bit;
    FEffBmp.SetSize(CW, CH);
    FEffBmp.Canvas.CopyRect(Rect(0, 0, CW, CH), FSourceBmp.Canvas,
      Rect(X0, Y0, X1 + 1, Y1 + 1));
    DoStencil(FEffBmp, FSm, FEd, FTh, FInk, FWear);
    FEffX := X0;
    FEffY := Y0;
    FEffW := CW;
    FEffH := CH;
    FEffValid := True;
  end;
  dstX := FZoomX - FEffX;
  dstY := FZoomY - FEffY;
  FZoomBmp.Canvas.CopyRect(Rect(0, 0, FZoomW, FZoomH), FEffBmp.Canvas,
    Rect(dstX, dstY, dstX + FZoomW, dstY + FZoomH));
  FZoomDirty := False;
end;

procedure TStencilDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TStencilDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TStencilDlg.pboxPreviewPaint(Sender: TObject);
var
  R: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) then
      Draw(0, 0, FWorkingPreview);
    if (FSourceBmp <> nil) and (FZoomW > 0) and (FZoomH > 0) then
    begin
      // Ramka obszaru podglądu 100%.
      R := CursorRect;
      Brush.Style := bsClear;
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Rectangle(R);
      Pen.Color := clWhite;
      FrameRect(Rect(R.Left - 1, R.Top - 1, R.Right + 1, R.Bottom + 1));
      Pen.Width := 1;
      Brush.Style := bsSolid;
    end;
  end;
end;

end.
