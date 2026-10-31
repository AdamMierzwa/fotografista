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
    chkSample: TCheckBox;
    lblDistance: TLabel;
    tbDistance: TTrackBar;
    lblDistValue: TLabel;
    lblTolerance: TLabel;
    tbTolerance: TTrackBar;
    lblTolValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure rgCornerClick(Sender: TObject);
    procedure tbToleranceChange(Sender: TObject);
    procedure chkSampleClick(Sender: TObject);
    procedure tbDistanceChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FPvMask: TBitmap;
    FPvBlock: Integer;   // bok bloku probki w pikselach podgladu
    function SampleDist: Integer;
    procedure ApplyPreview;
  end;

function ShowUsunTloDlg(Bitmap, Mask: TBitmap; out Corner, Tolerance, SampleDist: Integer): Boolean;
procedure ApplyRemoveBackground(Bitmap, Mask: TBitmap; Corner, Tolerance, SampleDist: Integer; var DirtyRect: TRect);

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
  TRowPtrs = array of PRGBTripleArray;

var
  gUsunTloLastCorner: Integer;
  gUsunTloLastTolerance: Integer;
  gUsunTloLastSample: Boolean;
  gUsunTloLastDist: Integer;

const
  // bok podgladu w oknie (ShowUsunTloDlg) - skala latki koloru startu
  cPreviewSide = 400;
  cSampleBlock = 5;    // bok bloku probki na zdjeciu

// Blok probki: na przekatnej od naroznika, odleglosc w % krotszego boku.
function SampleBlockRect(W, H, Corner, DistPct, Side: Integer): TRect;
var
  D, X, Y: Integer;
begin
  D := Round(Min(W, H) * DistPct / 100);
  Side := Min(Side, Min(W, H));
  if Corner in [0, 1] then X := D else X := W - Side - D;
  if Corner in [0, 2] then Y := D else Y := H - Side - D;
  X := EnsureRange(X, 0, W - Side);
  Y := EnsureRange(Y, 0, H - Side);
  Result := Rect(X, Y, X + Side, Y + Side);
end;

// Wypelnianie od narozika (4-sasiedztwo) z tolerancja wzgledem koloru startu.
// 2026-10-27: kolor startu = srednia (osobno R, G, B) latki S x S w narozniku,
// S = piksel podgladu w pikselach zdjecia; podglad sam ma S = 1. Srednia, bo
// tak liczy piksel podgladu (HALFTONE) - mediana brala wiecej niz podglad
// (Vermeer T=32: 71% wobec 45%), srednia 44% wobec 45%. Pojedynczy
// piksel narozika bywa inny niz tlo (Vermeer: jasny (79,80,98) przy tle
// ~(35,38,38)) - na pelnym zdjeciu wypelnianie stalo w rogu, a podglad
// (piksel = srednia kilku) bral tlo. Start z kazdego piksela latki, ktory
// miesci sie w tolerancji.
// SampleDist > 0: latka to blok SampleSide x SampleSide w oddaleniu od narozika
// (SampleBlockRect) i z niego rusza wypelnianie - rog poza tolerancja nie
// zatrzymuje wtedy wypelniania.
procedure RemoveBackgroundFlood(Bitmap, Mask: TBitmap; Corner, Tolerance,
  SampleDist, SampleSide: Integer; out SeedR, SeedG, SeedB: Integer;
  var DirtyRect: TRect);
var
  W, H, Y, X, SP, Cur, Tol, S, X0, Y0, N: Integer;
  Rows: TRowPtrs;
  MaskRows: array of PByte;
  Visited: array of Byte;
  Stack: array of Integer;
  Sum: array[0..2] of Integer;
  StartX, StartY, CR, CG, CB: Integer;
  MinX, MinY, MaxX, MaxY: Integer;
  Changed: Boolean;
  Block: TRect;

  procedure TryPush(NX, NY: Integer);
  var
    I: Integer;
  begin
    I := NY * W + NX;
    if Visited[I] <> 0 then Exit;
    Visited[I] := 1;
    if (Abs(Rows[NY][NX].R - CR) <= Tol) and
       (Abs(Rows[NY][NX].G - CG) <= Tol) and
       (Abs(Rows[NY][NX].B - CB) <= Tol) then
    begin
      Stack[SP] := I;
      Inc(SP);
    end;
  end;

