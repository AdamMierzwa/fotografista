unit frmTileDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
   Vcl.StdCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TTileDlg = class(TFotoForm)
    pnlInput: TPanel;
    pnlBottom: TPanel;
    lblWidth: TLabel;
    edWidth: TEdit;
    lblHeight: TLabel;
    edHeight: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
  end;

var
  TileSourceBmp: TBitmap = nil;

function ShowTileDlg(out NewW, NewH: Integer): Boolean;

implementation

{$R *.dfm}

function ShowTileDlg(out NewW, NewH: Integer): Boolean;
var
  Dlg: TTileDlg;
begin
  Result := False;
  if TileSourceBmp = nil then Exit;
  Dlg := TTileDlg.Create(Application);
  try
    Dlg.edWidth.Text := IntToStr(TileSourceBmp.Width);
    Dlg.edHeight.Text := IntToStr(TileSourceBmp.Height);
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, TileSourceBmp.Width);
      NewH := StrToIntDef(Dlg.edHeight.Text, TileSourceBmp.Height);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
