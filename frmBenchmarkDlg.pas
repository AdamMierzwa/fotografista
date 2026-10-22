unit frmBenchmarkDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  uRiso, uAmiga, uI18n,
  frmLevelsDlg, frmHDR1Dlg, frmKolorowanieDlg, frmCrossProcessDlg,
  frmReliefDlg, frmHalftoneDlg, frmScreenPrintDlg, frmEmergoDlg, uTitleBar;

type
  // Wskaźnik na efekt liczący (Orton jest prywatną metodą fMain, więc przekazujemy go z zewnątrz)
  TBmEffectProc = reference to procedure(Bitmap: TBitmap);

  TBmResult = record
    Name: string;
    Ms: Double;   // wyświetlany czas: średnia dla efektów 3x, pojedynczy pomiar dla 1x
    Avg: Boolean; // czy pokazać "(sr. z 3)"
  end;

  TBmIntroForm = class(TFotoForm)
    lblInfo: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefitButtons; override;
  end;

  TBmProgressForm = class(TFotoForm)
    lb: TListBox;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RefitButtons; override;
  end;

  TBmReportForm = class(TFotoForm)
    memo: TMemo;
    btnOK: TButton;
  private
    FLines: TArray<string>;   // wiersze raportu do pomiaru bez uchwytu pola
  public
    constructor Create(AOwner: TComponent; const AReport: string); reintroduce;
    procedure AfterConstruction; override;
    procedure RefitButtons; override;
  end;

// Przeprowadza benchmark na podanym obrazie (oryginał nie jest modyfikowany).
// AOwner (opcjonalnie) to okno wyłączane na czas pomiaru, by uniknąć reentrancji.
// Zwraca True, gdy test został wykonany do końca (użytkownik nie anulował).
function RunBenchmark(Src: TBitmap; OrtonProc: TBmEffectProc; AOwner: TForm = nil): Boolean;

implementation

const
  BMCount = 12;

  BMNames: array[0..BMCount - 1] of string = (
    'Levels', 'Vividness', 'Colorize', 'Cross process',
    'Bas-relief', 'Orton',
    'Halftone', 'Screen print', 'Risograph v2',
    'HAM8 (64 colors)', 'HAM6 (16 colors)',
    'Emergo');

  BMRepeats: array[0..BMCount - 1] of Integer = (
    3, 3, 3, 3,
    1, 3,
    3, 3, 1,
    1, 1,
    3);

// Grupowanie (puste linie w raporcie) — dokładnie jak w przykładowym raporcie.
function GroupStart(I: Integer): Boolean;
begin
  Result := (I = 4) or (I = 6) or (I = 9) or (I = 11);
end;

// Domyślne parametry z dialogów (bez otwierania okien).
procedure ApplyBenchmarkEffect(I: Integer; Bitmap: TBitmap; OrtonProc: TBmEffectProc);
begin
  case I of
    0:  DoLevels(Bitmap, 0, 255, 100);
    1:  DoHDR1(Bitmap, 60, 50, 40, 2);
    2:  DoTint(Bitmap, RGB(255, 0, 0), 50);
    3:  DoCrossProcess(Bitmap, 0);
    4:  DoRelief(Bitmap, 35, 0);
    5:  OrtonProc(Bitmap);
    6:  DoHalftone(Bitmap, 8);
    7:  DoScreenPrint(Bitmap, RGB(0, 0, 0), RGB(255, 248, 240), 0);
    8:  DoRisoV2(Bitmap, GetRisoPalette(0), 1);
    9:  ApplyHAM(Bitmap, 6);
    10: ApplyHAM(Bitmap, 4);
    11: DoEmergo(Bitmap, 0);
  end;
end;

// Liczby raportu z ustawien regionalnych Windows (globalne FormatSettings,
// czytane przy starcie programu): po polsku 1 253,54. Wczesniej na sztywno
// kropka dziesietna, a wyniki usredniane szly przez Format z ustawien systemu
// - raport mieszal przecinek i kropke (2026-10-21).
function FormatMs(Ms: Double): string;
begin
  Result := FormatFloat('#,##0.00', Ms, FormatSettings);
end;

function FormatTotal(TotalMs: Double): string;
var
  H, M, S: Integer;
  TotalSec: Double;
begin
  if TotalMs < 1000.0 then
  begin
    Result := Format('%.0f ms', [TotalMs]);
    Exit;
  end;
  TotalSec := TotalMs / 1000.0;
  H := Trunc(TotalSec / 3600);
  M := Trunc((TotalSec - H * 3600) / 60);
  S := Round(TotalSec - H * 3600 - M * 60);
  if S = 60 then begin Inc(M); S := 0; end;
  if M = 60 then begin Inc(H); M := 0; end;
  if H > 0 then
    Result := Format('%d h %d min %d s', [H, M, S])
  else
    Result := Format('%d min %d s', [M, S]);
end;