begin
  SeedR := 0;
  SeedG := 0;
  SeedB := 0;
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

  if SampleDist > 0 then
  begin
    Block := SampleBlockRect(W, H, Corner, SampleDist, SampleSide);
    S := Block.Right - Block.Left;
    X0 := Block.Left;
    Y0 := Block.Top;
  end
  else
  begin
    S := Max(1, Round(Max(W, H) / cPreviewSide));
    S := Min(S, Min(W, H));
    if StartX = 0 then X0 := 0 else X0 := W - S;
    if StartY = 0 then Y0 := 0 else Y0 := H - S;
  end;
  FillChar(Sum, SizeOf(Sum), 0);
  for Y := Y0 to Y0 + S - 1 do
    for X := X0 to X0 + S - 1 do
    begin
      Inc(Sum[0], Rows[Y][X].B);
      Inc(Sum[1], Rows[Y][X].G);
      Inc(Sum[2], Rows[Y][X].R);
    end;
  N := S * S;
  CB := (Sum[0] + N div 2) div N;
  CG := (Sum[1] + N div 2) div N;
  CR := (Sum[2] + N div 2) div N;
  SeedR := CR;
  SeedG := CG;
  SeedB := CB;

  SetLength(Visited, W * H);
  FillChar(Visited[0], W * H, 0);
  SetLength(Stack, W * H);

  SP := 0;
  for Y := Y0 to Y0 + S - 1 do
    for X := X0 to X0 + S - 1 do
      TryPush(X, Y);
  if SampleDist > 0 then
    Cur := (Y0 + S div 2) * W + X0 + S div 2
  else
    Cur := StartY * W + StartX;
  if Visited[Cur] = 0 then Visited[Cur] := 1;
  if SP = 0 then
  begin
    Stack[SP] := Cur;
    Inc(SP);
  end;

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

    if X > 0 then TryPush(X - 1, Y);
    if X + 1 < W then TryPush(X + 1, Y);
    if Y > 0 then TryPush(X, Y - 1);
    if Y + 1 < H then TryPush(X, Y + 1);
  end;

  if Changed then
    DirtyRect := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

function PreviewScale(Bitmap: TBitmap): Double;
begin
  Result := Min(1.0, Min(cPreviewSide / Bitmap.Width, cPreviewSide / Bitmap.Height));
end;

