unit frmLinocut2Dlg;

// Okno Linorytu (uLinocut). Uklad i podglad jak w oknie Progu
// (frmLinocutDlg): nawigator po lewej, fragment 1:1 obok. Ksztalty liczone
// raz z calego obrazu po zmianie suwaka; nawigator i fragment rysowane z nich
// (wynik zalezy od calego obrazu - CLAHE, zmniejszenie - wiec fragmentu nie
// liczy sie osobno jak w Progu).

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar, uMacros, uI18n, uLinocut;

type
  TLinocut2Dlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblThreshold: TLabel;
    tbThreshold: TTrackBar;
    lblThresholdVal: TLabel;
    lblSimplify: TLabel;
    tbSimplify: TTrackBar;
    lblSimplifyVal: TLabel;
    lblMinArea: TLabel;
    tbMinArea: TTrackBar;
    lblMinVal: TLabel;
    lblCleanCount: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pboxZoomPaint(Sender: TObject);
    procedure tbChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FShapes: TLinocutShapes;
    FNavW, FNavH: Integer;
    FZoomW, FZoomH: Integer;
    FZoomX, FZoomY: Integer;
    FZoomBmp: TBitmap;
    FZoomTimer: TTimer;
    FZoomDirty: Boolean;
    procedure ApplyPreview;
    procedure RenderFragment;
    procedure RebuildZoom(X, Y: Integer);
    procedure ZoomTimerTick(Sender: TObject);
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
  end;

function ShowLinocut2Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowLinocut2Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TLinocut2Dlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TLinocut2Dlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    // Podgląd 100%: te same wymiary co nawigator; fragment = 1:1 pikseli oryginału.
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;
    Dlg.FZoomW := Min(pw, Bitmap.Width);
    Dlg.FZoomH := Min(ph, Bitmap.Height);
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(Dlg.FZoomW, Dlg.FZoomH);
    Dlg.FZoomX := (Bitmap.Width - Dlg.FZoomW) div 2;
    Dlg.FZoomY := (Bitmap.Height - Dlg.FZoomH) div 2;

    // Layout: nawigator po lewej, podgląd 100% obok, pod nimi dwa suwaki.
    Dlg.pboxPreview.Width := pw;
    Dlg.pboxPreview.Height := ph;
    Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxPreview.Top := Dlg.TitleBarGap + Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.pboxZoom.Top := Dlg.pboxPreview.Top;
    Dlg.pboxZoom.Width := Dlg.FZoomW;
    Dlg.pboxZoom.Height := Dlg.FZoomH;

    Dlg.lblThreshold.Top := Dlg.pboxPreview.Top +
      Max(Dlg.pboxPreview.Height, Dlg.pboxZoom.Height) + Dlg.RowGap * 2;
    Dlg.tbThreshold.Top := Dlg.StackBelow(Dlg.lblThreshold, Dlg.RowGap);
    Dlg.lblThresholdVal.Top := Dlg.StackBelow(Dlg.tbThreshold, 0);
    Dlg.lblSimplify.Top := Dlg.StackBelow(Dlg.lblThresholdVal, Dlg.RowGap * 2);
    Dlg.tbSimplify.Top := Dlg.StackBelow(Dlg.lblSimplify, Dlg.RowGap);
    Dlg.lblSimplifyVal.Top := Dlg.StackBelow(Dlg.tbSimplify, 0);
    Dlg.lblMinArea.Top := Dlg.StackBelow(Dlg.lblSimplifyVal, Dlg.RowGap * 2);
    Dlg.tbMinArea.Top := Dlg.StackBelow(Dlg.lblMinArea, Dlg.RowGap);
    Dlg.lblMinVal.Top := Dlg.StackBelow(Dlg.tbMinArea, 0);
    Dlg.lblCleanCount.Top := Dlg.StackBelow(Dlg.lblMinVal, Dlg.RowGap);
    Dlg.btnOK.Top := Dlg.StackBelow(Dlg.lblCleanCount, Dlg.RowGap * 2);
    Dlg.btnCancel.Top := Dlg.btnOK.Top;

    Dlg.ApplyPreview;

    Dlg.ButtonsToLeft([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wyśrodkowanie pary podglądów w szerokości okna.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + Dlg.FZoomW)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      gMacroPending.Code := 'LINOCUT2';
      gMacroPending.Params := IntToStr(Dlg.tbThreshold.Position) + '|' +
        IntToStr(Dlg.tbSimplify.Position) + '|' + IntToStr(Dlg.tbMinArea.Position);
      DoLinocut2(Dlg.FSourceBmp, Dlg.tbThreshold.Position, Dlg.tbSimplify.Position,
        Dlg.tbMinArea.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TLinocut2Dlg }

procedure TLinocut2Dlg.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  tbThreshold.Min := 1;
  tbThreshold.Max := 100;
  tbThreshold.Position := cLinocutThresholdDefault;
  tbSimplify.Min := 1;
  tbSimplify.Max := 10;
  tbSimplify.Position := cLinocutSimplifyDefault;
  tbMinArea.Min := 0;
  tbMinArea.Max := cLinocutMinAreaMax;
  tbMinArea.Position := cLinocutMinAreaDefault;
  lblThresholdVal.Caption := IntToStr(tbThreshold.Position);
  lblSimplifyVal.Caption := IntToStr(tbSimplify.Position);
  lblMinVal.Caption := IntToStr(tbMinArea.Position);
  lblCleanCount.Caption := T('Islands removed:') + ' 0';
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
end;

procedure TLinocut2Dlg.FormDestroy(Sender: TObject);
begin
  FWorkingPreview.Free;
  FZoomBmp.Free;
end;

procedure TLinocut2Dlg.tbChange(Sender: TObject);
begin
  lblThresholdVal.Caption := IntToStr(tbThreshold.Position);
  lblSimplifyVal.Caption := IntToStr(tbSimplify.Position);
  lblMinVal.Caption := IntToStr(tbMinArea.Position);
  ApplyPreview;
end;

procedure TLinocut2Dlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FSourceBmp = nil) then Exit;
  BuildLinocutShapes(FSourceBmp, tbThreshold.Position, tbSimplify.Position,
    tbMinArea.Position, FShapes);
  lblCleanCount.Caption := T('Islands removed:') + ' ' + IntToStr(FShapes.Removed);
  RenderLinocutShapes(FShapes, FWorkingPreview, FNavW, FNavH, 0, 0);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TLinocut2Dlg.RenderFragment;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  RenderLinocutShapes(FShapes, FZoomBmp, FSourceBmp.Width, FSourceBmp.Height,
    FZoomX, FZoomY);
  FZoomDirty := False;
