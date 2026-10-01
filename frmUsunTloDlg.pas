unit frmUsunTloDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Types,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar, uI18n, uPreviewFit;

type
  TUsunTloDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblCorner: TLabel;
    rgCorner: TRadioGroup;
    lblTolerance: TLabel;
    tbTolerance: TTrackBar;
    lblTolValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure rgCornerClick(Sender: TObject);
    procedure tbToleranceChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FPvMask: TBitmap;
    procedure ApplyPreview;
  end;

function ShowUsunTloDlg(Bitmap, Mask: TBitmap; out Corner, Tolerance: Integer): Boolean;
procedure ApplyRemoveBackground(Bitmap, Mask: TBitmap; Corner, Tolerance: Integer; var DirtyRect: TRect);

implementation

{$R *.dfm}

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

var
  gUsunTloLastCorner: Integer;
  gUsunTloLastTolerance: Integer;

procedure RemoveBackgroundFlood(Bitmap, Mask: TBitmap; Corner, Tolerance: Integer;
  var DirtyRect: TRect);
var
  W, H, Y, X, NX, NY, SP, Cur, Tol: Integer;
  Rows: array of PRGBTripleArray;
  MaskRows: array of PByte;
  Visited: array of Byte;
  Stack: array of Integer;
  StartX, StartY, CR, CG, CB: Integer;
  MinX, MinY, MaxX, MaxY: Integer;
  Changed: Boolean;
begin
  DirtyRect := Rect(0, 0, 0, 0);
  if (Bitmap = nil) or (Mask = nil) then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if (Mask.Width <> W) or (Mask.Height <> H) then Exit;
  if Tolerance < 0 then Tol := 0
  else if Tolerance > 255 then Tol := 255
  else Tol := Tolerance;

  StartX := 0;
  StartY := 0;
  case Corner of
    1: StartY := H - 1;      // Bottom-left
    2: StartX := W - 1;      // Top-right
    3: begin
         StartX := W - 1;
         StartY := H - 1;
       end;
  end;

  SetLength(Rows, H);
  SetLength(MaskRows, H);
  for Y := 0 to H - 1 do
  begin
    Rows[Y] := Bitmap.ScanLine[Y];
    MaskRows[Y] := Mask.ScanLine[Y];
  end;

  CR := Rows[StartY][StartX].R;
  CG := Rows[StartY][StartX].G;
  CB := Rows[StartY][StartX].B;

  SetLength(Visited, W * H);
  FillChar(Visited[0], W * H, 0);
  SetLength(Stack, W * H);

  SP := 0;
  Stack[SP] := StartY * W + StartX;
  Inc(SP);
  Visited[StartY * W + StartX] := 1;

  MinX := MaxInt;
  MinY := MaxInt;
  MaxX := -1;
  MaxY := -1;
  Changed := False;

  while SP > 0 do
  begin
    Dec(SP);
    Cur := Stack[SP];
    X := Cur mod W;
    Y := Cur div W;

    if MaskRows[Y][X] <> 0 then
    begin
      MaskRows[Y][X] := 0;
      Changed := True;
      if X < MinX then MinX := X;
      if X > MaxX then MaxX := X;
      if Y < MinY then MinY := Y;
      if Y > MaxY then MaxY := Y;
    end;

    if X > 0 then
    begin
      NX := X - 1;
      NY := Y;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - CR) <= Tol) and
           (Abs(Rows[NY][NX].G - CG) <= Tol) and
           (Abs(Rows[NY][NX].B - CB) <= Tol) then
        begin
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if X + 1 < W then
    begin
      NX := X + 1;
      NY := Y;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - CR) <= Tol) and
           (Abs(Rows[NY][NX].G - CG) <= Tol) and
           (Abs(Rows[NY][NX].B - CB) <= Tol) then
        begin
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if Y > 0 then
    begin
      NX := X;
      NY := Y - 1;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - CR) <= Tol) and
           (Abs(Rows[NY][NX].G - CG) <= Tol) and
           (Abs(Rows[NY][NX].B - CB) <= Tol) then
        begin
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;

    if Y + 1 < H then
    begin
      NX := X;
      NY := Y + 1;
      if Visited[NY * W + NX] = 0 then
      begin
        Visited[NY * W + NX] := 1;
        if (Abs(Rows[NY][NX].R - CR) <= Tol) and
           (Abs(Rows[NY][NX].G - CG) <= Tol) and
           (Abs(Rows[NY][NX].B - CB) <= Tol) then
        begin
          Stack[SP] := NY * W + NX;
          Inc(SP);
        end;
      end;
    end;
  end;

  if Changed then
    DirtyRect := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

procedure ApplyRemoveBackground(Bitmap, Mask: TBitmap; Corner, Tolerance: Integer;
  var DirtyRect: TRect);
var
  R: TRect;
