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
    btnFullHD: TButton;
    grpTile: TGroupBox;
    rbTileOrig: TRadioButton;
    rbTileScale: TRadioButton;
    edTileScale: TEdit;
    rbTileCount: TRadioButton;
    edTileCount: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnFullHDClick(Sender: TObject);
    procedure rbTileClick(Sender: TObject);
  public
    procedure RefitButtons; override;
  end;

var
  TileSourceBmp: TBitmap = nil;

// TileW/TileH = 0: kafelek w rozmiarze oryginalu (jak przed 2026-10-24).
function ShowTileDlg(out NewW, NewH, TileW, TileH: Integer): Boolean;

implementation

{$R *.dfm}

function ShowTileDlg(out NewW, NewH, TileW, TileH: Integer): Boolean;
var
  Dlg: TTileDlg;
  SrcW, SrcH, Pct, Cnt: Integer;
begin
  Result := False;
  TileW := 0;
  TileH := 0;
  if TileSourceBmp = nil then Exit;
  SrcW := TileSourceBmp.Width;
  SrcH := TileSourceBmp.Height;
  Dlg := TTileDlg.Create(Application);
  try
    Dlg.edWidth.Text := IntToStr(SrcW);
    Dlg.edHeight.Text := IntToStr(SrcH);
    Dlg.edTileScale.Text := '50';
    Dlg.edTileCount.Text := '4';
    Dlg.rbTileOrig.Checked := True;
    Dlg.rbTileClick(nil);
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, SrcW);
      NewH := StrToIntDef(Dlg.edHeight.Text, SrcH);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
      if Dlg.rbTileScale.Checked then
      begin
        // procent wymiarow zdjecia
        Pct := EnsureRange(StrToIntDef(Dlg.edTileScale.Text, 100), 1, 1000);
        TileW := Max(1, Round(SrcW * Pct / 100));
        TileH := Max(1, Round(SrcH * Pct / 100));
      end
      else if Dlg.rbTileCount.Checked then
      begin
        // szerokosc docelowa / liczba kafelkow, wysokosc w proporcji zdjecia
        Cnt := EnsureRange(StrToIntDef(Dlg.edTileCount.Text, 1), 1, NewW);
        TileW := Max(1, Round(NewW / Cnt));
        TileH := Max(1, Round(SrcH * TileW / SrcW));
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TTileDlg.btnFullHDClick(Sender: TObject);
begin
  edWidth.Text := '1920';
  edHeight.Text := '1080';
end;

// Pole wartosci aktywne tylko przy wybranej opcji.
procedure TTileDlg.rbTileClick(Sender: TObject);
begin
  edTileScale.Enabled := rbTileScale.Checked;
  edTileCount.Enabled := rbTileCount.Checked;
end;

// Uklad wierszowy z zawartosci (2026-10-21; wczesniej sztywne 340x130, pola na
// stalym Left = 132, wiersze co 28 px - pusty pas nad przyciskami, duza
// przerwa etykieta-pole przy krotkich etykietach). Pole zaraz za najdluzsza
// etykieta, wysokosc okna = wiersze + pasek przyciskow (panele alTop/alBottom,
// wiec liczona tu, nie przez FitToContent). Odstepy z czcionki.
// 2026-10-24: przycisk Full HD obok pol wymiaru (na wysokosc obu wierszy) i
// ramka Rozmiar kafelka: Oryginal / Skala (%) / Kafelkow w poziomie.
procedure TTileDlg.RefitButtons;
var
  Margin, LabW, EdW, TH, CheckW, RbH, RowH, RowTop, EdLeft, EdW2: Integer;

  procedure PlaceRow(Rb: TRadioButton; Ed: TEdit);
  begin
    Rb.Left := CtrlGap * 2;
    Rb.Height := RbH;
    Rb.Width := Canvas.TextWidth(Rb.Caption) + CheckW + CtrlGap * 3;
    Rb.Top := RowTop + (RowH - RbH) div 2;
    if Ed <> nil then
      Ed.Top := RowTop + (RowH - Ed.Height) div 2;
    RowTop := RowTop + RowH + RowGap;
  end;

begin
  inherited;
  Margin := CtrlGap * 3;
  // wysokosc TEdit z czcionki ustawia dopiero CreateWnd (AdjustHeight)
  edWidth.HandleNeeded;
  edHeight.HandleNeeded;
  edTileScale.HandleNeeded;
  edTileCount.HandleNeeded;

  Canvas.Font.Assign(Font);
  TH := Canvas.TextHeight('Wg');
  LabW := Max(Canvas.TextWidth(lblWidth.Caption), Canvas.TextWidth(lblHeight.Caption));
  EdW := Canvas.TextWidth('000000') + CtrlGap * 4;

  edWidth.SetBounds(Margin + LabW + SectionGap, RowGap * 2, EdW, edWidth.Height);
  edHeight.SetBounds(edWidth.Left, edWidth.Top + edWidth.Height + RowGap, EdW,
    edHeight.Height);
  lblWidth.Left := Margin;
  lblWidth.Top := edWidth.Top + (edWidth.Height - lblWidth.Height) div 2;
  lblHeight.Left := Margin;
  lblHeight.Top := edHeight.Top + (edHeight.Height - lblHeight.Height) div 2;

  FitButton(btnFullHD);
  btnFullHD.Left := edWidth.Left + EdW + CtrlGap * 2;
  btnFullHD.Top := edWidth.Top;
  btnFullHD.Height := edHeight.Top + edHeight.Height - edWidth.Top;

  // Ramka Rozmiar kafelka: wiersze radio + pole, pola w jednej kolumnie.
  CheckW := GetSystemMetrics(SM_CXMENUCHECK);
  RbH := TH + 4;
  RowH := Max(RbH, edTileScale.Height);
  EdW2 := Canvas.TextWidth('0000') + CtrlGap * 4;
  RowTop := TH + RowGap * 2;
  PlaceRow(rbTileOrig, nil);
  PlaceRow(rbTileScale, edTileScale);
  PlaceRow(rbTileCount, edTileCount);
  EdLeft := Max(rbTileScale.Left + rbTileScale.Width,
    rbTileCount.Left + rbTileCount.Width) + CtrlGap * 2;
  edTileScale.SetBounds(EdLeft, edTileScale.Top, EdW2, edTileScale.Height);
  edTileCount.SetBounds(EdLeft, edTileCount.Top, EdW2, edTileCount.Height);
  grpTile.Left := Margin;
  grpTile.Top := edHeight.Top + edHeight.Height + SectionGap;
  grpTile.Width := Max(EdLeft + EdW2,
    rbTileOrig.Left + rbTileOrig.Width) + CtrlGap * 3;
  grpTile.Width := Max(grpTile.Width, Canvas.TextWidth(grpTile.Caption) + CtrlGap * 6);
  grpTile.Height := RowTop - RowGap + RowGap * 2;

  pnlInput.Height := grpTile.Top + grpTile.Height + RowGap * 2;

  btnOK.Top := RowGap * 2;
  btnCancel.Top := btnOK.Top;
  pnlBottom.Height := btnOK.Top + btnOK.Height + RowGap * 2;

  ClientWidth := Max(Max(btnFullHD.Left + btnFullHD.Width, grpTile.Left + grpTile.Width) + Margin,
    btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2);
  ClientHeight := pnlInput.Height + pnlBottom.Height + TitleBarGap;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

end.