end;

procedure TLinocut2Dlg.RebuildZoom(X, Y: Integer);
var
  MaxX, MaxY: Integer;
  R, C, UR: TRect;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  MaxX := FSourceBmp.Width - FZoomW;
  MaxY := FSourceBmp.Height - FZoomH;
  if MaxX < 0 then MaxX := 0;
  if MaxY < 0 then MaxY := 0;
  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  if X > MaxX then X := MaxX;
  if Y > MaxY then Y := MaxY;
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  R := CursorRect;   // stara pozycja ramki
  FZoomX := X;
  FZoomY := Y;
  // Ramka rusza się natychmiast; rysowanie fragmentu przez FZoomTimer.
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  FZoomDirty := True;
  if (FZoomTimer <> nil) and (not FZoomTimer.Enabled) then
    FZoomTimer.Enabled := True;
end;

procedure TLinocut2Dlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TLinocut2Dlg.CursorRect: TRect;
var
  Sx, Sy: Double;
begin
  Sx := FNavW / FSourceBmp.Width;
  Sy := FNavH / FSourceBmp.Height;
  Result.Left := Max(0, Round(FZoomX * Sx));
  Result.Top := Max(0, Round(FZoomY * Sy));
  Result.Right := Min(FNavW, Round((FZoomX + FZoomW) * Sx));
  Result.Bottom := Min(FNavH, Round((FZoomY + FZoomH) * Sy));
end;

// Odświeża tylko obszar objęty aRect (współrzędne nawigatora).
procedure TLinocut2Dlg.InvalidateNavRect(aRect: TRect);
var
  P: TWinControl;
begin
  P := pboxPreview.Parent;
  if (P = nil) or (P.Handle = 0) then Exit;
  InflateRect(aRect, 1, 1);
  if aRect.Left < 0 then aRect.Left := 0;
  if aRect.Top < 0 then aRect.Top := 0;
  if aRect.Right > FNavW then aRect.Right := FNavW;
  if aRect.Bottom > FNavH then aRect.Bottom := FNavH;
  OffsetRect(aRect, pboxPreview.Left, pboxPreview.Top);
  InvalidateRect(P.Handle, @aRect, False);
end;

procedure TLinocut2Dlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TLinocut2Dlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TLinocut2Dlg.pboxPreviewPaint(Sender: TObject);
var
  R: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) then
      Draw(0, 0, FWorkingPreview);
    if (FSourceBmp <> nil) and (FZoomW > 0) and (FZoomH > 0) then
    begin
      // Ramka obszaru podglądu 100%.
      R := CursorRect;
      Brush.Style := bsClear;
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Rectangle(R);
      Pen.Color := clWhite;
      FrameRect(Rect(R.Left - 1, R.Top - 1, R.Right + 1, R.Bottom + 1));
      Pen.Width := 1;
      Brush.Style := bsSolid;
    end;
  end;
end;

end.
