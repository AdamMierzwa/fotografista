unit uParamCheck;

// Kontrola parametrow - tylko build Debug (2026-11-08, ZADANIA.md: procedura
// testu "zmiana kazdego parametru", czesc 1). Wolana z przejscia po oknach
// w fMain (Pomoc -> Kontrola parametrow): w aktywnym oknie z podgladem zmienia
// po kolei kazda kontrolke i sprawdza, czy zmienil sie podglad (piksele pol
// TPaintBox odczytane z ekranu). Wynik w kontrola_parametrow.txt obok EXE.
//
// Kontrolki:
//   TTrackBar     - minimum i maksimum, porownanie obu podgladow
//   TCheckBox     - przelaczenie i z powrotem
//   TRadioGroup   - kazda pozycja wzgledem pozycji startowej
//   TRadioButton  - kazdy niezaznaczony wzgledem zaznaczonego
//   TComboBox     - nastepna pozycja wzgledem startowej
// Pomijane: wylaczone/niewidoczne, przyciski (okna systemowe), pola tekstowe.
// Gdy podglad sie nie zmienil - druga proba z pozostalymi suwakami na 3/4
// zakresu (np. Emergo: przy Intensywnosci 0 Rozjasnienie slusznie nic nie
// zmienia; nie srodek - w zakresie symetrycznym to 0, np. Kat Wiru).
// Po kazdej kontrolce stan startowy jest przywracany. "NIE ZMIENIA" to sygnal
// do obejrzenia okna, nie wyrok.

interface

uses
  Vcl.Forms;

procedure ParamCheckStart;
procedure CheckFormParams(AForm: TCustomForm);
function ParamCheckSummary: string;

implementation

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  System.Hash, System.TypInfo, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Graphics, Vcl.Menus, uI18n;

const
  cLogName = 'kontrola_parametrow.txt';
  cStableMs = 500;    // podglad bez zmian tak dlugo = gotowy (debounce w oknach do 400 ms)
  cTimeoutMs = 5000;  // dluzej - zapis "przekroczony czas"
  // okna bez podgladu obrazu albo ze zmianami na zywo w calym programie
  cSkipClasses: array[0..6] of string = ('TInterfaceDlg', 'TLanguageDlg',
    'TQualityDlg', 'TPerformanceDlg', 'TBatchDlg', 'TTimelapseDlg', 'TfrmFileInfo');

type
  TAct = reference to procedure;
  TComboAccess = class(TCustomComboBox);

var
  gForms, gSkipped, gControls, gNoChange, gTimeouts: Integer;
  gLines: TStringList = nil;   // wpisy biezacego okna
  gPBs: TList = nil;           // pola podgladu biezacego okna
  gCtls: TList = nil;          // kontrolki biezacego okna

function LogPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + cLogName;
end;

procedure AppendLog(Lines: TStrings);
var
  Log: TStringList;
begin
  Log := TStringList.Create;
  try
    if FileExists(LogPath) then
      Log.LoadFromFile(LogPath, TEncoding.UTF8);
    Log.AddStrings(Lines);
    Log.SaveToFile(LogPath, TEncoding.UTF8);
  finally
    Log.Free;
  end;
end;

procedure ParamCheckStart;
var
  L: TStringList;
begin
  gForms := 0;
  gSkipped := 0;
  gControls := 0;
  gNoChange := 0;
  gTimeouts := 0;
  L := TStringList.Create;
  try
    L.Add('');
    L.Add(Format('=== Kontrola parametrow | %s | %s | %d pt ===',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
       GetEnumName(TypeInfo(TLanguage), Ord(CurrentLanguage)),
       Application.DefaultFont.Size]));
    AppendLog(L);
  finally
    L.Free;
  end;
end;

function ParamCheckSummary: string;
begin
  Result := Format('Kontrola parametrów: okna sprawdzone %d, pominięte %d; ' +
    'kontrolki %d, NIE ZMIENIA %d, przekroczony czas %d.'#13#10'Log: %s',
    [gForms, gSkipped, gControls, gNoChange, gTimeouts, LogPath]);
end;

// widoczna i wlaczona razem z cala linia rodzicow
function IsLive(C: TControl): Boolean;
begin
  Result := True;
  while C <> nil do
  begin
    if not C.Visible or not C.Enabled then
      Exit(False);
    C := C.Parent;
  end;
end;

