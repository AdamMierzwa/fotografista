unit frmResizeCropDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uI18n, uTitleBar;

type
  TResizeCropDlg = class(TFotoForm)
    pnlTop: TPanel;
    pnlAnchor: TPanel;
    pnlBottom: TPanel;
    lblWidth: TLabel;
    edWidth: TEdit;
    lblHeight: TLabel;
    edHeight: TEdit;
    btnFullHD: TButton;
    lblAnchor: TLabel;
    rgCorner: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnFullHDClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;

var
  ResizeCropSourceBmp: TBitmap = nil;

function ShowResizeCropDlg(out NewW, NewH, Corner: Integer): Boolean;

implementation

{$R *.dfm}

procedure TResizeCropDlg.FormCreate(Sender: TObject);
var
  Bmp: TBitmap;
begin
  rgCorner.Items.Add(T('Top-left'));
  rgCorner.Items.Add(T('Bottom-left'));
  rgCorner.Items.Add(T('Top-right'));
  rgCorner.Items.Add(T('Bottom-right'));

  // Dopasuj szerokosc przycisku Full HD do captionu przy aktualnej czcionce,
  // by "Full HD 1920x1080" nie byl przycinany przy wiekszym foncie.
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font := btnFullHD.Font;
    btnFullHD.Width := Max(btnFullHD.Width, Bmp.Canvas.TextWidth(btnFullHD.Caption) + 20);
  finally
    Bmp.Free;
  end;
end;

function ShowResizeCropDlg(out NewW, NewH, Corner: Integer): Boolean;

  function VisualToCorner(Idx: Integer): Integer;
  const
    Map: array[0..3] of Integer = (0, 2, 1, 3);
  begin
    if (Idx >= Low(Map)) and (Idx <= High(Map)) then
      Result := Map[Idx]
    else
      Result := 0;
  end;

var
  Dlg: TResizeCropDlg;
begin
  Result := False;
  if ResizeCropSourceBmp = nil then Exit;
  Dlg := TResizeCropDlg.Create(Application);
  try
    Dlg.edWidth.Text := IntToStr(ResizeCropSourceBmp.Width);
    Dlg.edHeight.Text := IntToStr(ResizeCropSourceBmp.Height);
    Dlg.rgCorner.ItemIndex := 0;
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, ResizeCropSourceBmp.Width);
      NewH := StrToIntDef(Dlg.edHeight.Text, ResizeCropSourceBmp.Height);
      Corner := VisualToCorner(Dlg.rgCorner.ItemIndex);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TResizeCropDlg.btnFullHDClick(Sender: TObject);
begin
  edWidth.Text := '1920';
  edHeight.Text := '1080';
end;

end.
