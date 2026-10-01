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
  end;

  TBmProgressForm = class(TFotoForm)
    lb: TListBox;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TBmReportForm = class(TFotoForm)
    memo: TMemo;
    btnOK: TButton;
  public
    constructor Create(AOwner: TComponent); override;
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

function FormatMs(Ms: Double): string;
var
  FmtS: TFormatSettings;
begin
  FmtS.DecimalSeparator := '.';
  FmtS.ThousandSeparator := ',';
  Result := FormatFloat('0.00', Ms, FmtS);
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
        S := '  ' + Format(T('%s: %.2f ms (avg of %d)'), [Results[I].Name, Results[I].Ms, 3])
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

  Report := TBmReportForm.Create(nil);
  try
    Report.memo.Lines.Text := BuildReport(Src, Results, TotalMs);
    Report.memo.SelStart := 0;
    Report.ShowModal;
  finally
    Report.Free;
  end;

  Result := True;
end;

{ TBmIntroForm }

constructor TBmIntroForm.Create(AOwner: TComponent);
const
  MARGIN = 20;
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance test');
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  ClientWidth := 430;
  ClientHeight := 165;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.AutoSize := False;
  lblInfo.WordWrap := True;
  lblInfo.Left := MARGIN;
  lblInfo.Top := MARGIN;
  lblInfo.Width := ClientWidth - 2 * MARGIN;
  lblInfo.Height := ClientHeight - 2 * MARGIN - 25 - 12;
  lblInfo.Caption := T('The benchmark will test the speed of 12 graphics operations.')
    + sLineBreak + sLineBreak
    + T('Duration: from about a dozen seconds to several minutes, depending on image resolution and processor speed.');

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Caption := T('Continue');
  btnOK.ModalResult := mrOk;
  btnOK.Default := True;
  btnOK.Width := 85;
  btnOK.Height := 25;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Caption := T('Cancel');
  btnCancel.ModalResult := mrCancel;
  btnCancel.Cancel := True;
  btnCancel.Width := 85;
  btnCancel.Height := 25;

  btnOK.Left := ClientWidth - MARGIN - 85 * 2 - 10;
  btnCancel.Left := ClientWidth - MARGIN - 85;
  btnOK.Top := ClientHeight - 25 - 12;
  btnCancel.Top := btnOK.Top;
end;

{ TBmProgressForm }

constructor TBmProgressForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance test');
  BorderStyle := bsDialog;
  BorderIcons := [];
  Position := poScreenCenter;
  ClientWidth := 240;
  ClientHeight := 230;

  lb := TListBox.Create(Self);
  lb.Parent := Self;
  lb.SetBounds(8, 8, ClientWidth - 16, ClientHeight - 16);
  lb.ItemHeight := 18;
end;

{ TBmReportForm }

constructor TBmReportForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := T('Performance results');
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  Position := poScreenCenter;
  ClientWidth := 540;
  ClientHeight := 450;

  memo := TMemo.Create(Self);
  memo.Parent := Self;
  memo.ReadOnly := True;
  memo.ScrollBars := ssBoth;
  memo.WordWrap := False;
  memo.Font.Name := 'Courier New';
  memo.Font.Size := 9;
  memo.SetBounds(8, 8, ClientWidth - 16, ClientHeight - 8 - 25 - 12 - 8);

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Caption := T('Close');
  btnOK.ModalResult := mrOk;
  btnOK.Default := True;
  btnOK.Width := 85;
  btnOK.Height := 25;
  btnOK.Left := ClientWidth - 8 - 85;
  btnOK.Top := ClientHeight - 25 - 12;
end;

end.
