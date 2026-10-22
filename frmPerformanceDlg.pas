unit frmPerformanceDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uPrefs, uI18n, uTitleBar;

type
  TPerformanceDlg = class(TFotoForm)
    rgMaxResolution: TRadioGroup;
    chkSmoothPreview: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
  private
    function GetMaxResolution: string;
  public
    procedure RefitButtons; override;
  end;

function ShowPerformanceDlg: Boolean;

implementation

{$R *.dfm}

procedure TPerformanceDlg.FormCreate(Sender: TObject);
begin
  rgMaxResolution.Items.Add(T('Original'));
  rgMaxResolution.Items.Add(T('4K (3840×2160)'));
  rgMaxResolution.Items.Add(T('Full HD (1920×1080)'));
  rgMaxResolution.Items.Add(T('SVGA (800×600)'));
end;

function ShowPerformanceDlg: Boolean;
var
  Dlg: TPerformanceDlg;
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
    Dlg.chkSmoothPreview.Checked := Prefs.SmoothPreview;
    if Dlg.ShowModal = mrOk then
    begin
      Prefs.MaxResolution := Dlg.GetMaxResolution;
      Prefs.SmoothPreview := Dlg.chkSmoothPreview.Checked;
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
  I, W, TH, ItemH, Check, Margin: Integer;
begin
  inherited;
  Margin := CtrlGap * 3;
  TH := Canvas.TextHeight('Wg');
  ItemH := TH + RowGap * 2;
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;

  // szerokosc ramki: najdluzsza pozycja albo tytul ramki
  W := 0;
  for I := 0 to rgMaxResolution.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(rgMaxResolution.Items[I]) + Check);
  W := Max(W, Canvas.TextWidth(rgMaxResolution.Caption) + CtrlGap * 4);
  rgMaxResolution.SetBounds(Margin, Margin, W + 10 + CtrlGap * 2,
    TH + 5 + Max(1, rgMaxResolution.Items.Count) * ItemH);

  chkSmoothPreview.SetBounds(rgMaxResolution.Left + Margin,
    rgMaxResolution.Top + rgMaxResolution.Height + RowGap * 2,
    Canvas.TextWidth(chkSmoothPreview.Caption) + Check, TH + 4);

  btnOK.Top := chkSmoothPreview.Top + chkSmoothPreview.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  FitToContent(SectionGap, Margin);
  // okno co najmniej na pare przyciskow
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

end.
