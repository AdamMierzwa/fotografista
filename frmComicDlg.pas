unit frmComicDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uQuantize, uI18n, uTitleBar, uMacros;

type
  // Ustawienia okna, z ktorymi liczony jest wynik (porownanie: czy gotowy
  // wynik w tle pasuje do biezacych ustawien).
  TComicParams = record
    Style, Colors, Edge, Thick, Accent: Integer;
  end;

  // Watek roboczy: DoComic na wlasnej kopii pelnego obrazu (podglad 100%
  // i nawigator), zeby okno nie stalo w miejscu na czas liczenia. Kod stylow
  // nie uzywa Canvas ani zmiennych globalnych (gComicAccent - threadvar).
  TComicWorker = class(TThread)
  public
    Bmp: TBitmap;             // kopia robocza (pf24bit); po zakonczeniu wynik
    Params: TComicParams;
    constructor Create(ASource: TBitmap; const AParams: TComicParams);
    destructor Destroy; override;
    procedure Execute; override;
  end;

  TComicDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblColors: TLabel;
    tbColors: TTrackBar;
    lblCValue: TLabel;
    rgStyle: TRadioGroup;
    rgAccent: TRadioGroup;
    lblEdge: TLabel;
    tbEdge: TTrackBar;
    lblEValue: TLabel;
    lblThick: TLabel;
    tbThick: TTrackBar;
    lblTValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    pboxZoom: TPaintBox;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbColorsChange(Sender: TObject);
    procedure rgStyleClick(Sender: TObject);
    procedure rgAccentClick(Sender: TObject);
    procedure tbEdgeChange(Sender: TObject);
    procedure tbThickChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FZoomBmp: TBitmap;      // fragment 1:1 wyswietlany w pboxZoom
    FFullBmp: TBitmap;      // wynik efektu na pelnym obrazie (zrodlo podgladu 100%)
    FFullValid: Boolean;
    FZoomTimer: TTimer;     // opoznione przeliczenie FFullBmp po zmianie parametrow
    FFullParams: TComicParams;   // ustawienia, z ktorymi policzono FFullBmp
    FWorker: TComicWorker;  // nil = brak liczenia w tle
    FPending: Boolean;      // ustawienia zmienily sie w trakcie liczenia
    FWorkTimer: TTimer;     // sprawdza koniec liczenia w tle (co 50 ms)
    FStatus: TLabel;        // „Przetwarzanie…” - podglady pokazuja jeszcze stary wynik
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure UpdateStatus;
    function CurrentParams: TComicParams;
    procedure StartFullWork;
    procedure TakeWorkerResult;
    procedure WorkTimerTick(Sender: TObject);
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
    procedure ZoomTimerTick(Sender: TObject);
  end;

function ShowComicDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
// Accent: farba akcentu stylu Ben-Day - kolor (0 czerwona, 1 zielona, 2 niebieska,
// 3 zolta); inne style ja pomijaja.
procedure DoComic(Bitmap: TBitmap; Style, Colors, EdgePct: Integer; ThickPct: Integer = -1;
  Accent: Integer = 0);
// Nazwa stylu do wyswietlenia (tlumaczona albo robocza); '' poza zakresem.
function ComicStyleName(Style: Integer): string;
// Nazwa stylu ostatnio zatwierdzonego w oknie (pasek stanu, historia Cofnij).
function ComicLastStyleName: string;
// Krok makra COMIC w Zarzadzaniu makrami: nazwa na liscie krokow
// („Komiks: Ben-Day – kolor”) i wiersze panelu szczegolow
// („Czulosc krawedzi: 50”, ...).
function ComicMacroName(const Params: string): string;
function ComicMacroDetails(const Params: string): TArray<string>;

implementation

uses
  uComicCzarnoBialy, uComicGazeta, uComicKomiks1, uComicKomiks2;

