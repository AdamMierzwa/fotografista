unit uLayoutCheck;

// Kontrola ukladu okien - tylko build Debug (2026-10-21). Wolana z
// TfrmMain.FormActiveChanged po TranslateForm i RefitButtons: sprawdza
// liczbowo widoczne kontrolki aktywnego okna i dopisuje wynik do pliku
// kontrola_ukladu.txt obok EXE. Kazde okno sprawdzane raz na kombinacje
// klasa + tytul + jezyk + czcionka + rozmiar (ponowna aktywacja tego samego
// okna nie dubluje wpisow). Okno glowne pomijane.
//
// Reguly:
//   POZA      - kontrolka (Align = alNone) wychodzi poza obszar rodzica
//   TEKST-W   - napis szerszy niz kontrolka (przycisk, pole wyboru,
//               przelacznik, tytul ramki, etykieta bez AutoSize)
//   TEKST-H   - tekst wyzszy niz kontrolka (w tym etykieta zawijana)
//   NACHODZI  - dwie sasiednie kontrolki (ten sam rodzic, Align = alNone)
//               maja wspolny obszar
//   PRZYCISK-H - przycisk o wysokosci innej niz domyslna (25 px przy 96 DPI)
//   EKRAN     - okno wieksze niz obszar roboczy monitora
//   CZCIONKA  - czcionka okna (nazwa lub rozmiar) inna niz czcionka programu
//               (Application.DefaultFont) - np. forma bez .dfm bez Font.Assign
// Progi marginesow (cBtnPad, cBoxGap, cGroupPad) sa przyblizone - wpis to
// sygnal do obejrzenia okna, nie wyrok.
// INFO (nie liczone jako problem): TEKST-H odczytu wartosci - etykieta bez
// AutoSize o wysokosci 18 px przy 96 DPI (regula AGENTS.md dla odczytow przy
// suwakach; przycinanie przy 11-12 pt swiadomie zaakceptowane).

interface

uses
  Vcl.Forms;

procedure CheckFormLayout(AForm: TCustomForm);

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.Math,
  System.TypInfo, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics, uI18n;

const
  cLogName = 'kontrola_ukladu.txt';
  cBtnPad = 8;       // lacznie po obu stronach napisu w przycisku
  cBoxGap = 4;       // odstep kwadracika pola wyboru od napisu
  cGroupPad = 16;    // tytul ramki: wciecie z lewej + zapas z prawej
  cButtonH96 = 25;   // domyslna wysokosc TButton przy 96 DPI
  cReadoutH96 = 18;  // wysokosc odczytu wartosci przy suwaku (AGENTS.md)

type
  TControlAccess = class(TControl);

var
  gChecked: TStringList = nil;   // klucze juz sprawdzonych okien
  gMeasure: TBitmap = nil;       // plotno do pomiaru tekstu

function StripAmp(const S: string): string;
var
  I: Integer;
begin
  // '&x' -> 'x', '&&' -> '&' (jak wyswietla VCL przy ShowAccelChar)
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '&') and (I < Length(S)) then
      Inc(I);
    Result := Result + S[I];
    Inc(I);
  end;
end;

function CtlName(C: TControl): string;
var
  Cap: string;
