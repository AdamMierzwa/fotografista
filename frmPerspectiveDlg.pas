unit frmPerspectiveDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls, uTitleBar, uTransform;

type
  TPerspectiveDlg = class(TFotoForm)
    pboxSrc: TPaintBox;
    pboxDst: TPaintBox;
    lblHint: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pboxSrcPaint(Sender: TObject);
    procedure pboxDstPaint(Sender: TObject);
    procedure pboxSrcMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pboxSrcMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure pboxSrcMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FPreviewBmp: TBitmap;
    FWarpedBmp: TBitmap;
    FImgW: Integer;
    FImgH: Integer;
    FScale: Double;
    FQuad: TQuad;
    FDragIdx: Integer;
    function PreviewQuad: TQuad;
    function HitTest(X, Y: Integer): Integer;
    procedure LayoutDialog;
    procedure UpdateWarp;
    procedure DrawHandle(ACanvas: TCanvas; X, Y: Integer);
  end;

var
  PerspectiveSourceBmp: TBitmap = nil;

function ShowPerspectiveDlg(out Quad: TQuad): Boolean;

implementation

{$R *.dfm}

const
  cPreviewMax = 340;
  cHandleR    = 4;
  cHitR       = 7;

function ShowPerspectiveDlg(out Quad: TQuad): Boolean;
var
  Dlg: TPerspectiveDlg;
begin
  Result := False;
  if PerspectiveSourceBmp = nil then Exit;
  Dlg := TPerspectiveDlg.Create(Application);
  try
    Result := Dlg.ShowModal = mrOk;
    if Result then Quad := Dlg.FQuad;
  finally
    Dlg.Free;
  end;
end;

procedure TPerspectiveDlg.FormCreate(Sender: TObject);
begin
  FDragIdx := -1;
  if (PerspectiveSourceBmp = nil) or (PerspectiveSourceBmp.Width = 0) then Exit;

  FImgW := PerspectiveSourceBmp.Width;
  FImgH := PerspectiveSourceBmp.Height;

  FQuad[0] := TPointF.Create(0, 0);
  FQuad[1] := TPointF.Create(FImgW, 0);
  FQuad[2] := TPointF.Create(FImgW, FImgH);
  FQuad[3] := TPointF.Create(0, FImgH);

  LayoutDialog;
  UpdateWarp;
end;

procedure TPerspectiveDlg.FormDestroy(Sender: TObject);
begin
  FPreviewBmp.Free;
  FWarpedBmp.Free;
end;

procedure TPerspectiveDlg.LayoutDialog;
var
  PW, PH, Margin: Integer;
begin
  Margin := CtrlGap * 3;

  if FImgW >= FImgH then
  begin
    PW := cPreviewMax;
    PH := Max(1, Round(FImgH / FImgW * cPreviewMax));
  end
  else
  begin
    PH := cPreviewMax;
    PW := Max(1, Round(FImgW / FImgH * cPreviewMax));
  end;
  FScale := PW / FImgW;

  FPreviewBmp := TBitmap.Create;
  FPreviewBmp.PixelFormat := pf24bit;
  FPreviewBmp.SetSize(PW, PH);
  SetStretchBltMode(FPreviewBmp.Canvas.Handle, HALFTONE);
  FPreviewBmp.Canvas.StretchDraw(Rect(0, 0, PW, PH), PerspectiveSourceBmp);

  pboxSrc.SetBounds(Margin, Margin, PW, PH);
  pboxDst.SetBounds(Margin + PW + CtrlGap * 4, Margin, PW, PH);

  lblHint.Left := Margin;
  lblHint.Width := PW * 2 + CtrlGap * 4;
  lblHint.Top := Margin + PH + RowGap;
  lblHint.Height := Canvas.TextHeight('Wg') * 2 + 2;

  FitToContent(CtrlGap * 3, CtrlGap * 3);
  btnOK.Top := lblHint.Top + lblHint.Height + CtrlGap * 3;
  btnCancel.Top := btnOK.Top;
  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
end;

function TPerspectiveDlg.PreviewQuad: TQuad;
var
  I: Integer;
begin
  for I := 0 to 3 do
  begin
    Result[I].X := FQuad[I].X * FScale;
    Result[I].Y := FQuad[I].Y * FScale;
  end;
end;