function CtlText(C: TControl): string;
begin
  Result := C.Name;
  if IsPublishedProp(C, 'Caption') then
    Result := Trim(Result + ' ''' + StripHotkey(GetStrProp(C, 'Caption')) + '''');
end;

procedure CollectPaintBoxes(W: TWinControl);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to W.ControlCount - 1 do
  begin
    C := W.Controls[I];
    if (C is TPaintBox) and C.Visible and (C.Width > 0) and (C.Height > 0) then
      gPBs.Add(C)
    else if C is TWinControl then
      CollectPaintBoxes(TWinControl(C));
  end;
end;

procedure CollectControls(W: TWinControl);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to W.ControlCount - 1 do
  begin
    C := W.Controls[I];
    if (C is TTrackBar) or (C is TCheckBox) or (C is TComboBox) or
       (C is TCustomRadioGroup) then
      gCtls.Add(C)
    else if (C is TRadioButton) and not (C.Parent is TCustomRadioGroup) then
      gCtls.Add(C)
    else if C is TWinControl then
      CollectControls(TWinControl(C));
  end;
end;

// piksele wszystkich pol podgladu z ekranu -> skrot
function Snapshot: string;
var
  I, Y: Integer;
  PB: TPaintBox;
  Pt: TPoint;
  Bmp: TBitmap;
  DC: HDC;
  H: THashMD5;
begin
  Result := '';
  DC := GetDC(0);
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf32bit;
    for I := 0 to gPBs.Count - 1 do
    begin
      PB := TPaintBox(gPBs[I]);
      Pt := PB.ClientToScreen(Point(0, 0));
      Bmp.SetSize(PB.Width, PB.Height);
      BitBlt(Bmp.Canvas.Handle, 0, 0, PB.Width, PB.Height, DC, Pt.X, Pt.Y, SRCCOPY);
      H := THashMD5.Create;
      for Y := 0 to Bmp.Height - 1 do
        H.Update(Bmp.ScanLine[Y]^, Bmp.Width * 4);
      Result := Result + H.HashAsString;
    end;
  finally
    Bmp.Free;
    ReleaseDC(0, DC);
  end;
end;

// czeka, az podglad przestanie sie zmieniac (watki/timery podgladu w oknach)
function WaitStable: string;
var
  T0, TS: Cardinal;
  Prev: string;
begin
  T0 := GetTickCount;
  TS := T0;
  Prev := #0;
  repeat
    Application.ProcessMessages;
    Sleep(40);
    Result := Snapshot;
    if Result <> Prev then
    begin
      Prev := Result;
      TS := GetTickCount;
    end
    else if GetTickCount - TS >= cStableMs then
      Exit;
  until GetTickCount - T0 > cTimeoutMs;
  Inc(gTimeouts);
end;

procedure ClickCtl(C: TWinControl);
begin
  // jak klikniecie uzytkownika: BN_CLICKED -> OnClick
  SendMessage(C.Handle, BM_CLICK, 0, 0);
end;

function TwoStates(S1, S2: TAct): Boolean;
var
  A: string;
begin
  S1();
  A := WaitStable;
  S2();
  Result := A <> WaitStable;
end;

procedure TestOne(C: TControl; const What: string; S1, S2, Revert: TAct);
var
  Saved: array of Integer;
  I: Integer;
  Changed: Boolean;
  Note: string;
  TB: TTrackBar;
begin
  Changed := TwoStates(S1, S2);
  Revert();
  Note := '';
  if not Changed then
  begin
    // druga proba: pozostale suwaki na 3/4 zakresu
    SetLength(Saved, gCtls.Count);
    for I := 0 to gCtls.Count - 1 do
    begin
      Saved[I] := MaxInt;
      if (TControl(gCtls[I]) <> C) and (TControl(gCtls[I]) is TTrackBar) and
         IsLive(TControl(gCtls[I])) then
      begin
        TB := TTrackBar(gCtls[I]);
        Saved[I] := TB.Position;
        TB.Position := TB.Min + (TB.Max - TB.Min) * 3 div 4;
      end;
    end;
    Changed := TwoStates(S1, S2);
    Revert();
    for I := 0 to gCtls.Count - 1 do
      if Saved[I] <> MaxInt then
        TTrackBar(gCtls[I]).Position := Saved[I];
    if Changed then
      Note := '  (dopiero przy pozostałych suwakach na 3/4 zakresu)';
  end;
  Inc(gControls);
  if Changed then
    gLines.Add('    zmienia      ' + What + Note)
  else
  begin
    Inc(gNoChange);
    gLines.Add('    NIE ZMIENIA  ' + What);
  end;
end;

procedure TestTrack(TB: TTrackBar);
var
  Orig: Integer;
begin
  if TB.Max <= TB.Min then Exit;
  Orig := TB.Position;
  TestOne(TB, CtlText(TB) + Format(' (%d..%d)', [TB.Min, TB.Max]),
    procedure begin TB.Position := TB.Min; end,
    procedure begin TB.Position := TB.Max; end,
    procedure begin TB.Position := Orig; end);
end;

procedure TestCheck(CB: TCheckBox);
begin
  TestOne(CB, CtlText(CB),
    procedure begin end,
    procedure begin ClickCtl(CB); end,
    procedure begin ClickCtl(CB); end);
end;

procedure TestCombo(Cb: TComboBox);
var
  Orig, N: Integer;
begin
  if Cb.Items.Count < 2 then Exit;
  Orig := Cb.ItemIndex;
  N := (Max(Orig, 0) + 1) mod Cb.Items.Count;
  TestOne(Cb, CtlText(Cb) + ' -> ''' + Cb.Items[N] + '''',
    procedure begin end,
    procedure begin Cb.ItemIndex := N; TComboAccess(Cb).Change; end,
    procedure begin Cb.ItemIndex := Orig; TComboAccess(Cb).Change; end);
end;

procedure TestGroupItem(G: TCustomRadioGroup; J, Orig: Integer);
var
  Base, Item: TRadioButton;
begin
  Item := TRadioGroup(G).Buttons[J];
  if Orig >= 0 then
    Base := TRadioGroup(G).Buttons[Orig]
  else
    Base := nil;
  TestOne(G, CtlText(G) + ' -> ''' + StripHotkey(Item.Caption) + '''',
    procedure begin if Base <> nil then ClickCtl(Base); end,
    procedure begin ClickCtl(Item); end,
    procedure begin if Base <> nil then ClickCtl(Base); end);
end;

procedure TestGroup(G: TCustomRadioGroup);
var
  J, Orig: Integer;
begin
  Orig := TRadioGroup(G).ItemIndex;
  for J := 0 to TRadioGroup(G).Items.Count - 1 do
    if (J <> Orig) and IsLive(TRadioGroup(G).Buttons[J]) then
      TestGroupItem(G, J, Orig);
end;

procedure TestRadio(R: TRadioButton);
var
  I: Integer;
  Base: TRadioButton;
begin
  if R.Checked then Exit;   // zaznaczony = stan odniesienia dla pozostalych
  Base := nil;
  for I := 0 to R.Parent.ControlCount - 1 do
    if (R.Parent.Controls[I] is TRadioButton) and
       TRadioButton(R.Parent.Controls[I]).Checked then
      Base := TRadioButton(R.Parent.Controls[I]);
  TestOne(R, CtlText(R),
    procedure begin if Base <> nil then ClickCtl(Base); end,
    procedure begin ClickCtl(R); end,
    procedure begin if Base <> nil then ClickCtl(Base); end);
end;

procedure CheckFormParams(AForm: TCustomForm);
var
  I, HeaderIdx, NoChangeBefore, CtlsBefore: Integer;
  C: TControl;
  Head: string;
begin
  if (AForm = nil) or (AForm = Application.MainForm) or not AForm.Visible then Exit;
  Head := Format('%s ''%s''', [AForm.ClassName, AForm.Caption]);
  gLines := TStringList.Create;
  gPBs := TList.Create;
  gCtls := TList.Create;
  try
    for I := Low(cSkipClasses) to High(cSkipClasses) do
      if SameText(AForm.ClassName, cSkipClasses[I]) then
      begin
        Inc(gSkipped);
        gLines.Add('[POMINIĘTE] ' + Head + ' - okno bez podglądu obrazu');
        AppendLog(gLines);
        Exit;
      end;
    // wylaczony OK = okno bez tresci do pokazania (np. Znak wodny bez logo i
    // tekstu) - zadna kontrolka nie zmieni podgladu, wpisy bylyby falszywe
    if (AForm.FindComponent('btnOK') is TButton) and
       not TButton(AForm.FindComponent('btnOK')).Enabled then
    begin
      Inc(gSkipped);
      gLines.Add('[POMINIĘTE] ' + Head + ' - przycisk OK wyłączony, brak treści do podglądu');
      AppendLog(gLines);
      Exit;
    end;
    CollectPaintBoxes(AForm);
    if gPBs.Count = 0 then
    begin
      Inc(gSkipped);
      gLines.Add('[POMINIĘTE] ' + Head + ' - brak pola podglądu');
      AppendLog(gLines);
      Exit;
    end;

    Inc(gForms);
    NoChangeBefore := gNoChange;
    CtlsBefore := gControls;
    HeaderIdx := gLines.Add('');
    WaitStable;
    CollectControls(AForm);
    for I := 0 to gCtls.Count - 1 do
    begin
      C := TControl(gCtls[I]);
      if not IsLive(C) then Continue;
      if C is TTrackBar then TestTrack(TTrackBar(C))
      else if C is TCheckBox then TestCheck(TCheckBox(C))
      else if C is TComboBox then TestCombo(TComboBox(C))
      else if C is TCustomRadioGroup then TestGroup(TCustomRadioGroup(C))
      else if C is TRadioButton then TestRadio(TRadioButton(C));
    end;
    if gNoChange = NoChangeBefore then
      gLines[HeaderIdx] := Format('[OK] %s | kontrolki %d | %s',
        [Head, gControls - CtlsBefore, FormatDateTime('hh:nn:ss', Now)])
    else
      gLines[HeaderIdx] := Format('[%d NIE ZMIENIA] %s | kontrolki %d | %s',
        [gNoChange - NoChangeBefore, Head, gControls - CtlsBefore,
         FormatDateTime('hh:nn:ss', Now)]);
    AppendLog(gLines);
  finally
    FreeAndNil(gCtls);
    FreeAndNil(gPBs);
    FreeAndNil(gLines);
  end;
end;

end.