type
  TComicStyleProc = procedure(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);
  TComicStyle = record
    Name: string;          // klucz EN dla T() albo nazwa robocza
    Translate: Boolean;    // False: nazwa robocza, bez tlumaczenia (do zatwierdzenia stylu)
    Proc: TComicStyleProc; // procedura z unitu stylu (uComic*.pas)
    UsesColors: Boolean;   // dziala suwak Kolory
    UsesThick: Boolean;    // dziala suwak Grubosc
    UsesAccent: Boolean;   // dziala wybor Kolor tuszu (farba akcentu)
  end;

var
  gComicLastStyle: Integer = 0;

// threadvar (2026-10-23): pelny podglad liczy DoComic w watku roboczym
// (TComicWorker) rownolegle z miniatura w watku glownym - kazdy watek ma
// wlasna farbe akcentu. Domyslnie 0, jak dotad.
threadvar
  gComicAccent: Integer;   // farba akcentu dla ComicGazetaProc (ustawia DoComic)

// Posrednik stylu Gazeta: wspolna sygnatura tabeli nie ma pola farby, wiec
// farba idzie przez gComicAccent (sygnatury pozostalych stylow bez zmian).
// Pole Colors Gazeta pomija.
procedure ComicGazetaProc(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);
begin
  DoComicGazeta(Bitmap, gComicAccent, EdgePct, ThickPct);
end;

const
  // JEDYNE zrodlo listy stylow: pozycje w ramce Styl, wybor procedury, aktywne
  // suwaki, nazwa na pasku stanu i w historii Cofnij. Indeks = numer stylu
  // zapisywany w makrze COMIC - nowe style dopisywac TYLKO na koncu (zmiana
  // kolejnosci albo usuniecie ze srodka zmienia znaczenie zapisanych makr).
  // Zestaw zamkniety 2026-10-20 (przed wydaniem 1.3.0, makra COMIC z wersji
  // roboczych nie sa chronione): usuniete Kreskowka i Stary druk (wchlonela go
  // Pop-art - dwie farby z wyborem farby). 2026-10-24: Pop-art - czern / dwie
  // farby przemianowane na Ben-Day - czern / kolor (czern + jeden kolor, nie
  // dwie farby do wyboru; "pop-art" to nazwa potoczna).
  cComicStyles: array[0..3] of TComicStyle = (
    (Name: 'Ben-Day - black';    Translate: True;  Proc: DoComicCzarnoBialy; UsesColors: False; UsesThick: True; UsesAccent: False),
    (Name: 'Ben-Day - color';    Translate: True;  Proc: ComicGazetaProc;    UsesColors: False; UsesThick: True; UsesAccent: True),
    (Name: 'PRL - soft';         Translate: True;  Proc: DoComic1;           UsesColors: True;  UsesThick: True; UsesAccent: False),
    (Name: 'PRL - halftone';     Translate: True;  Proc: DoComic2;           UsesColors: True;  UsesThick: True; UsesAccent: False));

  // pozycje ramki Kolor tuszu (klucze EN dla T(); kolejnosc = cGazetaInks w uComicGazeta)
  cComicAccentNames: array[0..3] of string = ('Red', 'Green', 'Blue', 'Yellow');

{$R *.dfm}

function ComicStyleName(Style: Integer): string;
begin
  if (Style < Low(cComicStyles)) or (Style > High(cComicStyles)) then Exit('');
  if cComicStyles[Style].Translate then
    Result := T(cComicStyles[Style].Name)
  else
    Result := cComicStyles[Style].Name;
end;

function ComicLastStyleName: string;
begin
  Result := ComicStyleName(gComicLastStyle);
end;

// Parametry jak w fMain.RunMacroStep: styl|kolory|czulosc[|grubosc|farba];
// starsze makra bez grubosci (= czulosc) i bez farby (czerwona).
function ComicMacroParams(const Params: string): TArray<string>;
begin
  Result := Params.Split(['|']);
  if Length(Result) < 5 then SetLength(Result, 5);
  if Result[3] = '' then Result[3] := Result[2];
end;

function ComicMacroName(const Params: string): string;
var
  St: Integer;
begin
  St := StrToIntDef(ComicMacroParams(Params)[0], -1);
  if (St < Low(cComicStyles)) or (St > High(cComicStyles)) then
    Exit(T('Comic'));
  Result := T('Comic') + ': ' + ComicStyleName(St);