procedure TPerspectiveDlg.UpdateWarp;
var
  PQ: TQuad;
  OW, OH: Integer;
  NewBmp: TBitmap;
begin
  if (FPreviewBmp = nil) or (FPreviewBmp.Width = 0) then Exit;

  btnOK.Enabled := QuadIsConvex(FQuad);
  if not btnOK.Enabled then
  begin
    pboxDst.Invalidate;
    Exit;
  end;

  PQ := PreviewQuad;
  PerspectiveOutputSize(PQ, OW, OH);
  if (OW < 1) or (OH < 1) then Exit;

  NewBmp := PerspectiveWarp(FPreviewBmp, PQ, OW, OH);
  if NewBmp <> nil then
  begin
    FWarpedBmp.Free;
    FWarpedBmp := NewBmp;
  end;
  pboxDst.Invalidate;
end;

function TPerspectiveDlg.HitTest(X, Y: Integer): Integer;
var
  I, PX, PY: Integer;
begin
  Result := -1;
  for I := 0 to 3 do
  begin
    PX := Round(FQuad[I].X * FScale);
    PY := Round(FQuad[I].Y * FScale);
    if Sqr(X - PX) + Sqr(Y - PY) <= Sqr(cHitR) then Exit(I);
  end;
end;

procedure TPerspectiveDlg.DrawHandle(ACanvas: TCanvas; X, Y: Integer);
begin
  ACanvas.Brush.Color := clRed;
  ACanvas.FillRect(
    Rect(X - cHandleR, Y - cHandleR, X + cHandleR + 1, Y + cHandleR + 1));
end;

procedure TPerspectiveDlg.pboxSrcPaint(Sender: TObject);
var
  I, J, PX, PY, QX, QY: Integer;
begin
  with pboxSrc.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxSrc.ClientRect);
    if FPreviewBmp <> nil then
      Draw(0, 0, FPreviewBmp);

    Pen.Color := clWhite;
    Pen.Width := 1;
    for I := 0 to 3 do
    begin
      J := (I + 1) mod 4;
      PX := Round(FQuad[I].X * FScale);
      PY := Round(FQuad[I].Y * FScale);
      QX := Round(FQuad[J].X * FScale);
      QY := Round(FQuad[J].Y * FScale);
      MoveTo(PX, PY);
      LineTo(QX, QY);
    end;

    for I := 0 to 3 do
      DrawHandle(pboxSrc.Canvas,
        Round(FQuad[I].X * FScale), Round(FQuad[I].Y * FScale));
  end;
end;

procedure TPerspectiveDlg.pboxDstPaint(Sender: TObject);
var
  Sc: Double;
  RW, RH, DX, DY: Integer;
begin
  with pboxDst.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxDst.ClientRect);
    if (FWarpedBmp = nil) or (FWarpedBmp.Width = 0) or
       (FWarpedBmp.Height = 0) then Exit;

    Sc := Min(pboxDst.ClientWidth / FWarpedBmp.Width,
              pboxDst.ClientHeight / FWarpedBmp.Height);
    RW := Max(1, Round(FWarpedBmp.Width * Sc));
    RH := Max(1, Round(FWarpedBmp.Height * Sc));
    DX := (pboxDst.ClientWidth - RW) div 2;
    DY := (pboxDst.ClientHeight - RH) div 2;

    SetStretchBltMode(Canvas.Handle, HALFTONE);
    StretchDraw(Rect(DX, DY, DX + RW, DY + RH), FWarpedBmp);
  end;
end;

procedure TPerspectiveDlg.pboxSrcMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  FDragIdx := HitTest(X, Y);
end;

procedure TPerspectiveDlg.pboxSrcMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  IX, IY: Double;
begin
  if not (ssLeft in Shift) then
  begin
    FDragIdx := -1;
    Exit;
  end;
  if FDragIdx < 0 then Exit;

  IX := X / FScale;
  IY := Y / FScale;
  if IX < 0 then IX := 0 else if IX > FImgW then IX := FImgW;
  if IY < 0 then IY := 0 else if IY > FImgH then IY := FImgH;

  FQuad[FDragIdx] := TPointF.Create(IX, IY);
  UpdateWarp;
  pboxSrc.Invalidate;
end;

procedure TPerspectiveDlg.pboxSrcMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragIdx := -1;
end;

end.
