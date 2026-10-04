unit frmInterfaceDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.ExtCtrls, Vcl.Themes, uTitleBar;

type
  TInterfacePreviewProc = procedure(AColor: TColor; AFontSize: Integer) of object;

  TInterfaceDlg = class(TFotoForm)
    lblCanvasBG: TLabel;
    btnCanvasBG: TButton;
    chkRememberWin: TCheckBox;
    lblFontSize: TLabel;
    spinFontSize: TSpinEdit;
    lblRecentCount: TLabel;
    spinRecentCount: TSpinEdit;
    lblTheme: TLabel;
    cmbTheme: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnCanvasBGClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure spinFontSizeChange(Sender: TObject);
  public
    procedure RefitButtons; override;
  private
    FCanvasBG: TColor;
    FTheme: string;
    FBaseFont: Integer;
    FOnPreview: TInterfacePreviewProc;
    procedure DoPreview;
  public
    property CanvasBG: TColor read FCanvasBG write FCanvasBG;
    property Theme: string read FTheme write FTheme;
    property OnPreview: TInterfacePreviewProc read FOnPreview write FOnPreview;
  end;

function ShowInterfaceDlg(var ACanvasBG: TColor;
  out ARememberWin: Boolean; out AFontSize, ARecentCount: Integer;
  var ATheme: string;
  AOnPreview: TInterfacePreviewProc = nil): Boolean;

implementation

{$R *.dfm}

uses
  Vcl.ColorGrd,
  uPrefs;

procedure TInterfaceDlg.FormCreate(Sender: TObject);
var
  S: string;
begin
  FCanvasBG := RGB(80, 80, 80);
  for S in TStyleManager.StyleNames do
    cmbTheme.Items.Add(S);
  cmbTheme.ItemIndex := 0;
end;

procedure TInterfaceDlg.RefitButtons;
begin
  inherited;
  FitButton(btnCanvasBG);
end;

procedure TInterfaceDlg.DoPreview;
begin
  if Assigned(FOnPreview) then
    FOnPreview(FCanvasBG, spinFontSize.Value - FBaseFont);
end;

procedure TInterfaceDlg.btnCanvasBGClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FCanvasBG;
    Dlg.Options := [cdFullOpen];
    if Dlg.Execute then
    begin
      FCanvasBG := Dlg.Color;
      DoPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TInterfaceDlg.spinFontSizeChange(Sender: TObject);
begin
  DoPreview;
end;

function ShowInterfaceDlg(var ACanvasBG: TColor;
  out ARememberWin: Boolean; out AFontSize, ARecentCount: Integer;
  var ATheme: string;
  AOnPreview: TInterfacePreviewProc): Boolean;
var
  Dlg: TInterfaceDlg;
  Idx: Integer;
begin
  Result := False;
  Dlg := TInterfaceDlg.Create(Application);
  try
    Dlg.FBaseFont := Application.DefaultFont.Size - Prefs.UIFontSize;
    Dlg.CanvasBG := ACanvasBG;
    Dlg.spinFontSize.MinValue := 8;
    Dlg.spinFontSize.MaxValue := 12;
    Dlg.spinFontSize.Value := Dlg.FBaseFont + AFontSize;
    Dlg.spinRecentCount.Value := ARecentCount;
    Dlg.chkRememberWin.Checked := ARememberWin;
    Dlg.Theme := ATheme;
    Idx := Dlg.cmbTheme.Items.IndexOf(Dlg.Theme);
    if Idx >= 0 then
      Dlg.cmbTheme.ItemIndex := Idx;
    Dlg.OnPreview := AOnPreview;
    if Dlg.ShowModal = mrOk then
    begin
      ACanvasBG := Dlg.CanvasBG;
      ARememberWin := Dlg.chkRememberWin.Checked;
      AFontSize := Dlg.spinFontSize.Value - Dlg.FBaseFont;
      ARecentCount := Dlg.spinRecentCount.Value;
      if Dlg.cmbTheme.ItemIndex >= 0 then
        ATheme := Dlg.cmbTheme.Items[Dlg.cmbTheme.ItemIndex];
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