end;

// Etykiety z istniejacych kluczy okna Komiksu (Colors, Edge sensitivity:,
// Thickness, Ink color), farba z cComicAccentNames; parametry nieuzywane
// przez styl pomijane (jak wyszarzone kontrolki w oknie).
function ComicMacroDetails(const Params: string): TArray<string>;
var
  P: TArray<string>;
  St, Ac: Integer;

  function Lbl(const Key: string): string;
  begin
    Result := T(Key);
    if Result.EndsWith(':') then
      SetLength(Result, Length(Result) - 1);
    Result := Result + ': ';
  end;

begin
  Result := nil;
  P := ComicMacroParams(Params);
  St := StrToIntDef(P[0], -1);
  if (St < Low(cComicStyles)) or (St > High(cComicStyles)) then Exit;
  if cComicStyles[St].UsesColors then
    Result := Result + [Lbl('Colors') + P[1]];
  Result := Result + [Lbl('Edge sensitivity:') + P[2]];
  if cComicStyles[St].UsesThick then
    Result := Result + [Lbl('Thickness') + P[3]];
  if cComicStyles[St].UsesAccent then
  begin
    Ac := EnsureRange(StrToIntDef(P[4], 0), Low(cComicAccentNames), High(cComicAccentNames));
    Result := Result + [Lbl('Ink color') + T(cComicAccentNames[Ac])];
  end;
end;

// Okno Komiksu laczy niezalezne efekty - kazdy styl jest osobnym unitem
// (uComic*.pas) z wlasnym kodem; tu tylko normalizacja parametrow i wybor
// procedury z tabeli cComicStyles. ThickPct < 0: grubosc z EdgePct (makra
// COMIC z trzema polami).
procedure DoComic(Bitmap: TBitmap; Style, Colors, EdgePct: Integer; ThickPct: Integer = -1;
  Accent: Integer = 0);
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Style := EnsureRange(Style, Low(cComicStyles), High(cComicStyles));
  Colors := EnsureRange(Colors, 2, 16);
  EdgePct := EnsureRange(EdgePct, 1, 100);
  if ThickPct < 0 then ThickPct := EdgePct;
  ThickPct := EnsureRange(ThickPct, 1, 100);
  gComicAccent := EnsureRange(Accent, Low(cComicAccentNames), High(cComicAccentNames));
  cComicStyles[Style].Proc(Bitmap, Colors, EdgePct, ThickPct);
end;

{ TComicWorker }

constructor TComicWorker.Create(ASource: TBitmap; const AParams: TComicParams);
begin
  inherited Create(True);   // wstrzymany; Start po przypisaniu do FWorker
  Params := AParams;
  // Kopia tworzona w watku glownym. Assign wspoldzieli obraz ze zrodlem -
  // dostep do ScanLine wymusza wlasna kopie pikseli, zanim ruszy watek.
  Bmp := TBitmap.Create;
  Bmp.Assign(ASource);
  Bmp.PixelFormat := pf24bit;
  // sam odczyt ScanLine wymusza kopie; wynik niepotrzebny (ScanLine nie jest nil)
  if (Bmp.Height > 0) and (Bmp.ScanLine[0] = nil) then
    Exit;
end;

destructor TComicWorker.Destroy;
begin
  Bmp.Free;
  inherited;
end;

// Watek nie wywoluje metod VCL (Canvas, Invalidate) - tylko DoComic na Bmp.
procedure TComicWorker.Execute;
begin
  DoComic(Bmp, Params.Style, Params.Colors, Params.Edge, Params.Thick, Params.Accent);
end;

function ShowComicDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TComicDlg;
  Scale: Double;
  pw, ph, Short: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;

  // Szerokosc ramki, przy ktorej najdluzszy napis przelacznika miesci sie w
  // swojej kolumnie: TRadioGroup daje przelacznikowi (Width - 10) div Columns
  // (Vcl.ExtCtrls.pas, TCustomRadioGroup.ArrangeButtons); przelacznik = kolko
  // (SM_CXMENUCHECK) + odstep + napis - jak regula TEKST-W kontroli ukladu.
  function GroupNeedW(G: TRadioGroup): Integer;
  var
    J, Tw: Integer;
  begin
    Dlg.Canvas.Font.Assign(G.Font);
    Tw := 0;
    for J := 0 to G.Items.Count - 1 do
      Tw := Max(Tw, Dlg.Canvas.TextWidth(G.Items[J]));
    // + CtrlGap * 3 miedzy kolumnami (bez tego „Pop-art – dwie farby”, obecnie „Ben-Day – kolor”,
    // dochodzilo do kolka „PRL – raster”), CtrlGap * 2 przed prawa krawedzia
    Result := G.Columns * (GetSystemMetrics(SM_CXMENUCHECK) + Dlg.CtrlGap + Tw) +
      (G.Columns - 1) * Dlg.CtrlGap * 3 + Dlg.CtrlGap * 2 + 10;
    // ramka co najmniej na swoj tytul (AF „Inkkleur” przy krotkich nazwach
    // farb wchodzil na krawedz) - zapas jak w frmPerformanceDlg
    Result := Max(Result, Dlg.Canvas.TextWidth(G.Caption) + Dlg.CtrlGap * 4);
    Dlg.Canvas.Font.Assign(Dlg.Font);
  end;

  // Najkrotszy suwak w prawej kolumnie (przy malym obrazie podglady sa waskie).
  function SliderMinW: Integer;
  begin
    Dlg.Canvas.Font.Assign(Dlg.Font);
    Result := Dlg.Canvas.TextWidth('0') * 25;
  end;

  // Uklad (2026-10-23, decyzja wlasciciela): para podgladow wysrodkowana w
  // szerokosci okna (jak frmRastrCmykDlg). Pod nawigatorem ramki Styl i Kolor
  // tuszu OBOK SIEBIE, pozycje w jednej kolumnie: Kolor tuszu tak waski, jak
  // wymagaja jego krotkie nazwy, Styl - reszta kolumny. Pod podgladem 100% trzy
  // suwaki. Obie kolumny maja te sama gore i dol: suwaki rozlozone na wysokosc
  // ramek, a gdy sie nie mieszcza - ramki wydluzone do wysokosci suwakow.
  // Przyciski pod zawartoscia.
  // Kolumny pod podgladami: po polowie szerokosci okna miedzy marginesami
  // (SectionGap - ten sam margines z lewej, z prawej i na dole okna), odstep
  // CtrlGap * 2 - przy oknie z szerokosci podgladow kolumna = szerokosc
  // podgladu; przy poszerzeniu rosna obie.
  function ColW: Integer;
  begin
    Result := (Dlg.ClientWidth - Dlg.SectionGap * 2 - Dlg.CtrlGap * 2) div 2;
  end;

  procedure PlaceColumns;
  var
    Lbl, Val: array[0..2] of TLabel;
    TB: array[0..2] of TTrackBar;
    K, X, W, AccW, TH, ItemH, H, RowH, Gap, Y, Bottom: Integer;
  begin
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    W := ColW;

    Lbl[0] := Dlg.lblColors; TB[0] := Dlg.tbColors; Val[0] := Dlg.lblCValue;
    Lbl[1] := Dlg.lblEdge;   TB[1] := Dlg.tbEdge;   Val[1] := Dlg.lblEValue;
    Lbl[2] := Dlg.lblThick;  TB[2] := Dlg.tbThick;  Val[2] := Dlg.lblTValue;

    // Wysokosc ramek: 4 pozycje jak w TRadioGroup.ArrangeButtons (pozycja =
    // (Height - tmHeight - 5) div liczba, wzorzec frmPerformanceDlg). Kolumna
    // suwakow = suma wierszy (napis + suwak + odczyt) + co najmniej RowGap
    // miedzy wierszami; wyzsza z nich wyznacza wspolna wysokosc.
    Dlg.Canvas.Font.Assign(Dlg.Font);
    TH := Dlg.Canvas.TextHeight('Wg');
    ItemH := TH + Dlg.RowGap * 2;
    H := TH + 5 + Max(Dlg.rgStyle.Items.Count, Dlg.rgAccent.Items.Count) * ItemH;
    RowH := 0;
    for K := 0 to 2 do
      Inc(RowH, Lbl[K].Height + TB[K].Height + Val[K].Height);
    H := Max(H, RowH + Dlg.RowGap * 2);
    Gap := (H - RowH) div 2;

    // lewa kolumna: Styl | Kolor tuszu, prawa krawedz = krawedz nawigatora
    AccW := GroupNeedW(Dlg.rgAccent);
    Dlg.rgStyle.SetBounds(Dlg.SectionGap, Dlg.rgStyle.Top,
      W - AccW - Dlg.CtrlGap * 2, H);
    Dlg.rgAccent.SetBounds(Dlg.rgStyle.Left + Dlg.rgStyle.Width + Dlg.CtrlGap * 2,
      Dlg.rgStyle.Top, AccW, H);

    // prawa kolumna: suwaki od gory ramek (napis na wysokosci tytulu ramki)
    // do ich dolu (ostatni odczyt na dolnej krawedzi)
    X := Dlg.rgStyle.Left + W + Dlg.CtrlGap * 2;
    Y := Dlg.rgStyle.Top;
    for K := 0 to 2 do
    begin
      Lbl[K].SetBounds(X, Y, Lbl[K].Width, Lbl[K].Height);
      TB[K].SetBounds(X, Y + Lbl[K].Height, W, TB[K].Height);
      Val[K].SetBounds(X, TB[K].Top + TB[K].Height, W, Val[K].Height);
      Y := Val[K].Top + Val[K].Height + Gap;
    end;

    // przyciski pod kolumnami; pod Kolorem tuszu miejsce na Przetwarzanie...
    Bottom := Max(Dlg.rgStyle.Top + H,
      Dlg.rgAccent.Top + H + Dlg.RowGap + Dlg.FStatus.Height);
    Dlg.btnOK.Top := Bottom + Dlg.SectionGap;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
  end;

begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TComicDlg.Create(Application);
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

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

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    // Podglad 100% obok nawigatora (wzorzec frmRastrCmykDlg): ten sam rozmiar
    // co nawigator, fragment 1:1 pikseli wyniku; poczatkowo srodek obrazu.
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;
    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);
    Dlg.FZoomBmp.Canvas.Brush.Color := clBtnFace;
    Dlg.FZoomBmp.Canvas.FillRect(Rect(0, 0, pw, ph));
    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;
    Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.SetBounds(Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2,
      Dlg.pboxPreview.Top, pw, ph);
    Dlg.ApplyPreview;

    // szerokosc z pary podgladow (suwaki z .dfm stoja jeszcze po lewej, wezsze)
    Dlg.ButtonsToLeft([Dlg.btnOK, Dlg.btnCancel], Dlg.SectionGap);
    Dlg.FitToContent(Dlg.SectionGap, Dlg.SectionGap);
    Dlg.ClientWidth := pw + Dlg.CtrlGap * 2 + pw + Dlg.SectionGap * 2;
    PlaceColumns;
    // Gdy kolumna jest za waska na napisy przelacznikow (np. DE „Pop-Art – zwei
    // Farben” przy zdjeciu pionowym) albo na suwak, okno jest szersze - nie
    // wyzsze, bo wysokosc ogranicza ekran. Poszerzenie o W daje kazdej kolumnie
    // W/2 (podglady sa wysrodkowane), stad 2 x wiekszy niedobor.
    Short := Max(GroupNeedW(Dlg.rgStyle) - Dlg.rgStyle.Width,
      SliderMinW - Dlg.tbColors.Width);
    if Short > 0 then
    begin
      Dlg.ClientWidth := Dlg.ClientWidth + Short * 2 + 1;
      PlaceColumns;
    end;
    // wysokosc z zawartosci, margines dolny jak w innych oknach
    Dlg.FitHeight(Dlg.SectionGap);
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.SectionGap);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gComicLastStyle := Dlg.rgStyle.ItemIndex;
      gMacroPending.Code := 'COMIC';
      // styl|kolory|czulosc|grubosc|farba (odczyt: fMain.RunMacroStep, krotsze
      // makra uzupelniane domyslnymi)
      gMacroPending.Params := IntToStr(Dlg.rgStyle.ItemIndex) + '|' +
        IntToStr(Dlg.tbColors.Position) + '|' + IntToStr(Dlg.tbEdge.Position) + '|' +
        IntToStr(Dlg.tbThick.Position) + '|' + IntToStr(Dlg.rgAccent.ItemIndex);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TComicDlg }

