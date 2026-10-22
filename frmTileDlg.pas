unit frmTileDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
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
  public
    procedure RefitButtons; override;
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

// Uklad wierszowy z zawartosci (2026-10-21; wczesniej sztywne 340x130, pola na
// stalym Left = 132, wiersze co 28 px - pusty pas nad przyciskami, duza
// przerwa etykieta-pole przy krotkich etykietach). Pole zaraz za najdluzsza
// etykieta, wysokosc okna = wiersze + pasek przyciskow (panele alTop/alBottom,
// wiec liczona tu, nie przez FitToContent). Odstepy z czcionki.
procedure TTileDlg.RefitButtons;
var
  Margin, LabW, EdW: Integer;
begin
  inherited;
  Margin := CtrlGap * 3;
  LabW := Max(Canvas.TextWidth(lblWidth.Caption), Canvas.TextWidth(lblHeight.Caption));
  EdW := Canvas.TextWidth('000000') + CtrlGap * 4;

  edWidth.SetBounds(Margin + LabW + SectionGap, RowGap * 2, EdW, edWidth.Height);
  edHeight.SetBounds(edWidth.Left, edWidth.Top + edWidth.Height + RowGap, EdW,
    edHeight.Height);
  lblWidth.Left := Margin;
  lblWidth.Top := edWidth.Top + (edWidth.Height - lblWidth.Height) div 2;
  lblHeight.Left := Margin;
  lblHeight.Top := edHeight.Top + (edHeight.Height - lblHeight.Height) div 2;
  pnlInput.Height := edHeight.Top + edHeight.Height + RowGap * 2;

  btnOK.Top := RowGap * 2;
  btnCancel.Top := btnOK.Top;
  pnlBottom.Height := btnOK.Top + btnOK.Height + RowGap * 2;

  ClientWidth := Max(edWidth.Left + EdW + Margin,
    btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2);
  ClientHeight := pnlInput.Height + pnlBottom.Height + TitleBarGap;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

end.