begin
  if C.Name <> '' then
    Result := C.Name + ': ' + C.ClassName
  else
    Result := C.ClassName;
  Cap := StripAmp(TControlAccess(C).Caption);
  if Cap <> '' then
  begin
    if Length(Cap) > 40 then
      Cap := Copy(Cap, 1, 40) + '...';
    Result := Result + ' ''' + Cap + '''';
  end;
end;

procedure UseFont(C: TControl);
begin
  gMeasure.Canvas.Font.Assign(TControlAccess(C).Font);
end;

function TW(const S: string): Integer;
begin
  Result := gMeasure.Canvas.TextWidth(S);
end;

function TH: Integer;
begin
  Result := gMeasure.Canvas.TextHeight('Wg');
end;

// wysokosc tekstu zawijanego w podanej szerokosci
function WrapHeight(const S: string; AWidth: Integer): Integer;
var
  R: TRect;
begin
  R := Rect(0, 0, AWidth, 0);
  DrawText(gMeasure.Canvas.Handle, PChar(S), Length(S), R,
    DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
  Result := R.Bottom;
end;

procedure CheckText(C: TControl; Issues, Infos: TStrings);
var
  Cap: string;
  Need: Integer;
begin
  Cap := StripAmp(TControlAccess(C).Caption);
  UseFont(C);

  if C is TButton then
  begin
    if (Cap <> '') and not TButton(C).WordWrap then
    begin
      Need := TW(Cap) + cBtnPad;
      if Need > C.Width then
        Issues.Add(Format('TEKST-W  %s: napis %d px + margines %d > szerokosc %d',
          [CtlName(C), TW(Cap), cBtnPad, C.Width]));
    end;
    if TH > C.Height then
      Issues.Add(Format('TEKST-H  %s: tekst %d px > wysokosc %d', [CtlName(C), TH, C.Height]));
  end
  else if (C is TCheckBox) or (C is TRadioButton) then
  begin
    if (Cap <> '') and not (((C is TCheckBox) and TCheckBox(C).WordWrap)
      or ((C is TRadioButton) and TRadioButton(C).WordWrap)) then
    begin
      Need := GetSystemMetrics(SM_CXMENUCHECK) + cBoxGap + TW(Cap);
      if Need > C.Width then
        Issues.Add(Format('TEKST-W  %s: kwadracik + napis %d px > szerokosc %d',
          [CtlName(C), Need, C.Width]));
    end;
    if TH > C.Height then
      Issues.Add(Format('TEKST-H  %s: tekst %d px > wysokosc %d', [CtlName(C), TH, C.Height]));
  end
  else if C is TCustomGroupBox then
  begin
    if Cap <> '' then
    begin
      Need := TW(Cap) + cGroupPad;
      if Need > C.Width then
        Issues.Add(Format('TEKST-W  %s: tytul %d px + margines %d > szerokosc %d',
          [CtlName(C), TW(Cap), cGroupPad, C.Width]));
    end;
  end
  else if C is TLabel then
  begin
    if Cap = '' then Exit;
    if TLabel(C).WordWrap then
    begin
      Need := WrapHeight(Cap, C.Width);
      if Need > C.Height then
        Issues.Add(Format('TEKST-H  %s: zawiniety tekst %d px > wysokosc %d',
          [CtlName(C), Need, C.Height]));
    end
    else
    begin
      if (not TLabel(C).AutoSize) and (TW(Cap) > C.Width) then
        Issues.Add(Format('TEKST-W  %s: napis %d px > szerokosc %d',
          [CtlName(C), TW(Cap), C.Width]));
      if TH > C.Height then
      begin
        if (not TLabel(C).AutoSize)
          and (C.Height = MulDiv(cReadoutH96, C.CurrentPPI, 96)) then
          Infos.Add(Format('INFO     TEKST-H odczytu %s: tekst %d px > wysokosc %d',
            [CtlName(C), TH, C.Height]))
        else
          Issues.Add(Format('TEKST-H  %s: tekst %d px > wysokosc %d', [CtlName(C), TH, C.Height]));
      end;
    end;
  end;
end;

function IsBackground(C: TControl): Boolean;
begin
  // ksztalty tla nie sa kolizja, gdy cos na nich lezy
  Result := (C is TBevel) or (C is TShape);
end;

procedure CheckChildren(W: TWinControl; AForm: TCustomForm; Issues, Infos: TStrings);
var
  I, J, ButtonH: Integer;
  C, D: TControl;
  R: TRect;
begin
  ButtonH := MulDiv(cButtonH96, AForm.CurrentPPI, 96);
  for I := 0 to W.ControlCount - 1 do
  begin
    C := W.Controls[I];
    if not C.Visible then Continue;
    // wnetrze kontrolki zlozonej (np. strzalki TSpinEdit - TTimerSpeedButton,
    // wlasciciel TSpinButton) nie jest ukladem okna: pomijane z poddrzewem.
    // Wyjatek: przelaczniki TRadioGroup (TGroupButton = TRadioButton,
    // wlasciciel = ramka, Vcl.ExtCtrls.pas:6258, 6272-6281) - ich napisy to
    // tresc okna i maja byc sprawdzane
    if (C.Owner is TControl) and (C.Owner <> AForm)
      and not (C.Owner is TCustomRadioGroup) then Continue;

    // zawartosc przewijana (TScrollBox) moze lezec poza widocznym obszarem;
    // forma tez jest TScrollingWinControl, ale jej nie przewijamy
    if (C.Align = alNone)
      and ((W is TCustomForm) or not (W is TScrollingWinControl))
      and ((C.Left < 0) or (C.Top < 0)
        or (C.Left + C.Width > W.ClientWidth) or (C.Top + C.Height > W.ClientHeight)) then
      Issues.Add(Format('POZA     %s: [%d,%d %dx%d] poza rodzicem %s (%dx%d)',
          [CtlName(C), C.Left, C.Top, C.Width, C.Height, CtlName(W), W.ClientWidth, W.ClientHeight]));

    CheckText(C, Issues, Infos);

    if (C is TButton) and (C.Height <> ButtonH) then
      Issues.Add(Format('PRZYCISK-H %s: wysokosc %d, domyslna %d', [CtlName(C), C.Height, ButtonH]));

    if (C.Align = alNone) and not IsBackground(C) then
      for J := I + 1 to W.ControlCount - 1 do
      begin
        D := W.Controls[J];
        if (not D.Visible) or (D.Align <> alNone) or IsBackground(D) then Continue;
        if IntersectRect(R, C.BoundsRect, D.BoundsRect) and (R.Width > 0) and (R.Height > 0) then
          Issues.Add(Format('NACHODZI %s i %s: wspolne %dx%d px',
            [CtlName(C), CtlName(D), R.Width, R.Height]));
      end;

    if C is TWinControl then
      CheckChildren(TWinControl(C), AForm, Issues, Infos);
  end;
end;

procedure WriteLog(const Lines: TStrings);
var
  Path: string;
  Log: TStringList;
begin
  Path := ExtractFilePath(Application.ExeName) + cLogName;
  Log := TStringList.Create;
  try
    if FileExists(Path) then
      Log.LoadFromFile(Path, TEncoding.UTF8);
    Log.AddStrings(Lines);
    Log.SaveToFile(Path, TEncoding.UTF8);
  finally
    Log.Free;
  end;
end;

procedure CheckFormLayout(AForm: TCustomForm);
var
  Key, Lang: string;
  Issues, Infos, Lines: TStringList;
  WA: TRect;
  I: Integer;
begin
  if (AForm = nil) or (AForm = Application.MainForm) or not AForm.Visible then Exit;

  Lang := GetEnumName(TypeInfo(TLanguage), Ord(CurrentLanguage));
  Key := Format('%s|%s|%s|%d|%dx%d', [AForm.ClassName, AForm.Caption, Lang,
    AForm.Font.Size, AForm.ClientWidth, AForm.ClientHeight]);
  if gChecked = nil then
  begin
    gChecked := TStringList.Create;
    gChecked.Sorted := True;
  end;
  if gChecked.IndexOf(Key) >= 0 then Exit;
  gChecked.Add(Key);

  if gMeasure = nil then
    gMeasure := TBitmap.Create;

  Issues := TStringList.Create;
  Infos := TStringList.Create;
  Lines := TStringList.Create;
  try
    CheckChildren(AForm, AForm, Issues, Infos);
    WA := AForm.Monitor.WorkareaRect;
    if (AForm.Width > WA.Width) or (AForm.Height > WA.Height) then
      Issues.Add(Format('EKRAN    okno %dx%d > obszar roboczy %dx%d',
        [AForm.Width, AForm.Height, WA.Width, WA.Height]));
    if not SameText(AForm.Font.Name, Application.DefaultFont.Name)
      or (AForm.Font.Size <> Application.DefaultFont.Size) then
      Issues.Add(Format('CZCIONKA okno %s %d pt, program %s %d pt',
        [AForm.Font.Name, AForm.Font.Size,
         Application.DefaultFont.Name, Application.DefaultFont.Size]));

    if Issues.Count = 0 then
      Lines.Add(Format('[OK] %s ''%s'' | %s | %d pt | %dx%d | %s',
        [AForm.ClassName, AForm.Caption, Lang, AForm.Font.Size,
         AForm.ClientWidth, AForm.ClientHeight, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]))
    else
    begin
      Lines.Add(Format('[%d] %s ''%s'' | %s | %d pt | %dx%d | %s',
        [Issues.Count, AForm.ClassName, AForm.Caption, Lang, AForm.Font.Size,
         AForm.ClientWidth, AForm.ClientHeight, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
      for I := 0 to Issues.Count - 1 do
        Lines.Add('    ' + Issues[I]);
    end;
    for I := 0 to Infos.Count - 1 do
      Lines.Add('    ' + Infos[I]);
    WriteLog(Lines);
  finally
    Lines.Free;
    Infos.Free;
    Issues.Free;
  end;
end;

initialization

finalization
  gChecked.Free;
  gMeasure.Free;

end.
