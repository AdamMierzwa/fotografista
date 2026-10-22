unit frmComicDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uQuantize, uI18n, uTitleBar, uMacros;

type
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
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
    procedure ZoomTimerTick(Sender: TObject);
  end;

function ShowComicDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
// Accent: farba akcentu stylu Pop-art - dwie farby (0 czerwona, 1 zielona, 2 niebieska,
// 3 zolta); inne style ja pomijaja.
procedure DoComic(Bitmap: TBitmap; Style, Colors, EdgePct: Integer; ThickPct: Integer = -1;
  Accent: Integer = 0);
// Nazwa stylu do wyswietlenia (tlumaczona albo robocza); '' poza zakresem.
function ComicStyleName(Style: Integer): string;
// Nazwa stylu ostatnio zatwierdzonego w oknie (pasek stanu, historia Cofnij).
function ComicLastStyleName: string;
// Krok makra COMIC w Zarzadzaniu makrami: nazwa na liscie krokow
// („Komiks: Pop-art – dwie farby”) i wiersze panelu szczegolow
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
  gComicAccent: Integer = 0;   // farba akcentu dla ComicGazetaProc (ustawia DoComic)

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
  // Pop-art - dwie farby z wyborem farby).
  cComicStyles: array[0..3] of TComicStyle = (
    (Name: 'Pop art - black';    Translate: True;  Proc: DoComicCzarnoBialy; UsesColors: False; UsesThick: True; UsesAccent: False),
    (Name: 'Pop art - two inks'; Translate: True;  Proc: ComicGazetaProc;    UsesColors: False; UsesThick: True; UsesAccent: True),
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
    Dlg.Canvas.Font.Assign(Dlg.Font);
    Result := G.Columns * (GetSystemMetrics(SM_CXMENUCHECK) + Dlg.CtrlGap + Tw) + 10;
  end;

  // Para podgladow wysrodkowana w szerokosci okna (jak frmRastrCmykDlg),
  // ramki w swoich kolumnach: Styl konczy sie przed kolumna podgladu 100%,
  // Kolor tuszu na prawym marginesie okna (jak w FitToContent).
  procedure PlaceColumns;
  begin
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.rgAccent.Left := Dlg.pboxZoom.Left;
    Dlg.rgStyle.Width := Dlg.pboxZoom.Left - Dlg.CtrlGap * 2 - Dlg.rgStyle.Left;
    Dlg.rgAccent.Width := Dlg.ClientWidth - Dlg.CtrlGap * 3 - Dlg.rgAccent.Left;
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
    // Kolor tuszu: w wolnej kolumnie pod podgladem 100%, na wysokosci ramki Styl.
    Dlg.rgAccent.SetBounds(Dlg.pboxZoom.Left, Dlg.rgStyle.Top, Dlg.rgStyle.Width,
      Dlg.rgStyle.Height);

    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);
    // Przy obrazie pionowym (podglady wezsze niz 400 px) obie ramki mialy 400 px
    // z .dfm: Kolor tuszu zaslanial prawa krawedz Stylu i wystawal poza okno.
    PlaceColumns;
    // Gdy kolumna jest za waska na napisy przelacznikow (np. DE „Pop-Art – zwei
    // Farben” przy zdjeciu pionowym), okno jest szersze - nie wyzsze, bo
    // wysokosc ogranicza ekran. Poszerzenie o W daje kazdej kolumnie W/2
    // (podglady sa wysrodkowane), stad 2 x wiekszy niedobor.
    Short := Max(GroupNeedW(Dlg.rgStyle) - Dlg.rgStyle.Width,
      GroupNeedW(Dlg.rgAccent) - Dlg.rgAccent.Width);
    if Short > 0 then
    begin
      Dlg.ClientWidth := Dlg.ClientWidth + Short * 2 + 1;
      PlaceColumns;
    end;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

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
end;

procedure TComicDlg.FormDestroy(Sender: TObject);
begin
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
  FWorkingPreview.Canvas.Draw(0, 0, FOriginalPreview);
  DoComic(FWorkingPreview, rgStyle.ItemIndex, tbColors.Position, tbEdge.Position,
    tbThick.Position, rgAccent.ItemIndex);
  pboxPreview.Invalidate;
  // Podglad 100% do przeliczenia - po ustaniu zmian (restart timera), bo
  // wymaga efektu na calym obrazie.
  FFullValid := False;
  if FZoomTimer <> nil then
  begin
    FZoomTimer.Enabled := False;
    FZoomTimer.Enabled := True;
  end;
end;

// Efekt Komiksu nie jest lokalny (skala robocza, plamy i siatka rastra zaleza
// od wymiarow calego obrazu), wiec - inaczej niz w frmRastrCmykDlg - wycinek
// nie moze byc liczony osobno: wierny 1:1 to fragment wyniku na pelnym obrazie.
// Liczony raz po zmianie parametrow; ruch myszy tylko kopiuje fragment.
procedure TComicDlg.ZoomTimerTick(Sender: TObject);
var
  OldCursor: TCursor;
begin
  FZoomTimer.Enabled := False;
  if FSourceBmp = nil then Exit;
  OldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    if FFullBmp = nil then
      FFullBmp := TBitmap.Create;
    FFullBmp.Assign(FSourceBmp);
    FFullBmp.PixelFormat := pf24bit;
    DoComic(FFullBmp, rgStyle.ItemIndex, tbColors.Position, tbEdge.Position,
      tbThick.Position, rgAccent.ItemIndex);
    FFullValid := True;
    // Nawigator = pomniejszony wynik pelnego obrazu (HALFTONE usrednia kropki).
    // Efekt liczony na miniaturze ma inna skale - np. raster CMYK Komiksu 2
    // dostaje tam siatke 2 px i falszywe kolory - wiec zostaje tylko szybkim
    // podgladem na czas przeliczania.
    SetStretchBltMode(FWorkingPreview.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(FWorkingPreview.Canvas.Handle, 0, 0, nil);
    StretchBlt(FWorkingPreview.Canvas.Handle, 0, 0, FWorkingPreview.Width,
      FWorkingPreview.Height, FFullBmp.Canvas.Handle, 0, 0, FFullBmp.Width,
      FFullBmp.Height, SRCCOPY);
  finally
    Screen.Cursor := OldCursor;
  end;
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TComicDlg.RenderFragment;
begin
  if (FZoomBmp = nil) or (FFullBmp = nil) or not FFullValid then Exit;
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

procedure TComicDlg.ApplyFull;
begin
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
