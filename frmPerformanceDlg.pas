unit frmPerformanceDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uPrefs, uI18n, uTitleBar, uMediaFoundation, uVideoWriter;

type
  TPerformanceDlg = class(TFotoForm)
    rgMaxResolution: TRadioGroup;
    rgUndoLimit: TRadioGroup;
    chkUseGPU: TCheckBox;
    lblGPUInfo: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure chkUseGPUClick(Sender: TObject);
  private
    FHasHWEncoder: Boolean;
    FAdapters: TArray<string>;    // [0] = karta wskazywana koderowi
    function GetMaxResolution: string;
    function GPUInfoText(WithInUse: Boolean): string;
  public
    procedure RefitButtons; override;
  end;

function ShowPerformanceDlg: Boolean;

implementation

{$R *.dfm}

const
  // pozycje rgUndoLimit -> Prefs.UndoLimit (0 = bez limitu)
  cUndoLimits: array[0..3] of Integer = (20, 50, 100, 0);

// Opis pod polem karty: karty z listy Windows (nazwy od sterownika, bez
// tlumaczenia), pierwsza = ta, ktora zapis wideo wskazuje koderowi; dopisek
// „(uzywana)” tylko przy wlaczonym polu. Bez sprzetowego kodera H.264 -
// komunikat, ze koduje procesor.
function TPerformanceDlg.GPUInfoText(WithInUse: Boolean): string;
var
  I: Integer;
begin
  if not FHasHWEncoder then
    Exit(T('No hardware video encoder (video encoded by the processor)'));
  if Length(FAdapters) = 0 then Exit('');
  Result := T('Graphics card:') + ' ' + FAdapters[0];
  if WithInUse then
    Result := Result + ' (' + T('in use') + ')';
  for I := 1 to High(FAdapters) do
    Result := Result + sLineBreak + FAdapters[I];
end;

procedure TPerformanceDlg.chkUseGPUClick(Sender: TObject);
begin
  lblGPUInfo.Caption := GPUInfoText(chkUseGPU.Checked);
end;

procedure TPerformanceDlg.FormCreate(Sender: TObject);
var
  Chosen: Integer;
begin
  FHasHWEncoder := Length(HardwareH264EncoderNames) > 0;
  FAdapters := GraphicsAdapterNames(Chosen);
  lblGPUInfo.Caption := GPUInfoText(True);
  // osobny napis: "Original" (361) jest wspoldzielony z Mieszaniem, Kafelkowaniem i Timelapse
  rgMaxResolution.Items.Add(T('Original (no downscaling)'));
  rgMaxResolution.Items.Add(T('4K (3840×2160)'));
  rgMaxResolution.Items.Add(T('Full HD (1920×1080)'));
  rgMaxResolution.Items.Add(T('SVGA (800×600)'));
  // kolejnosc = cUndoLimits
  rgUndoLimit.Items.Add('20');
  rgUndoLimit.Items.Add('50');
  rgUndoLimit.Items.Add('100');
  rgUndoLimit.Items.Add(T('Unlimited'));
end;

function ShowPerformanceDlg: Boolean;
var
  Dlg: TPerformanceDlg;
  I: Integer;
begin
  Result := False;
  Dlg := TPerformanceDlg.Create(Application);
  try
    if Prefs.MaxResolution = '4k' then
      Dlg.rgMaxResolution.ItemIndex := 1
    else if Prefs.MaxResolution = 'fhd' then
      Dlg.rgMaxResolution.ItemIndex := 2
    else if Prefs.MaxResolution = 'svga' then
      Dlg.rgMaxResolution.ItemIndex := 3
    else
      Dlg.rgMaxResolution.ItemIndex := 0;
    Dlg.rgUndoLimit.ItemIndex := High(cUndoLimits);
    for I := 0 to High(cUndoLimits) do
      if cUndoLimits[I] = Prefs.UndoLimit then
        Dlg.rgUndoLimit.ItemIndex := I;
    Dlg.chkUseGPU.Checked := Prefs.UseGPU;
    Dlg.lblGPUInfo.Caption := Dlg.GPUInfoText(Prefs.UseGPU);
    if Dlg.ShowModal = mrOk then
    begin
      Prefs.MaxResolution := Dlg.GetMaxResolution;
      if Dlg.rgUndoLimit.ItemIndex >= 0 then
        Prefs.UndoLimit := cUndoLimits[Dlg.rgUndoLimit.ItemIndex];
      Prefs.UseGPU := Dlg.chkUseGPU.Checked;
      SavePrefs;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TPerformanceDlg }