procedure TComicDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  tbColors.Min := 2;
  tbColors.Max := 16;
  tbColors.Position := 8;
  lblCValue.Caption := IntToStr(tbColors.Position);
  for I := Low(cComicStyles) to High(cComicStyles) do
    rgStyle.Items.Add(ComicStyleName(I));
  for I := Low(cComicAccentNames) to High(cComicAccentNames) do
    rgAccent.Items.Add(T(cComicAccentNames[I]));
  rgAccent.ItemIndex := 0;
  rgStyle.ItemIndex := 0;
  tbEdge.Min := 1;
  tbEdge.Max := 100;
  tbEdge.Position := 50;
  lblEValue.Caption := IntToStr(tbEdge.Position);
  tbThick.Min := 1;
  tbThick.Max := 100;
  tbThick.Position := 50;
  lblTValue.Caption := IntToStr(tbThick.Position);
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 400;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  FWorkTimer := TTimer.Create(Self);
  FWorkTimer.Interval := 50;
  FWorkTimer.Enabled := False;
  FWorkTimer.OnTimer := WorkTimerTick;
  FStatus := TLabel.Create(Self);
  FStatus.Parent := rgAccent.Parent;
  FStatus.StyleElements := [seClient, seBorder];
  FStatus.Caption := T('Processing...');
  FStatus.Visible := False;
end;

// Napis „Przetwarzanie…” pod ramka Kolor tuszu, gdy podglady czekaja na nowy
// pelny wynik (zmiana ustawien, liczenie w tle albo czekanie na start).
procedure TComicDlg.UpdateStatus;
begin
  if FStatus = nil then Exit;
  FStatus.SetBounds(rgAccent.Left, rgAccent.Top + rgAccent.Height + RowGap,
    FStatus.Width, FStatus.Height);
  FStatus.Visible := (FFullBmp <> nil) and
    ((FWorker <> nil) or FPending or FZoomTimer.Enabled);
end;

procedure TComicDlg.FormDestroy(Sender: TObject);
begin
  // DoComic nie ma punktow przerwania - zamkniecie okna w trakcie liczenia
  // czeka na koniec watku (watek pracuje na wlasnej kopii obrazu).
  if FWorker <> nil then
  begin
    FWorker.WaitFor;
    FreeAndNil(FWorker);
  end;
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FFullBmp.Free;
end;

procedure TComicDlg.tbColorsChange(Sender: TObject);
begin
  lblCValue.Caption := IntToStr(tbColors.Position);
  ApplyPreview;
end;

procedure TComicDlg.rgStyleClick(Sender: TObject);
begin
  // Suwaki nieuzywane przez wybrany styl sa wyszarzone (tabela cComicStyles).
  if (rgStyle.ItemIndex >= Low(cComicStyles)) and
     (rgStyle.ItemIndex <= High(cComicStyles)) then
  begin
    tbColors.Enabled := cComicStyles[rgStyle.ItemIndex].UsesColors;
    tbThick.Enabled := cComicStyles[rgStyle.ItemIndex].UsesThick;
    rgAccent.Enabled := cComicStyles[rgStyle.ItemIndex].UsesAccent;
  end;
  lblColors.Enabled := tbColors.Enabled;
  lblCValue.Enabled := tbColors.Enabled;
  lblThick.Enabled := tbThick.Enabled;
  lblTValue.Enabled := tbThick.Enabled;
  ApplyPreview;
end;

procedure TComicDlg.rgAccentClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TComicDlg.tbEdgeChange(Sender: TObject);
begin
  lblEValue.Caption := IntToStr(tbEdge.Position);
  ApplyPreview;
