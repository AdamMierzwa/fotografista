unit frmRisoDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uRiso, uI18n, uTitleBar;

type
  TRisoVersion = (rvV1, rvV2);

  TRisoDlg = class(TFotoForm)
    lstPalettes: TListBox;
    pboxPreview: TPaintBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure lstPalettesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FVersion: TRisoVersion;
    FPrevW, FPrevH: Integer;   // rozmiar podgladu z proporcji zdjecia (limit 400)
    function CurrentPalette: TRisoPalette;
    procedure FitPreview(pw, ph: Integer);
    procedure ApplyPreview;
    procedure ApplyFull;
  public
    procedure RefitButtons; override;
  end;

function ShowRisoDlg(Bitmap: TBitmap; Version: TRisoVersion; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowRisoDlg(Bitmap: TBitmap; Version: TRisoVersion; out ElapsedSec: Double): Boolean;
var
  Dlg: TRisoDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TRisoDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;
    Dlg.FVersion := Version;
    if Version = rvV1 then
      Dlg.Caption := T('Risograph v1')
    else
      Dlg.Caption := T('Risograph v2');

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Scaled := TBitmap.Create;
    try
      Scaled.PixelFormat := pf24bit;
      Scaled.SetSize(pw, ph);
      Scaled.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

      Dlg.FOriginalPreview := TBitmap.Create;
      Dlg.FOriginalPreview.PixelFormat := pf24bit;
      Dlg.FOriginalPreview.SetSize(pw, ph);
      Dlg.FOriginalPreview.Canvas.Draw(0, 0, Scaled);

      Dlg.FWorkingPreview := TBitmap.Create;
      Dlg.FWorkingPreview.PixelFormat := pf24bit;
      Dlg.FWorkingPreview.SetSize(pw, ph);
    finally
      Scaled.Free;
    end;

    Dlg.FitPreview(pw, ph);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TRisoDlg }

procedure TRisoDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  DoubleBuffered := True;
  lstPalettes.Clear;
  for I := 0 to GetRisoPaletteCount - 1 do
    lstPalettes.Items.Add(GetRisoPaletteName(I));
  lstPalettes.ItemIndex := 0;
  // rozmiar listy, podgladu i okna: RefitButtons
end;

procedure TRisoDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

function TRisoDlg.CurrentPalette: TRisoPalette;
begin
  Result := GetRisoPalette(lstPalettes.ItemIndex);
end;

procedure TRisoDlg.FitPreview(pw, ph: Integer);
// Podgląd: rozmiar z proporcji zdjęcia (pw x ph, już ograniczone do 400 px
// w ShowRisoDlg). Położenie i rozmiar okna liczy RefitButtons (wcześniej
// obszar podglądu brany ze sztywnego ClientWidth z DFM).
begin
  if (pw <= 0) or (ph <= 0) then Exit;
  FPrevW := pw;
  FPrevH := ph;
  pboxPreview.Width := pw;
  pboxPreview.Height := ph;
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 640x465, lista 395 px
// wysokosci, szerokosc listy z zapasem 30 px liczona raz w FormCreate).
// Lista po lewej pokazuje wszystkie zestawy (bez przewijania), szerokosc z
// najdluzszej nazwy; podglad po prawej, oba wysrodkowane w pionie wzgledem
// siebie; OK/Anuluj do prawej. Odstepy z czcionki.
procedure TRisoDlg.RefitButtons;
var
  Margin, I, W, IH, AreaH, X2: Integer;
begin
  inherited;
  Margin := CtrlGap * 3;

  W := 0;
  for I := 0 to lstPalettes.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(lstPalettes.Items[I]));
  // rzeczywista wysokosc pozycji listy: dla lbStandard z uchwytem ItemHeight
  // zwraca wysokosc z GetItemRect (Vcl.StdCtrls.pas:7595-7604)
  if lstPalettes.HandleAllocated then
    IH := lstPalettes.ItemHeight
  else
    IH := Canvas.TextHeight('Wg');
  lstPalettes.Left := Margin;
  lstPalettes.ClientWidth := W + CtrlGap * 4;
  lstPalettes.ClientHeight := Max(1, lstPalettes.Items.Count) * IH;

  AreaH := Max(lstPalettes.Height, FPrevH);
  lstPalettes.Top := Margin + (AreaH - lstPalettes.Height) div 2;
  X2 := lstPalettes.Left + lstPalettes.Width + SectionGap;
  if FPrevW > 0 then
    pboxPreview.SetBounds(X2, Margin + (AreaH - FPrevH) div 2, FPrevW, FPrevH);

  btnOK.Top := Margin + AreaH + SectionGap;
  btnCancel.Top := btnOK.Top;
  FitToContent(SectionGap, Margin);
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

procedure TRisoDlg.lstPalettesClick(Sender: TObject);
begin
  if lstPalettes.ItemIndex >= 0 then ApplyPreview;
end;

procedure TRisoDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  if FVersion = rvV1 then
    DoRisoV1(FWorkingPreview, CurrentPalette)
  else
    DoRisoV2(FWorkingPreview, CurrentPalette);
  pboxPreview.Invalidate;
end;

procedure TRisoDlg.ApplyFull;
begin
  if FVersion = rvV1 then
    DoRisoV1(FSourceBmp, CurrentPalette)
  else
    DoRisoV2(FSourceBmp, CurrentPalette);
end;

procedure TRisoDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);

    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;

      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;

      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);

      DestRect := Rect(
        (TargetW - NewW) div 2,
        (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW,
        (TargetH - NewH) div 2 + NewH
      );

      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
