unit frmResizeDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TResizeDlg = class(TFotoForm)
    pnlRadio: TPanel;
    pnlInput: TPanel;
    pnlBottom: TPanel;
    rbManual: TRadioButton;
    rbAutoPct: TRadioButton;
    lblMethod: TLabel;
    lblWidth: TLabel;
    lblHeight: TLabel;
    edWidth: TEdit;
    edHeight: TEdit;
    chkAspect: TCheckBox;
    lblPercent: TLabel;
    tbPercent: TTrackBar;
    lblPctValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure rbManualClick(Sender: TObject);
    procedure rbAutoPctClick(Sender: TObject);
    procedure edWidthChange(Sender: TObject);
    procedure edHeightChange(Sender: TObject);
    procedure tbPercentChange(Sender: TObject);
    procedure chkAspectClick(Sender: TObject);
  private
    FOrigW, FOrigH: Integer;
    FUpdating: Boolean;
    procedure SetMode(IsAuto: Boolean);
    procedure SyncFromPercent;
    procedure SyncAspectFromWidth;
    procedure SyncAspectFromHeight;
  public
    property OrigWidth: Integer read FOrigW write FOrigW;
    property OrigHeight: Integer read FOrigH write FOrigH;
  end;

var
  ResizeSourceBmp: TBitmap = nil;

function ShowResizeDlg(out NewW, NewH: Integer): Boolean;

implementation

{$R *.dfm}

function ShowResizeDlg(out NewW, NewH: Integer): Boolean;
var
  Dlg: TResizeDlg;
begin
  Result := False;
  if ResizeSourceBmp = nil then Exit;
  Dlg := TResizeDlg.Create(Application);
  try
    Dlg.FOrigW := ResizeSourceBmp.Width;
    Dlg.FOrigH := ResizeSourceBmp.Height;
    Dlg.edWidth.Text := IntToStr(Dlg.FOrigW);
    Dlg.edHeight.Text := IntToStr(Dlg.FOrigH);
    Dlg.chkAspect.Checked := True;
    Dlg.tbPercent.Position := 100;
    Dlg.lblPctValue.Caption := '100%';
    Dlg.rbManual.Checked := True;
    Dlg.SetMode(False);
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, Dlg.FOrigW);
      NewH := StrToIntDef(Dlg.edHeight.Text, Dlg.FOrigH);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TResizeDlg.SetMode(IsAuto: Boolean);
begin
  edWidth.Enabled := not IsAuto;
  edHeight.Enabled := not IsAuto;
  chkAspect.Enabled := not IsAuto;
  tbPercent.Enabled := IsAuto;
end;

procedure TResizeDlg.rbManualClick(Sender: TObject);
begin
  SetMode(False);
end;

procedure TResizeDlg.rbAutoPctClick(Sender: TObject);
begin
  SetMode(True);
  SyncFromPercent;
end;

procedure TResizeDlg.SyncFromPercent;
var
  Pct: Double;
begin
  Pct := tbPercent.Position / 100.0;
  edWidth.Text := IntToStr(Max(1, Round(FOrigW * Pct)));
  edHeight.Text := IntToStr(Max(1, Round(FOrigH * Pct)));
end;

procedure TResizeDlg.tbPercentChange(Sender: TObject);
begin
  if not tbPercent.Enabled then Exit;
  lblPctValue.Caption := IntToStr(tbPercent.Position) + '%';
  SyncFromPercent;
end;

procedure TResizeDlg.SyncAspectFromWidth;
var
  W, H: Integer;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    W := StrToIntDef(edWidth.Text, 0);
    if W > 0 then
    begin
      H := Max(1, Round(W * (FOrigH / FOrigW)));
      edHeight.Text := IntToStr(H);
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TResizeDlg.SyncAspectFromHeight;
var
  W, H: Integer;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    H := StrToIntDef(edHeight.Text, 0);
    if H > 0 then
    begin
      W := Max(1, Round(H * (FOrigW / FOrigH)));
      edWidth.Text := IntToStr(W);
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TResizeDlg.edWidthChange(Sender: TObject);
begin
  if edWidth.Enabled and chkAspect.Checked then
    SyncAspectFromWidth;
end;

procedure TResizeDlg.edHeightChange(Sender: TObject);
begin
  if edHeight.Enabled and chkAspect.Checked then
    SyncAspectFromHeight;
end;

procedure TResizeDlg.chkAspectClick(Sender: TObject);
begin
  if chkAspect.Checked then
    SyncAspectFromWidth;
end;

end.
