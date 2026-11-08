unit frmWaterRippleDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uDistort, uI18n, uTitleBar, uPreviewFit;

type
  TWaterRippleDlg = class(TFotoForm)
    pnlPreview: TPanel;
    pnlSliders: TPanel;
    pboxPreview: TPaintBox;
    lblStrength: TLabel;
    trkStrength: TTrackBar;
    lblStrengthVal: TLabel;
    lblDensity: TLabel;
    trkDensity: TTrackBar;
    lblDensityVal: TLabel;
    grpSource: TGroupBox;
    rbCenter: TRadioButton;
    rbTopLeft: TRadioButton;
    rbTopRight: TRadioButton;
    rbBottomLeft: TRadioButton;
    rbBottomRight: TRadioButton;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure trkSliderChange(Sender: TObject);
    procedure rbSourceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    function SourceIndex: Integer;
    procedure LayoutSource;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowWaterRippleDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  uMacros;

{$R *.dfm}

// Sila 0 = obraz bez zmian, OK jak Anuluj.
function ShowWaterRippleDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TWaterRippleDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TWaterRippleDlg.Create(Application);
  try
    Dlg.Caption := T('Water ripple');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(370.0 / Bitmap.Width, 300.0 / Bitmap.Height);
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

    FitPreviewToDialog(Dlg, Dlg.pnlPreview, Dlg.pboxPreview, pw, ph);

    Dlg.pnlPreview.Height := Dlg.pboxPreview.Top + Dlg.pboxPreview.Height + Dlg.CtrlGap;
    Dlg.ReflowTrackBarRows(Dlg.pnlSliders);
    Dlg.LayoutSource;
    Dlg.pnlSliders.Height := Dlg.grpSource.Top + Dlg.grpSource.Height + Dlg.CtrlGap;
    Dlg.btnOK.Top := Max(Dlg.pnlPreview.Top + Dlg.pnlPreview.Height,
                         Dlg.pnlSliders.Top + Dlg.pnlSliders.Height) + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if (Dlg.ShowModal = mrOk) and (Dlg.trkStrength.Position <> 0) then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      // zrodlo | sila | gestosc
      gMacroPending.Code := 'WATERRIPPLE';
      gMacroPending.Params := IntToStr(Dlg.SourceIndex) + '|' +
        IntToStr(Dlg.trkStrength.Position) + '|' + IntToStr(Dlg.trkDensity.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TWaterRippleDlg }

procedure TWaterRippleDlg.FormCreate(Sender: TObject);
begin
  lblStrengthVal.Caption := IntToStr(trkStrength.Position) + '%';
  lblDensityVal.Caption := IntToStr(trkDensity.Position);
end;

procedure TWaterRippleDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TWaterRippleDlg.trkSliderChange(Sender: TObject);
begin
  lblStrengthVal.Caption := IntToStr(trkStrength.Position) + '%';
  lblDensityVal.Caption := IntToStr(trkDensity.Position);
  ApplyPreview;
end;

procedure TWaterRippleDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH: Integer;
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
        (TargetW - NewW) div 2, (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW, (TargetH - NewH) div 2 + NewH);
      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

procedure TWaterRippleDlg.rbSourceClick(Sender: TObject);
begin
  ApplyPreview;
end;

// Numeracja jak w ApplyWaterRipple
function TWaterRippleDlg.SourceIndex: Integer;
begin
  if rbTopLeft.Checked then Result := 1
  else if rbBottomLeft.Checked then Result := 2
  else if rbTopRight.Checked then Result := 3
  else if rbBottomRight.Checked then Result := 4
  else Result := 0;
end;

// Srodek w pierwszym wierszu, narozniki 2 x 2 pod nim; wysokosc z czcionki.
procedure TWaterRippleDlg.LayoutSource;
var
  RowH, X1, X2, ColW, Y0, NeedCol, Delta: Integer;

  procedure Place(Rb: TRadioButton; AX, ARow: Integer);
  begin
    Rb.Left := AX;
    Rb.Top := Y0 + ARow * RowH;
    Rb.Width := ColW;
    Rb.Height := Canvas.TextHeight('Wg') + 2;
  end;

begin
  RowH := Canvas.TextHeight('Wg') + CtrlGap;
  Y0 := CtrlGap * 2;
  X1 := CtrlGap * 2;
  // kolumna z najdluzszego napisu; ramka, panel i okno szersze tylko, gdy
  // trzeba (DE 'Unten rechts' przy 12 pt; kontrola ukladu 2026-11-08)
  Canvas.Font.Assign(rbCenter.Font);
  NeedCol := Max(Max(Canvas.TextWidth(rbCenter.Caption), Canvas.TextWidth(rbTopLeft.Caption)),
    Max(Max(Canvas.TextWidth(rbTopRight.Caption), Canvas.TextWidth(rbBottomLeft.Caption)),
      Canvas.TextWidth(rbBottomRight.Caption))) + ButtonPad;
  Canvas.Font.Assign(Font);
  Delta := X1 * 2 + NeedCol * 2 - grpSource.ClientWidth;
  if Delta > 0 then
  begin
    grpSource.Width := grpSource.Width + Delta;
    pnlSliders.Width := pnlSliders.Width + Delta;
    ClientWidth := ClientWidth + Delta;
  end;
  ColW := (grpSource.ClientWidth - X1 * 2) div 2;
  X2 := X1 + ColW;
  Place(rbCenter, X1, 0);
  Place(rbTopLeft, X1, 1);
  Place(rbTopRight, X2, 1);
  Place(rbBottomLeft, X1, 2);
  Place(rbBottomRight, X2, 2);
  grpSource.Top := lblDensityVal.Top + lblDensityVal.Height + SectionGap;
  grpSource.Height := Y0 + 3 * RowH + CtrlGap;
end;

procedure TWaterRippleDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplyWaterRipple(FWorkingPreview, SourceIndex, trkStrength.Position, trkDensity.Position);
  pboxPreview.Invalidate;
end;

procedure TWaterRippleDlg.ApplyFull;
begin
  ApplyWaterRipple(FSourceBmp, SourceIndex, trkStrength.Position, trkDensity.Position);
end;

end.