function BuildReport(Src: TBitmap; const Results: array of TBmResult; TotalMs: Double): string;
var
  Lines: TStringList;
  S: string;
  Longest: Integer;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    Longest := -1;
    Lines.Add(Format(T('Image: current image (%d x %d)'), [Src.Width, Src.Height]));
    Lines.Add('');
    for I := 0 to High(Results) do
    begin
      if GroupStart(I) then Lines.Add('');
      if Results[I].Avg then
        S := '  ' + Format(T('%s: %.2n ms (avg of %d)'), [Results[I].Name, Results[I].Ms, 3], FormatSettings)
      else
        S := '  ' + Results[I].Name + ': ' + FormatMs(Results[I].Ms) + ' ms';
      Lines.Add(S);
      if (Longest < 0) or (Results[I].Ms > Results[Longest].Ms) then
        Longest := I;
    end;
    Lines.Add('');
    Lines.Add(Format(T('  Test time: %s'), [FormatTotal(TotalMs)]));
    Lines.Add('');
    Lines.Add(Format(T('  The heaviest challenge was: %s'),
      [Results[Longest].Name + ' (' + FormatMs(Results[Longest].Ms) + ' ms).']));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function RunBenchmark(Src: TBitmap; OrtonProc: TBmEffectProc; AOwner: TForm): Boolean;
var
  Intro: TBmIntroForm;
  Progress: TBmProgressForm;
  Report: TBmReportForm;
  Results: array[0..BMCount - 1] of TBmResult;
  I, R: Integer;
  RunMs, DisplayMs, TotalMs: Double;
  CopyBmp: TBitmap;
  SW: TStopwatch;
begin
  Result := False;
  if (Src = nil) or (Src.Width = 0) or (Src.Height = 0) then Exit;

  Intro := TBmIntroForm.Create(nil);
  try
    if Intro.ShowModal <> mrOk then Exit;
  finally
    Intro.Free;
  end;

  if AOwner <> nil then AOwner.Enabled := False;
  try
    Progress := TBmProgressForm.Create(nil);
    try
      Progress.Show;
      Application.ProcessMessages;

      TotalMs := 0;
      for I := 0 to BMCount - 1 do
      begin
        Progress.lb.Items.Add(T(BMNames[I]));
        Progress.lb.ItemIndex := Progress.lb.Items.Count - 1;
        Progress.lb.Update;
        Application.ProcessMessages;

        RunMs := 0;
        for R := 1 to BMRepeats[I] do
        begin
          CopyBmp := TBitmap.Create;
          try
            CopyBmp.Assign(Src);
            SW := TStopwatch.StartNew;
            ApplyBenchmarkEffect(I, CopyBmp, OrtonProc);
            SW.Stop;
            RunMs := RunMs + SW.Elapsed.TotalMilliseconds;
          finally
            CopyBmp.Free;
          end;
        end;

        if BMRepeats[I] = 3 then
          DisplayMs := RunMs / 3
        else
          DisplayMs := RunMs;

        Results[I].Name := T(BMNames[I]);
        Results[I].Ms := DisplayMs;
        Results[I].Avg := BMRepeats[I] = 3;
        TotalMs := TotalMs + RunMs;
      end;
    finally
      Progress.Free;
    end;
  finally
    if AOwner <> nil then AOwner.Enabled := True;
  end;

  Report := TBmReportForm.Create(nil, BuildReport(Src, Results, TotalMs));
  try
    Report.ShowModal;
  finally
    Report.Free;
  end;

  Result := True;
end;

{ TBmIntroForm }

// Okna testu wydajnosci: uklad z tresci (2026-10-21; wczesniej sztywne
// 430x165 / 240x230 / 540x450, przyciski po 85 px, raport na stale 9 pt).
// Czcionke programu forma dostaje w TFotoForm.AfterConstruction, czyli PO
// konstruktorze - dlatego konstruktory tylko tworza kontrolki, a wymiary
// liczy RefitButtons (pokazanie okna, zmiana czcionki).

constructor TBmIntroForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance test');
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.AutoSize := False;
  lblInfo.WordWrap := True;
  lblInfo.Caption := T('The benchmark will test the speed of 12 graphics operations.')
    + sLineBreak + sLineBreak
    + T('Duration: from about a dozen seconds to several minutes, depending on image resolution and processor speed.');

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Caption := T('Continue');
  btnOK.ModalResult := mrOk;
  btnOK.Default := True;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Caption := T('Cancel');
  btnCancel.ModalResult := mrCancel;
  btnCancel.Cancel := True;
end;

// Opis zawijany w szerokosci ok. 50 znakow (wysokosc z tekstu), przyciski do
// prawej.
procedure TBmIntroForm.RefitButtons;
var
  Margin: Integer;
begin
  inherited;
  Margin := SectionGap;
  // AutoSize wylaczany i wlaczany ponownie, zeby wysokosc zawinietego opisu
  // przeliczyla sie dla nowej szerokosci
  lblInfo.AutoSize := False;
  lblInfo.SetBounds(Margin, Margin, Canvas.TextWidth('0') * 50, Canvas.TextHeight('Wg'));
  lblInfo.AutoSize := True;
  FitButtonGroup([btnOK, btnCancel]);
  btnOK.Top := lblInfo.Top + lblInfo.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  FitToContent(Margin, Margin);
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