function TPerformanceDlg.GetMaxResolution: string;
begin
  case rgMaxResolution.ItemIndex of
    1: Result := '4k';
    2: Result := 'fhd';
    3: Result := 'svga';
  else
    Result := 'original';
  end;
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 380x210, ramka 356x115 i
// pole wyboru o wysokosci 17 px - przy 12 pt tekst ~21 px, ciasno/ucinane).
// TRadioGroup.ArrangeButtons (Vcl.ExtCtrls.pas:6388-6393, TopMarginButtons = 0):
// wysokosc pozycji = (Height - tmHeight - 5) div liczba, szerokosc = Width - 10
// - stad wymiary ramki liczone odwrotnie. Odstepy z czcionki.
procedure TPerformanceDlg.RefitButtons;
var
  I, W, TH, ItemH, Check, Margin, FrameW: Integer;
  Lines: TArray<string>;
begin
  inherited;
  Margin := CtrlGap * 3;
  TH := Canvas.TextHeight('Wg');
  ItemH := TH + RowGap * 2;
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;

  // szerokosc ramek (obie rowne): najdluzsza pozycja albo tytul ramki
  W := 0;
  for I := 0 to rgMaxResolution.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(rgMaxResolution.Items[I]) + Check);
  W := Max(W, Canvas.TextWidth(rgMaxResolution.Caption) + CtrlGap * 4);
  for I := 0 to rgUndoLimit.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(rgUndoLimit.Items[I]) + Check);
  W := Max(W, Canvas.TextWidth(rgUndoLimit.Caption) + CtrlGap * 4);
  FrameW := W + 10 + CtrlGap * 2;
  // ramki co najmniej do prawego brzegu pola karty graficznej i opisu pod nim
  // (pole i opis wciete o Margin wzgledem ramek, opis dodatkowo o Check)
  FrameW := Max(FrameW, Margin + Canvas.TextWidth(chkUseGPU.Caption) + Check);
  // szerokosc z wersji z dopiskiem „(uzywana)”, zeby wlaczenie pola nie
  // poszerzalo okna
  Lines := GPUInfoText(True).Split([sLineBreak]);
  for I := 0 to High(Lines) do
    FrameW := Max(FrameW, Margin + Check + Canvas.TextWidth(Lines[I]));
  rgMaxResolution.SetBounds(Margin, Margin, FrameW,
    TH + 5 + Max(1, rgMaxResolution.Items.Count) * ItemH);

  // pole "Plynne skalowanie podgladu" przeniesione do menu Widok (2026-10-25)
  rgUndoLimit.SetBounds(Margin, rgMaxResolution.Top + rgMaxResolution.Height + SectionGap,
    rgMaxResolution.Width, TH + 5 + Max(1, rgUndoLimit.Items.Count) * ItemH);

  // jak dawne pole Plynnego skalowania: wciete o Margin, wysokosc z czcionki
  chkUseGPU.SetBounds(rgUndoLimit.Left + Margin,
    rgUndoLimit.Top + rgUndoLimit.Height + RowGap * 2,
    Canvas.TextWidth(chkUseGPU.Caption) + Check, TH + 4);

  lblGPUInfo.Left := chkUseGPU.Left + Check;
  lblGPUInfo.Top := chkUseGPU.Top + chkUseGPU.Height + RowGap;

  btnOK.Top := lblGPUInfo.Top + lblGPUInfo.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  // przyciski od lewej przed pomiarem - inaczej FitToContent liczy ich
  // pozycje z .dfm (Anuluj Left = 284) i okno wychodzi szersze od ramek
  btnOK.Left := Margin;
  btnCancel.Left := btnOK.Left + btnOK.Width + CtrlGap * 2;
  FitToContent(SectionGap, Margin);
  // okno co najmniej na pare przyciskow
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

end.