begin
  RemoveBackgroundFlood(Bitmap, Mask, Corner, Tolerance, R);
  if (R.Right <= R.Left) or (R.Bottom <= R.Top) then Exit;
  if (DirtyRect.Right <= DirtyRect.Left) or (DirtyRect.Bottom <= DirtyRect.Top) then
    DirtyRect := R
  else
  begin
    if R.Left < DirtyRect.Left then DirtyRect.Left := R.Left;
    if R.Top < DirtyRect.Top then DirtyRect.Top := R.Top;
    if R.Right > DirtyRect.Right then DirtyRect.Right := R.Right;
    if R.Bottom > DirtyRect.Bottom then DirtyRect.Bottom := R.Bottom;
  end;
end;

procedure DrawChecker(Bmp: TBitmap; Mask: TBitmap);
var
  Y, X, XEnd, S: Integer;
  P: PByte;
begin
  if (Bmp = nil) or (Mask = nil) then Exit;
  if (Mask.Width <> Bmp.Width) or (Mask.Height <> Bmp.Height) then Exit;
  with Bmp.Canvas do
  begin
    Brush.Style := bsSolid;
    for Y := 0 to Bmp.Height - 1 do
    begin
      P := Mask.ScanLine[Y];
      X := 0;
      while X < Bmp.Width do
      begin
        while (X < Bmp.Width) and (P[X] <> 0) do Inc(X);
        if X >= Bmp.Width then Break;
        S := X;
        XEnd := ((X div 8) + 1) * 8;
        if XEnd > Bmp.Width then XEnd := Bmp.Width;
        while (X < XEnd) and (P[X] = 0) do Inc(X);
        if ((S div 8) + (Y div 8)) mod 2 = 0 then
          Brush.Color := clWhite
        else
          Brush.Color := clSilver;
        FillRect(Rect(S, Y, X, Y + 1));
      end;
    end;
  end;
end;

function ShowUsunTloDlg(Bitmap, Mask: TBitmap; out Corner, Tolerance: Integer): Boolean;
var
  Dlg: TUsunTloDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
begin
  Corner := 0;
  Tolerance := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TUsunTloDlg.Create(Application);
  try
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
    finally
      Scaled.Free;
    end;

    Dlg.FPvMask := TBitmap.Create;
    Dlg.FPvMask.PixelFormat := pf8bit;
    Dlg.FPvMask.SetSize(pw, ph);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    Dlg.rgCorner.ItemIndex := gUsunTloLastCorner;
    Dlg.tbTolerance.Position := gUsunTloLastTolerance;
    Dlg.lblTolValue.Caption := IntToStr(Dlg.tbTolerance.Position);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    Dlg.lblCorner.Top := Dlg.pboxPreview.Top + Dlg.pboxPreview.Height + Dlg.SectionGap;
    Dlg.rgCorner.Top := Dlg.lblCorner.Top + Dlg.lblCorner.Height + Dlg.CtrlGap;
    Dlg.rgCorner.Height := Dlg.Canvas.TextHeight('Wg') * 3 + 18;
    Dlg.lblTolerance.Top := Dlg.rgCorner.Top + Dlg.rgCorner.Height + Dlg.SectionGap;
    Dlg.tbTolerance.Top := Dlg.lblTolerance.Top + Dlg.lblTolerance.Height + Dlg.CtrlGap;
    Dlg.lblTolValue.Top := Dlg.tbTolerance.Top + Dlg.tbTolerance.Height + Dlg.CtrlGap;
    Dlg.btnOK.Top := Dlg.lblTolValue.Top + Dlg.lblTolValue.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      Corner := Dlg.rgCorner.ItemIndex;
      Tolerance := Dlg.tbTolerance.Position;
      gUsunTloLastCorner := Corner;
      gUsunTloLastTolerance := Tolerance;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TUsunTloDlg }

procedure TUsunTloDlg.FormCreate(Sender: TObject);
begin
  rgCorner.Items.Add(T('Top-left'));
  rgCorner.Items.Add(T('Bottom-left'));
  rgCorner.Items.Add(T('Top-right'));
  rgCorner.Items.Add(T('Bottom-right'));
  rgCorner.ItemIndex := 0;
  tbTolerance.Position := 32;
  lblTolValue.Caption := IntToStr(tbTolerance.Position);
end;

procedure TUsunTloDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FPvMask.Free;
end;

procedure TUsunTloDlg.rgCornerClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TUsunTloDlg.tbToleranceChange(Sender: TObject);
begin
  lblTolValue.Caption := IntToStr(tbTolerance.Position);
  ApplyPreview;
end;

procedure TUsunTloDlg.ApplyPreview;
var
  R: TRect;
  Y: Integer;
  P: PByte;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FPvMask = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  for Y := 0 to FPvMask.Height - 1 do
  begin
    P := FPvMask.ScanLine[Y];
    FillChar(P^, FPvMask.Width, 255);
  end;
  RemoveBackgroundFlood(FWorkingPreview, FPvMask, rgCorner.ItemIndex,
    tbTolerance.Position, R);
  DrawChecker(FWorkingPreview, FPvMask);
  pboxPreview.Invalidate;
end;

procedure TUsunTloDlg.pboxPreviewPaint(Sender: TObject);
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

initialization

  gUsunTloLastCorner := 0;
  gUsunTloLastTolerance := 32;

end.