// HALFTONE wprost (Canvas.StretchDraw przestawia na STRETCH_DELETESCANS):
// piksel podgladu = srednia.
function CreatePreviewBitmap(Bitmap: TBitmap; PW, PH: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(PW, PH);
  SetStretchBltMode(Result.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(Result.Canvas.Handle, 0, 0, nil);
  Winapi.Windows.StretchBlt(Result.Canvas.Handle, 0, 0, PW, PH,
    Bitmap.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height, SRCCOPY);
end;

// Wynik z maski podgladu (2026-10-31): wypelnianie na surowych pikselach pelnego
// zdjecia przeciekalo cienkimi sciezkami w ciemne partie postaci i rozbijalo sie
// na peknieciach farby, a usredniony podglad tego nie mial - pokazywal co innego
// niz wynik. Teraz liczy sie ta sama procedura na tej samej kopii co w oknie,
// a na zdjeciu powstaje jej maska: wnetrze obszaru w calosci (peknienia tez),
// a w pasie jednej komorki podgladu przy granicy decyduja piksele zdjecia
// i tolerancja - krawedz bez schodkow wielkosci komorki.
procedure FloodFromPreview(Bitmap, Mask: TBitmap; Corner, Tolerance, SampleDist: Integer;
  var DirtyRect: TRect);
const
  cOutside = 0; cBandOut = 1; cBandIn = 2; cCore = 3;
var
  W, H, PW, PH, X, Y, I, SP, Cur, Tol, SR, SG, SB, C: Integer;
  MinX, MinY, MaxX, MaxY: Integer;
  Scale: Double;
  Pv, PvMask: TBitmap;
  PR: TRect;
  Rows: TRowPtrs;
  MaskRows: array of PByte;
  PvRows: array of PByte;
  Cls, Visited: array of Byte;
  XMap, YMap, Stack: array of Integer;
  Changed, Rem, AllRem, AnyRem: Boolean;

  function Fits(AX, AY: Integer): Boolean;
  begin
    Result := (Abs(Rows[AY][AX].R - SR) <= Tol) and
      (Abs(Rows[AY][AX].G - SG) <= Tol) and
      (Abs(Rows[AY][AX].B - SB) <= Tol);
  end;

  procedure TryPush(NX, NY: Integer);
  var
    K: Integer;
  begin
    K := NY * W + NX;
    if Visited[K] <> 0 then Exit;
    if (Cls[YMap[NY] * PW + XMap[NX]] <> cOutside) and Fits(NX, NY) then
    begin
      Visited[K] := 1;
      Stack[SP] := K;
      Inc(SP);
    end;
  end;

  procedure CheckNeighbour(AX, AY: Integer);
  begin
    if (AX < 0) or (AX >= PW) or (AY < 0) or (AY >= PH) then Exit;
    if PvRows[AY][AX] = 0 then
      AnyRem := True
    else
      AllRem := False;
  end;

begin
  DirtyRect := Rect(0, 0, 0, 0);
  if (Bitmap = nil) or (Mask = nil) then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if (Mask.Width <> W) or (Mask.Height <> H) then Exit;
  Tol := EnsureRange(Tolerance, 0, 255);

  Scale := PreviewScale(Bitmap);
  PW := Max(1, Round(W * Scale));
  PH := Max(1, Round(H * Scale));
  // zdjecie nie wieksze od podgladu: podglad to samo zdjecie
  if (PW = W) and (PH = H) then
  begin
    RemoveBackgroundFlood(Bitmap, Mask, Corner, Tol, SampleDist, cSampleBlock,
      SR, SG, SB, DirtyRect);
    Exit;
  end;

  // klasy komorek podgladu
  SetLength(Cls, PW * PH);
  Pv := CreatePreviewBitmap(Bitmap, PW, PH);
  PvMask := TBitmap.Create;
  try
    PvMask.PixelFormat := pf8bit;
    PvMask.SetSize(PW, PH);
    SetLength(PvRows, PH);
    for Y := 0 to PH - 1 do
    begin
      PvRows[Y] := PvMask.ScanLine[Y];
      FillChar(PvRows[Y]^, PW, 255);
    end;
    RemoveBackgroundFlood(Pv, PvMask, Corner, Tol, SampleDist,
      Max(1, Round(cSampleBlock * Scale)), SR, SG, SB, PR);
    for Y := 0 to PH - 1 do
      for X := 0 to PW - 1 do
      begin
        Rem := PvRows[Y][X] = 0;
        AllRem := True;
        AnyRem := False;
        CheckNeighbour(X - 1, Y);
        CheckNeighbour(X + 1, Y);
        CheckNeighbour(X, Y - 1);
        CheckNeighbour(X, Y + 1);
        if Rem and AllRem then
          Cls[Y * PW + X] := cCore
        else if Rem then
          Cls[Y * PW + X] := cBandIn
        else if AnyRem then
          Cls[Y * PW + X] := cBandOut
        else
          Cls[Y * PW + X] := cOutside;
      end;
  finally
    PvMask.Free;
    Pv.Free;
  end;

  SetLength(XMap, W);
  for X := 0 to W - 1 do
    XMap[X] := Int64(2 * X + 1) * PW div (2 * W);
  SetLength(YMap, H);
  for Y := 0 to H - 1 do
    YMap[Y] := Int64(2 * Y + 1) * PH div (2 * H);

  SetLength(Rows, H);
  SetLength(MaskRows, H);
  for Y := 0 to H - 1 do
  begin
    Rows[Y] := Bitmap.ScanLine[Y];
    MaskRows[Y] := Mask.ScanLine[Y];
  end;
  SetLength(Visited, W * H);
  FillChar(Visited[0], W * H, 0);
  SetLength(Stack, W * H);

  // start: cale wnetrze i piksele komorek usunietych w podgladzie, ktore mieszcza
  // sie w tolerancji; pas na zewnatrz obszaru tylko przez sasiedztwo z nimi
  SP := 0;
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      C := Cls[YMap[Y] * PW + XMap[X]];
      if (C = cCore) or ((C = cBandIn) and Fits(X, Y)) then
      begin
        I := Y * W + X;
        Visited[I] := 1;
        Stack[SP] := I;
        Inc(SP);
      end;
    end;

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
    if X > 0 then TryPush(X - 1, Y);
    if X + 1 < W then TryPush(X + 1, Y);
    if Y > 0 then TryPush(X, Y - 1);
    if Y + 1 < H then TryPush(X, Y + 1);
  end;

  if Changed then
    DirtyRect := Rect(MinX, MinY, MaxX + 1, MaxY + 1);
end;

procedure ApplyRemoveBackground(Bitmap, Mask: TBitmap; Corner, Tolerance, SampleDist: Integer;
  var DirtyRect: TRect);
var
  R: TRect;
begin
  FloodFromPreview(Bitmap, Mask, Corner, Tolerance, SampleDist, R);
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

function ShowUsunTloDlg(Bitmap, Mask: TBitmap; out Corner, Tolerance, SampleDist: Integer): Boolean;
var
  Dlg: TUsunTloDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
begin
  Corner := 0;
  Tolerance := 0;
  SampleDist := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TUsunTloDlg.Create(Application);
  try
    Scale := PreviewScale(Bitmap);
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FPvBlock := Max(1, Round(cSampleBlock * Scale));

    Scaled := CreatePreviewBitmap(Bitmap, pw, ph);
    try
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
    Dlg.tbDistance.Position := gUsunTloLastDist;
    Dlg.lblDistValue.Caption := IntToStr(Dlg.tbDistance.Position) + '%';
    Dlg.chkSample.Checked := gUsunTloLastSample;

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    Dlg.lblCorner.Top := Dlg.pboxPreview.Top + Dlg.pboxPreview.Height + Dlg.SectionGap;
    Dlg.rgCorner.Top := Dlg.lblCorner.Top + Dlg.lblCorner.Height + Dlg.CtrlGap;
    Dlg.rgCorner.Height := Dlg.Canvas.TextHeight('Wg') * 3 + 18;
    Dlg.chkSample.Top := Dlg.rgCorner.Top + Dlg.rgCorner.Height + Dlg.SectionGap;
    Dlg.chkSample.Height := Dlg.Canvas.TextHeight('Wg') + Dlg.CtrlGap;
    Dlg.lblDistance.Top := Dlg.chkSample.Top + Dlg.chkSample.Height + Dlg.CtrlGap;
    Dlg.tbDistance.Top := Dlg.lblDistance.Top + Dlg.lblDistance.Height + Dlg.CtrlGap;
    Dlg.lblDistValue.Top := Dlg.tbDistance.Top + Dlg.tbDistance.Height + Dlg.CtrlGap;
    Dlg.lblTolerance.Top := Dlg.lblDistValue.Top + Dlg.lblDistValue.Height + Dlg.SectionGap;
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
      SampleDist := Dlg.SampleDist;
      gUsunTloLastCorner := Corner;
      gUsunTloLastTolerance := Tolerance;
      gUsunTloLastSample := Dlg.chkSample.Checked;
      gUsunTloLastDist := Dlg.tbDistance.Position;
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

procedure TUsunTloDlg.chkSampleClick(Sender: TObject);
begin
  lblDistance.Enabled := chkSample.Checked;
  tbDistance.Enabled := chkSample.Checked;
  lblDistValue.Enabled := chkSample.Checked;
  ApplyPreview;
end;

procedure TUsunTloDlg.tbDistanceChange(Sender: TObject);
begin
  lblDistValue.Caption := IntToStr(tbDistance.Position) + '%';
  ApplyPreview;
end;

function TUsunTloDlg.SampleDist: Integer;
begin
  if chkSample.Checked then
    Result := tbDistance.Position
  else
    Result := 0;
end;

procedure TUsunTloDlg.ApplyPreview;
var
  R: TRect;
  Y, SR, SG, SB: Integer;
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
    tbTolerance.Position, SampleDist, FPvBlock, SR, SG, SB, R);
  DrawChecker(FWorkingPreview, FPvMask);
  pboxPreview.Invalidate;
end;

procedure TUsunTloDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH, Cx, Cy, Half: Integer;
  Scale: Double;
  DestRect, Block: TRect;
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
      // ramka w miejscu probki, dwukolorowa - widoczna na kazdym tle
      if chkSample.Checked then
      begin
        Block := SampleBlockRect(SrcW, SrcH, rgCorner.ItemIndex,
          tbDistance.Position, FPvBlock);
        Cx := DestRect.Left + Round((Block.Left + Block.Right) / 2 * Scale);
        Cy := DestRect.Top + Round((Block.Top + Block.Bottom) / 2 * Scale);
        Half := Max(2, TextHeight('W') div 3);
        Brush.Style := bsClear;
        Pen.Color := clBlack;
        Rectangle(Cx - Half - 1, Cy - Half - 1, Cx + Half + 2, Cy + Half + 2);
        Pen.Color := clWhite;
        Rectangle(Cx - Half, Cy - Half, Cx + Half + 1, Cy + Half + 1);
        Brush.Style := bsSolid;
      end;
    end;
  end;
end;

initialization

  gUsunTloLastCorner := 0;
  gUsunTloLastTolerance := 32;
  gUsunTloLastSample := False;
  gUsunTloLastDist := 5;

end.