end;

procedure TComicDlg.tbThickChange(Sender: TObject);
begin
  lblTValue.Caption := IntToStr(tbThick.Position);
  ApplyPreview;
end;

procedure TComicDlg.ApplyPreview;
begin
  if not Assigned(FOriginalPreview) or not Assigned(FWorkingPreview) then Exit;
  // Szybki podglad z miniatury tylko do pierwszego pelnego wyniku: ma inna
  // skale (np. raster) niz wynik, wiec pozniej przeskakiwanie miniatura <->
  // pelny wynik migotalo. Potem nawigator i podglad 100% zostaja przy
  // ostatnim pelnym wyniku, a napis „Przetwarzanie…” mowi, ze sa stare.
  if FFullBmp = nil then
  begin
    FWorkingPreview.Canvas.Draw(0, 0, FOriginalPreview);
    DoComic(FWorkingPreview, rgStyle.ItemIndex, tbColors.Position, tbEdge.Position,
      tbThick.Position, rgAccent.ItemIndex);
    pboxPreview.Invalidate;
  end;
  // Podglad 100% do przeliczenia - po ustaniu zmian (restart timera), bo
  // wymaga efektu na calym obrazie.
  FFullValid := False;
  if FZoomTimer <> nil then
  begin
    FZoomTimer.Enabled := False;
    FZoomTimer.Enabled := True;
  end;
  UpdateStatus;
end;

// Efekt Komiksu nie jest lokalny (skala robocza, plamy i siatka rastra zaleza
// od wymiarow calego obrazu), wiec - inaczej niz w frmRastrCmykDlg - wycinek
// nie moze byc liczony osobno: wierny 1:1 to fragment wyniku na pelnym obrazie.
// Liczony raz po zmianie parametrow (w tle, TComicWorker); ruch myszy tylko
// kopiuje fragment.
procedure TComicDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  StartFullWork;
  UpdateStatus;
end;

function TComicDlg.CurrentParams: TComicParams;
begin
  Result.Style := rgStyle.ItemIndex;
  Result.Colors := tbColors.Position;
  Result.Edge := tbEdge.Position;
  Result.Thick := tbThick.Position;
  Result.Accent := rgAccent.ItemIndex;
end;

function SameComicParams(const A, B: TComicParams): Boolean;
begin
  Result := (A.Style = B.Style) and (A.Colors = B.Colors) and (A.Edge = B.Edge) and
    (A.Thick = B.Thick) and (A.Accent = B.Accent);
end;

// Start liczenia pelnego obrazu w tle. Gdy watek juz liczy - zapamietaj, ze
// po nim trzeba policzyc jeszcze raz (biezace ustawienia).
procedure TComicDlg.StartFullWork;
begin
  if FSourceBmp = nil then Exit;
  if FWorker <> nil then
  begin
    FPending := True;
    Exit;
  end;
  FPending := False;
  FWorker := TComicWorker.Create(FSourceBmp, CurrentParams);
  FWorker.Start;
  FWorkTimer.Enabled := True;
end;

// Odbior wyniku w watku glownym. Wynik dla nieaktualnych ustawien odrzucany.
procedure TComicDlg.TakeWorkerResult;
var
  W: TComicWorker;