{ TBmProgressForm }

constructor TBmProgressForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance test');
  BorderStyle := bsDialog;
  BorderIcons := [];
  Position := poScreenCenter;

  lb := TListBox.Create(Self);
  lb.Parent := Self;
end;

// Lista na wszystkie operacje bez przewijania: szerokosc z najdluzszej nazwy
// (wszystkie znane przed startem - okno nie zmienia rozmiaru w trakcie),
// wysokosc BMCount wierszy.
procedure TBmProgressForm.RefitButtons;
var
  Margin, W, IH, I: Integer;
begin
  inherited;
  Margin := RowGap * 2;
  W := 0;
  for I := 0 to BMCount - 1 do
    W := Max(W, Canvas.TextWidth(T(BMNames[I])));
  // rzeczywista wysokosc pozycji listy: dla lbStandard z uchwytem ItemHeight
  // zwraca wysokosc z GetItemRect (Vcl.StdCtrls.pas:7595-7604)
  if lb.HandleAllocated and (lb.Items.Count > 0) then
    IH := lb.ItemHeight
  else
    IH := Canvas.TextHeight('Wg');
  lb.Left := Margin;
  lb.Top := Margin;
  lb.ClientWidth := W + CtrlGap * 4;
  lb.ClientHeight := BMCount * IH;
  FitToContent(Margin, Margin);
end;

{ TBmReportForm }

// Raport podawany w konstruktorze: pole dostaje tekst przed utworzeniem okna
// (WM_SETTEXT bez uchwytu zapamietuje tekst, CreateWindowHandle wpisuje go przy
// tworzeniu - Vcl.Controls.pas:10367, Vcl.StdCtrls.pas:3846-3853), a wymiary
// liczone sa z FLines, bez siegania do memo.Lines (ono tworzy uchwyt). Wczesniej
// memo.Lines.Text tworzylo okno pola w domyslnym rozmiarze 185x89
// (Vcl.StdCtrls.pas:3794-3795) i styl VCL ustawial tam poziomy pasek
// przewijania (Vcl.Forms.pas:15758-15774); po powiekszeniu pola zostawal jego
// nieprzemalowany slad - bialy pasek do pierwszego klikniecia.
constructor TBmReportForm.Create(AOwner: TComponent; const AReport: string);
var
  L: TStringList;
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance results');
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;

  memo := TMemo.Create(Self);
  memo.Parent := Self;
  memo.ReadOnly := True;
  memo.ScrollBars := ssBoth;
  memo.WordWrap := False;
  memo.Font.Name := 'Courier New';   // raport w kolumnach - stala szerokosc znakow
  memo.Text := AReport;
  L := TStringList.Create;
  try
    L.Text := AReport;
    FLines := L.ToStringArray;
  finally
    L.Free;
  end;

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Caption := T('Close');
  btnOK.ModalResult := mrOk;
  btnOK.Default := True;
end;

// Raport: Courier New w rozmiarze czcionki programu; pole w rozmiarze tresci
// (najdluzszy wiersz x liczba wierszy), limit 80% ekranu - dalej paski
// przewijania; Zamknij do prawej.
// Uklad liczony od razu po konstrukcji (czcionke programu forma ma juz z
// TFotoForm.AfterConstruction): okna kontrolek powstaja w UpdateShowing PRZED
// CM_SHOWINGCHANGED, czyli przed DoShow (Vcl.Controls.pas, UpdateShowing) -
// samo RefitButtons z DoShow ustawialo rozmiar pola dopiero po utworzeniu
// jego okna w rozmiarze domyslnym.
procedure TBmReportForm.AfterConstruction;
begin
  inherited;
  RefitButtons;
end;

procedure TBmReportForm.RefitButtons;
var
  Margin, I, LineW, LineH, MaxW, MaxH: Integer;
begin
  inherited;
  Margin := SectionGap;
  memo.Font.Size := Font.Size;
  Canvas.Font.Assign(memo.Font);
  LineW := 0;
  for I := 0 to High(FLines) do
    LineW := Max(LineW, Canvas.TextWidth(FLines[I]));
  LineH := Canvas.TextHeight('Wg');
  Canvas.Font.Assign(Font);
  FitButton(btnOK);

  MaxW := Screen.WorkAreaWidth * 8 div 10 - Margin * 2;
  MaxH := Screen.WorkAreaHeight * 8 div 10 - Margin * 3 - btnOK.Height;
  memo.Left := Margin;
  memo.Top := Margin;
  // zapas na wewnetrzne marginesy pola i paski przewijania
  memo.Width := Min(MaxW, LineW + GetSystemMetrics(SM_CXVSCROLL) + CtrlGap * 4);
  memo.Height := Min(MaxH, Max(1, Length(FLines)) * LineH + GetSystemMetrics(SM_CYHSCROLL) + CtrlGap * 4);

  btnOK.Top := memo.Top + memo.Height + SectionGap;
  FitToContent(Margin, Margin);
  btnOK.Left := ClientWidth - Margin - btnOK.Width;
end;

end.