begin
  W := FWorker;
  FWorker := nil;
  if W = nil then Exit;
  try
    W.WaitFor;
    if not SameComicParams(W.Params, CurrentParams) then Exit;
    FFullBmp.Free;
    FFullBmp := W.Bmp;
    W.Bmp := nil;
    FFullParams := W.Params;
    FFullValid := True;
  finally
    W.Free;
  end;
  // Nawigator = pomniejszony wynik pelnego obrazu (HALFTONE usrednia kropki).
  // Efekt liczony na miniaturze ma inna skale - np. raster CMYK Komiksu 2
  // dostaje tam siatke 2 px i falszywe kolory - wiec zostaje tylko szybkim
  // podgladem na czas przeliczania.
  SetStretchBltMode(FWorkingPreview.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(FWorkingPreview.Canvas.Handle, 0, 0, nil);
  StretchBlt(FWorkingPreview.Canvas.Handle, 0, 0, FWorkingPreview.Width,
    FWorkingPreview.Height, FFullBmp.Canvas.Handle, 0, 0, FFullBmp.Width,
    FFullBmp.Height, SRCCOPY);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TComicDlg.WorkTimerTick(Sender: TObject);
begin
  if (FWorker <> nil) and FWorker.Finished then
  begin
    TakeWorkerResult;
    if FPending then StartFullWork;
  end;
  if FWorker = nil then
    FWorkTimer.Enabled := False;
  UpdateStatus;
end;

procedure TComicDlg.RenderFragment;
begin
  // Fragment z ostatniego pelnego wyniku, takze w trakcie liczenia nowego
  // (FFullValid = False) - ruch myszy dalej przesuwa fragment.
  if (FZoomBmp = nil) or (FFullBmp = nil) then Exit;
  FZoomBmp.Canvas.CopyRect(Rect(0, 0, FZoomW, FZoomH), FFullBmp.Canvas,
    Rect(FZoomX, FZoomY, FZoomX + FZoomW, FZoomY + FZoomH));
end;

// Pozycja ramki podgladu 100% w pikselach nawigatora.
function TComicDlg.CursorRect: TRect;
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

// Odswieza tylko obszar objety aRect (wspolrzedne nawigatora).
procedure TComicDlg.InvalidateNavRect(aRect: TRect);
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

procedure TComicDlg.RebuildZoom(X, Y: Integer);
var
  MaxX, MaxY: Integer;
  R, C, UR: TRect;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  MaxX := Max(0, FSourceBmp.Width - FZoomW);
  MaxY := Max(0, FSourceBmp.Height - FZoomH);
  X := EnsureRange(X, 0, MaxX);
  Y := EnsureRange(Y, 0, MaxY);
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  R := CursorRect;   // stara pozycja ramki
  FZoomX := X;
  FZoomY := Y;
  RenderFragment;
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  pboxZoom.Invalidate;
end;

procedure TComicDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (FSourceBmp = nil) or (FNavW = 0) or (FNavH = 0) then Exit;
  // Srodek kursora = srodek podgladu 100%.
  RebuildZoom(Round(X * FSourceBmp.Width / FNavW) - FZoomW div 2,
    Round(Y * FSourceBmp.Height / FNavH) - FZoomH div 2);
end;

procedure TComicDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

// OK: gdy w tle liczy sie albo jest juz policzony wynik dla biezacych
// ustawien - przejmij go zamiast liczyc drugi raz.
procedure TComicDlg.ApplyFull;
begin
  if FWorker <> nil then
    TakeWorkerResult;
  if FFullValid and (FFullBmp <> nil) and SameComicParams(FFullParams, CurrentParams) then
    FSourceBmp.Assign(FFullBmp)
  else
    DoComic(FSourceBmp, rgStyle.ItemIndex, tbColors.Position, tbEdge.Position,
      tbThick.Position, rgAccent.ItemIndex);
end;

procedure TComicDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);

    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;

      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;

      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);

      DestRect := Rect(
        (TargetW - NewW) div 2,
        (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW,
        (TargetH - NewH) div 2 + NewH
      );

      StretchDraw(DestRect, FWorkingPreview);

      // Ramka obszaru podgladu 100% (nawigator ma rozmiar FNavW x FNavH,
      // wiec DestRect zaczyna sie w 0,0).
      if (FSourceBmp <> nil) and (FNavW > 0) and (FZoomW > 0) then
      begin
        DestRect := CursorRect;
        Brush.Style := bsClear;
        Pen.Style := psSolid;
        Pen.Color := clBlack;
        Pen.Width := 1;
        Rectangle(DestRect);
        Brush.Color := clWhite;
        FrameRect(Rect(DestRect.Left - 1, DestRect.Top - 1,
          DestRect.Right + 1, DestRect.Bottom + 1));
        Brush.Style := bsSolid;
      end;
    end;
  end;
end;

end.
