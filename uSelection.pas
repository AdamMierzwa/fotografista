unit uSelection;

interface

uses
  Winapi.Windows, System.Types, System.Math, System.Classes, System.SysUtils,
  Vcl.Graphics, Vcl.ExtCtrls, Vcl.Controls;

type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;
  THitHandle = (
    hhNone,
    hhTL, hhTM, hhTR,
    hhML, hhMR,
    hhBL, hhBM, hhBR,
    hhMove
  );

  THitShape = (
    hsRect,
    hsEllipse,
    hsLasso,
    hsWand
  );

  // Tryb wyświetlania zaznaczenia: obrys (marching ants) albo podgląd jak
  // quick mask (wypełnienie kształtu). Tylko reprezentacja widoku - żadne
  // warstwy, maska danych pojawi się dopiero z narzędziami lasso/różdżka.
  TSelectionView = (
    svOutline,
    svMask
  );

  TSelection = class
  private
    FActive: Boolean;
    FShape: THitShape;
    FView: TSelectionView;
    FX1, FY1, FX2, FY2: Double;
    FDashOffset: Integer;
    FTimer: TTimer;
    FOnChanged: TNotifyEvent;
    FOnRepaintReq: TNotifyEvent;
    FRegion: TBitmap;              // hsLasso/hsWand: 1 B/px, <>0 = zaznaczone
    FRegionPts: TArray<TPoint>;    // bieżąca ścieżka lassa (koord. obrazu)
    FMoveActive: Boolean;          // trwa przesuwanie regionu (podgląd)
    FMoveDx, FMoveDy: Integer;     // bieżąca delta przesuwania (koord. obrazu)
    FMoveBaseX1, FMoveBaseY1, FMoveBaseX2, FMoveBaseY2: Double;
    FMoveImgW, FMoveImgH: Integer;
    FSeedX, FSeedY: Integer;       // punkt zalewania - do ponownego przeliczenia z tolerancji
    procedure TimerTick(Sender: TObject);
    function RegionAt(Px, Py: Double): Boolean;
    procedure DrawRegionFill(Canvas: TCanvas; Zoom: Double; OffsetX, OffsetY: Integer);
    procedure DrawRegionOutline(Canvas: TCanvas; Zoom: Double; OffsetX, OffsetY: Integer);
    function RegionFromMask(const Mask: TBitmap; Zoom: Double; OffsetX, OffsetY: Integer): HRGN;
    function GetW: Double;
    function GetH: Double;
    function GetLeft: Double;
    function GetTop: Double;
    function GetRight: Double;
    function GetBottom: Double;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetRect(X1, Y1, X2, Y2: Double);
    function HitTest(Px, Py: Double; Zoom: Double): THitHandle;
    function CursorForHandle(Handle: THitHandle): TCursor;
    procedure ResizeHandle(Handle: THitHandle; Nx, Ny: Double; Shift: TShiftState);
    procedure SetSizeKeepTopLeft(W, H: Double; ImgW, ImgH: Integer);
    procedure SetSizeCentered(W, H: Double; ImgW, ImgH: Integer);
    function Contains(Px, Py: Double): Boolean;
    function ClampedRect(ImgW, ImgH: Integer): TRect;
    function IsValid: Boolean;
    procedure SetRegionFromPolygon(const Pts: array of TPoint; ImgW, ImgH: Integer);
    procedure ClearRegion;
    function HasRegion: Boolean;
    procedure SetRegionFromSeed(Bitmap: TBitmap; X, Y, Tolerance: Integer);
    function HasValidSeed: Boolean;
    procedure RecomputeFromSeed(Bitmap: TBitmap; Tolerance: Integer);
    procedure BeginRegionMove;
    procedure PreviewRegionMove(Dx, Dy: Integer);
    procedure CommitRegionMove;
    procedure CancelRegionMove;
    procedure Draw(Canvas: TCanvas; Zoom: Double; OffsetX, OffsetY: Integer;
      ShowHandles: Boolean; ImgW: Integer = 0; ImgH: Integer = 0);
    property Active: Boolean read FActive write FActive;
    property Shape: THitShape read FShape write FShape;
    property View: TSelectionView read FView write FView;
    property X1: Double read FX1;
    property Y1: Double read FY1;
    property X2: Double read FX2;
    property Y2: Double read FY2;
    property W: Double read GetW;
    property H: Double read GetH;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
    property OnRepaintReq: TNotifyEvent read FOnRepaintReq write FOnRepaintReq;
  end;

function SelectionCrop(Bitmap: TBitmap; const Sel: TSelection): TBitmap;

implementation

{ helpers }

procedure MarchingAntsRect
(Canvas: TCanvas; const R: TRect; Offset: Integer);
var
  DashLen: Integer;
  Phase, X, Y, Rem: Integer;
  Drawing: Boolean;
begin
  // white base
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(R);

  // black dashes on top
  DashLen := 6;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  // Top edge
  Phase := Offset mod (DashLen * 2);
  if Phase >= DashLen then Phase := Phase - DashLen;
  Drawing := Phase < DashLen;
  X := R.Left + Phase;
  Rem := DashLen - Phase;
  while X < R.Right do
  begin
    if Drawing then
    begin
      Canvas.MoveTo(X, R.Top);
      X := Min(X + Rem, R.Right);
      Canvas.LineTo(X, R.Top);
    end;
    Inc(X, DashLen);
    Drawing := not Drawing;
    Rem := DashLen;
  end;

  // Bottom edge
  Phase := (Offset + (R.Right - R.Left)) mod (DashLen * 2);
  if Phase >= DashLen then Phase := Phase - DashLen;
  Drawing := Phase < DashLen;
  X := R.Left + Phase;
  Rem := DashLen - Phase;
  while X < R.Right do
  begin
    if Drawing then
    begin
      Canvas.MoveTo(X, R.Bottom - 1);
      X := Min(X + Rem, R.Right);
      Canvas.LineTo(X, R.Bottom - 1);
    end;
    Inc(X, DashLen);
    Drawing := not Drawing;
    Rem := DashLen;
  end;

  // Left edge
  Phase := (Offset + (R.Bottom - R.Top)) mod (DashLen * 2);
  if Phase >= DashLen then Phase := Phase - DashLen;
  Drawing := Phase < DashLen;
  Y := R.Top + Phase;
  Rem := DashLen - Phase;
  while Y < R.Bottom do
  begin
    if Drawing then
    begin
      Canvas.MoveTo(R.Left, Y);
      Y := Min(Y + Rem, R.Bottom);
      Canvas.LineTo(R.Left, Y);
    end;
    Inc(Y, DashLen);
    Drawing := not Drawing;
    Rem := DashLen;
  end;

  // Right edge
  Phase := (Offset + (R.Bottom - R.Top) + (R.Right - R.Left)) mod (DashLen * 2);
  if Phase >= DashLen then Phase := Phase - DashLen;
  Drawing := Phase < DashLen;
  Y := R.Top + Phase;
  Rem := DashLen - Phase;
  while Y < R.Bottom do
  begin
    if Drawing then
    begin
      Canvas.MoveTo(R.Right - 1, Y);
      Y := Min(Y + Rem, R.Bottom);
      Canvas.LineTo(R.Right - 1, Y);
    end;
    Inc(Y, DashLen);
    Drawing := not Drawing;
    Rem := DashLen;
  end;
end;

procedure MarchingAntsEllipse
(Canvas: TCanvas; const R: TRect; Offset: Integer);
var
  DashLen: Integer;
  N, I, J, K: Integer;
  CX, CY, RX, RY: Integer;
  Px, Py, PrevX, PrevY, CurX, CurY: Integer;
  Angle, Step, SegLen, S: Double;
  On, InDash: Boolean;
begin
  // white base
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  Canvas.Ellipse(R);

  DashLen := 6;
  CX := (R.Left + R.Right) div 2;
  CY := (R.Top + R.Bottom) div 2;
  RX := (R.Right - R.Left) div 2;
  RY := (R.Bottom - R.Top) div 2;
  if (RX <= 0) or (RY <= 0) then Exit;

  // Punkty obwodu gęste (~krok 4px), czarne kreski nakładane na beli
  // z przesunięciem fazy FDashOffset - ten sam wzorzec co MarchingAntsRect.
  N := Max(96, Round(2.0 * Pi * Max(RX, RY) / 4.0));
  Step := 2.0 * Pi / N;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  PrevX := CX + RX;
  PrevY := CY;
  S := 0.0;
  InDash := False;
  for I := 1 to N do
  begin
    Angle := I * Step;
    Px := CX + Round(RX * Cos(Angle));
    Py := CY + Round(RY * Sin(Angle));
    SegLen := Hypot(Px - PrevX, Py - PrevY);
    K := Max(1, Round(SegLen));
    for J := 1 to K do
    begin
      S := S + SegLen / K;
      CurX := PrevX + Round((Px - PrevX) * J / K);
      CurY := PrevY + Round((Py - PrevY) * J / K);
      On := (Round(Offset + S) mod (DashLen * 2)) < DashLen;
      if On then
      begin
        if not InDash then Canvas.MoveTo(CurX, CurY);
        InDash := True;
      end
      else
      begin
        if InDash then Canvas.LineTo(CurX, CurY);
        InDash := False;
      end;
    end;
    PrevX := Px;
    PrevY := Py;
  end;
  if InDash then Canvas.LineTo(PrevX, PrevY);
end;

procedure MarchingAntsPolyline
(Canvas: TCanvas; const Pts: array of TPoint;
  Zoom: Double; OffsetX, OffsetY, DashOffset, PtDx, PtDy: Integer);
var
  DashLen, N, I, J, K, Px, Py, PrevX, PrevY: Integer;
  SP: TArray<TPoint>;
  SegLen, S: Double;
  On, InDash: Boolean;
begin
  N := Length(Pts);
  if N < 2 then Exit;
  DashLen := 6;

  SetLength(SP, N + 1);
  for I := 0 to N - 1 do
    SP[I] := System.Types.Point(
      OffsetX + Round((Pts[I].X + PtDx) * Zoom),
      OffsetY + Round((Pts[I].Y + PtDy) * Zoom));
  SP[N] := SP[0];

  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsClear;

  // white base (zamknięty wielokąt)
  Canvas.Pen.Color := clWhite;
  Canvas.Polyline(SP);

  // black dashes na wierzchu
  Canvas.Pen.Color := clBlack;
  S := 0.0;
  InDash := False;
  for I := 0 to N - 1 do
  begin
    PrevX := SP[I].X;
    PrevY := SP[I].Y;
    SegLen := Hypot(SP[I + 1].X - PrevX, SP[I + 1].Y - PrevY);
    K := Max(1, Round(SegLen));
    for J := 1 to K do
    begin
      S := S + SegLen / K;
      Px := PrevX + Round((SP[I + 1].X - PrevX) * J / K);
      Py := PrevY + Round((SP[I + 1].Y - PrevY) * J / K);
      On := (Round(DashOffset + S) mod (DashLen * 2)) < DashLen;
      if On then
      begin
        if not InDash then Canvas.MoveTo(Px, Py);
        InDash := True;
      end
      else
      begin
        if InDash then Canvas.LineTo(Px, Py);
        InDash := False;
      end;
    end;
  end;
  if InDash then Canvas.LineTo(SP[N].X, SP[N].Y);
end;

procedure DrawHandle(Canvas: TCanvas; CX, CY, Size: Integer);
begin
  Canvas.Pen.Style := psClear;
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(Rect(CX - Size div 2, CY - Size div 2,
    CX - Size div 2 + Size, CY - Size div 2 + Size));
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(CX - Size div 2, CY - Size div 2,
    CX - Size div 2 + Size, CY - Size div 2 + Size);
end;

procedure BuildFillMask(Src: TBitmap; SX, SY, Tol: Integer;
  var Mask: TArray<Byte>; out W, H, MinX, MinY, MaxX, MaxY: Integer);
var
  I, Row, SP, Cap, Cur, NX, NY: Integer;
  SR, SG, SB: Byte;
  Rows: array of PRGBTripleArray;
  Visited: array of Byte;
  Stack: array of Integer;
begin
  W := 0; H := 0;
  MinX := 0; MinY := 0; MaxX := 0; MaxY := 0;
  Mask := nil;
  if Src = nil then Exit;
  W := Src.Width;
  H := Src.Height;
  if (W <= 0) or (H <= 0) then Exit;
  if (SX < 0) or (SY < 0) or (SX >= W) or (SY >= H) then Exit;

  // Wiersze Zachowujemy jako wskaźniki ScanLine (bez kopii) — zalewanie
  // wykonuje się synchronicznie w głównym wątku, więc obraz nie może być
  // podmieniony/zwolniony w trakcie przetwarzania.
  SetLength(Rows, H);
  for I := 0 to H - 1 do
    Rows[I] := Src.ScanLine[I];

  SR := Rows[SY][SX].rgbtRed;
  SG := Rows[SY][SX].rgbtGreen;
  SB := Rows[SY][SX].rgbtBlue;

  SetLength(Mask, W * H);
  FillChar(Mask[0], W * H, 0);
  SetLength(Visited, W * H);
  FillChar(Visited[0], W * H, 0);

  Cap := 4096;
  SetLength(Stack, Cap);
  SP := 0;
  MinX := SX; MinY := SY; MaxX := SX; MaxY := SY;
  Row := SY * W + SX;
  Stack[SP] := Row;
  Inc(SP);
  Visited[Row] := 1;
  Mask[Row] := 1;

  while SP > 0 do
  begin
    Dec(SP);
    Cur := Stack[SP];
    NX := Cur mod W;
    NY := Cur div W;
    if NX > 0 then
    begin
      Row := NY * W + NX - 1;
      if Visited[Row] = 0 then
      begin
        Visited[Row] := 1;
        if (Abs(Rows[NY][NX - 1].rgbtRed - SR) <= Tol) and
           (Abs(Rows[NY][NX - 1].rgbtGreen - SG) <= Tol) and
           (Abs(Rows[NY][NX - 1].rgbtBlue - SB) <= Tol) then
        begin
          Mask[Row] := 1;
          if NX - 1 < MinX then MinX := NX - 1;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          if SP = Cap then
          begin
            Cap := Cap * 2;
            SetLength(Stack, Cap);
          end;
          Stack[SP] := Row;
          Inc(SP);
        end;
      end;
    end;
    if NX < W - 1 then
    begin
      Row := NY * W + NX + 1;
      if Visited[Row] = 0 then
      begin
        Visited[Row] := 1;
        if (Abs(Rows[NY][NX + 1].rgbtRed - SR) <= Tol) and
           (Abs(Rows[NY][NX + 1].rgbtGreen - SG) <= Tol) and
           (Abs(Rows[NY][NX + 1].rgbtBlue - SB) <= Tol) then
        begin
          Mask[Row] := 1;
          if NX + 1 > MaxX then MaxX := NX + 1;
          if NY < MinY then MinY := NY;
          if NY > MaxY then MaxY := NY;
          if SP = Cap then
          begin
            Cap := Cap * 2;
            SetLength(Stack, Cap);
          end;
          Stack[SP] := Row;
          Inc(SP);
        end;
      end;
    end;
    if NY > 0 then
    begin
      Row := (NY - 1) * W + NX;
      if Visited[Row] = 0 then
      begin
        Visited[Row] := 1;
        if (Abs(Rows[NY - 1][NX].rgbtRed - SR) <= Tol) and
           (Abs(Rows[NY - 1][NX].rgbtGreen - SG) <= Tol) and
           (Abs(Rows[NY - 1][NX].rgbtBlue - SB) <= Tol) then
        begin
          Mask[Row] := 1;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY - 1 < MinY then MinY := NY - 1;
          if SP = Cap then
          begin
            Cap := Cap * 2;
            SetLength(Stack, Cap);
          end;
          Stack[SP] := Row;
          Inc(SP);
        end;
      end;
    end;
    if NY < H - 1 then
    begin
      Row := (NY + 1) * W + NX;
      if Visited[Row] = 0 then
      begin
        Visited[Row] := 1;
        if (Abs(Rows[NY + 1][NX].rgbtRed - SR) <= Tol) and
           (Abs(Rows[NY + 1][NX].rgbtGreen - SG) <= Tol) and
           (Abs(Rows[NY + 1][NX].rgbtBlue - SB) <= Tol) then
        begin
          Mask[Row] := 1;
          if NX < MinX then MinX := NX;
          if NX > MaxX then MaxX := NX;
          if NY + 1 > MaxY then MaxY := NY + 1;
          if SP = Cap then
          begin
            Cap := Cap * 2;
            SetLength(Stack, Cap);
          end;
          Stack[SP] := Row;
          Inc(SP);
        end;
      end;
    end;
  end;
end;

{ TSelection }

constructor TSelection.Create;
begin
  inherited;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 150;
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;
  FDashOffset := 0;
  FShape := hsRect;
  FView := svOutline;
  Clear;
end;

destructor TSelection.Destroy;
begin
  FRegion.Free;
  FTimer.Free;
  inherited;
end;

procedure TSelection.TimerTick(Sender: TObject);
begin
  Inc(FDashOffset);
  if Assigned(FOnRepaintReq) then FOnRepaintReq(Self);
end;

procedure TSelection.Clear;
begin
  FActive := False;
  FX1 := -1; FY1 := -1;
  FX2 := -1; FY2 := -1;
  ClearRegion;
  FMoveActive := False;
  FMoveDx := 0; FMoveDy := 0;
  FSeedX := -1; FSeedY := -1;
  if FTimer <> nil then FTimer.Enabled := False;
end;

procedure TSelection.SetRect(X1, Y1, X2, Y2: Double);
begin
  FX1 := X1; FY1 := Y1;
  FX2 := X2; FY2 := Y2;
  if (GetW > 0) and (GetH > 0) then
    FTimer.Enabled := FActive;
end;

function TSelection.GetLeft: Double; begin Result := Min(FX1, FX2); end;
function TSelection.GetTop: Double; begin Result := Min(FY1, FY2); end;
function TSelection.GetRight: Double; begin Result := Max(FX1, FX2); end;
function TSelection.GetBottom: Double; begin Result := Max(FY1, FY2); end;
function TSelection.GetW: Double; begin Result := Abs(FX2 - FX1); end;
function TSelection.GetH: Double; begin Result := Abs(FY2 - FY1); end;

function TSelection.IsValid: Boolean;
begin
  Result := FActive and (GetW > 0) and (GetH > 0);
end;

function TSelection.HitTest(Px, Py: Double; Zoom: Double): THitHandle;
var
  L, T, R, B, MidX, MidY: Double;
  Thr: Double;
begin
  Result := hhNone;
  if not FActive then Exit;
  L := GetLeft; T := GetTop;
  R := GetRight; B := GetBottom;
  MidX := (L + R) / 2;
  MidY := (T + B) / 2;
  Thr := 6.0 / Zoom;

  // corners
  if (Abs(Px - L) <= Thr) and (Abs(Py - T) <= Thr) then Exit(hhTL);
  if (Abs(Px - R) <= Thr) and (Abs(Py - T) <= Thr) then Exit(hhTR);
  if (Abs(Px - L) <= Thr) and (Abs(Py - B) <= Thr) then Exit(hhBL);
  if (Abs(Px - R) <= Thr) and (Abs(Py - B) <= Thr) then Exit(hhBR);
  // midpoints
  if (Abs(Px - MidX) <= Thr) and (Abs(Py - T) <= Thr) then Exit(hhTM);
  if (Abs(Px - MidX) <= Thr) and (Abs(Py - B) <= Thr) then Exit(hhBM);
  if (Abs(Px - L) <= Thr) and (Abs(Py - MidY) <= Thr) then Exit(hhML);
  if (Abs(Px - R) <= Thr) and (Abs(Py - MidY) <= Thr) then Exit(hhMR);
  // body — dla elipsy tylko wnętrze (prostokąt bounding box pozostaje dla uchwytów)
  if FShape = hsEllipse then
  begin
    if Contains(Px, Py) then Exit(hhMove);
  end
  else if (Px >= L) and (Px <= R) and (Py >= T) and (Py <= B) then
    Exit(hhMove);
end;

function TSelection.CursorForHandle(Handle: THitHandle): TCursor;
begin
  case Handle of
    hhTL: Result := crSizeNWSE;
    hhTM: Result := crSizeNS;
    hhTR: Result := crSizeNESW;
    hhML: Result := crSizeWE;
    hhMR: Result := crSizeWE;
    hhBL: Result := crSizeNESW;
    hhBM: Result := crSizeNS;
    hhBR: Result := crSizeNWSE;
    hhMove: Result := crSizeAll;
  else
    Result := crDefault;
  end;
end;

procedure TSelection.SetSizeKeepTopLeft(W, H: Double; ImgW, ImgH: Integer);
begin
  if FX1 < 0 then FX1 := Max(0.0, (ImgW - W) / 2.0);
  if FY1 < 0 then FY1 := Max(0.0, (ImgH - H) / 2.0);
  FX2 := FX1 + W; FY2 := FY1 + H;
  FActive := True;
  FTimer.Enabled := True;
end;

procedure TSelection.SetSizeCentered(W, H: Double; ImgW, ImgH: Integer);
begin
  FX1 := Max(0.0, (ImgW - W) / 2.0);
  FY1 := Max(0.0, (ImgH - H) / 2.0);
  FX2 := FX1 + W; FY2 := FY1 + H;
  FActive := True;
  FTimer.Enabled := True;
end;

procedure TSelection.ResizeHandle(Handle: THitHandle; Nx, Ny: Double; Shift: TShiftState);
var
  L, T, R, B: Double;
begin
  L := GetLeft; T := GetTop;
  R := GetRight; B := GetBottom;

  case Handle of
    hhTL: begin FX1 := R; FY1 := B; FX2 := Nx; FY2 := Ny; end;
    hhTM: begin FY1 := B; FY2 := Ny; end;
    hhTR: begin FX1 := L; FY1 := B; FX2 := Nx; FY2 := Ny; end;
    hhML: begin FX1 := R; FX2 := Nx; end;
    hhMR: begin FX1 := L; FX2 := Nx; end;
    hhBL: begin FX1 := R; FY1 := T; FX2 := Nx; FY2 := Ny; end;
    hhBM: begin FY1 := T; FY2 := Ny; end;
    hhBR: begin FX1 := L; FY1 := T; FX2 := Nx; FY2 := Ny; end;
  end;

  if ssShift in Shift then
  begin
    // constrain to square
    // (keep the larger dimension)
  end;
end;

function TSelection.Contains(Px, Py: Double): Boolean;
var
  Rx, Ry: Double;
begin
  Result := False;
  if not FActive then Exit;
  if FShape in [hsLasso, hsWand] then
  begin
    Result := RegionAt(Px, Py);
    Exit;
  end;
  if FShape = hsEllipse then
  begin
    Rx := GetW / 2;
    Ry := GetH / 2;
    if (Rx <= 0) or (Ry <= 0) then Exit;
    Result := Sqr((Px - (GetLeft + GetRight) / 2) / Rx) +
      Sqr((Py - (GetTop + GetBottom) / 2) / Ry) <= 1.0;
  end
  else
    Result := (Px >= GetLeft) and (Px <= GetRight)
      and (Py >= GetTop) and (Py <= GetBottom);
end;

function TSelection.ClampedRect(ImgW, ImgH: Integer): TRect;
var
  L, T, R, B: Integer;
begin
  L := Round(GetLeft);
  T := Round(GetTop);
  R := Round(GetRight);
  B := Round(GetBottom);

  if (R < L) or (B < T) then
  begin
    // Odwrócone/puste zaznaczenie — brak obszaru do zastosowania
    Result := Rect(0, 0, -1, -1);
    Exit;
  end;

  // Przycięcie do granic bufora (współrzędne włączne: 0..ImgW-1, 0..ImgH-1)
  if L < 0 then L := 0;
  if T < 0 then T := 0;
  if R > ImgW - 1 then R := ImgW - 1;
  if B > ImgH - 1 then B := ImgH - 1;

  if (L > R) or (T > B) then
  begin
    // Zaznaczenie całkowicie poza krawędzią obrazu — brak przecięcia
    Result := Rect(0, 0, -1, -1);
  end
  else
    Result := Rect(L, T, R, B);
end;

{ --- Region (lasso / różdżka) --- }

procedure TSelection.ClearRegion;
begin
  FRegion.Free;
  FRegion := nil;
  SetLength(FRegionPts, 0);
end;

function TSelection.HasRegion: Boolean;
begin
  Result := FRegion <> nil;
end;

function TSelection.RegionAt(Px, Py: Double): Boolean;
var
  X, Y: Integer;
begin
  Result := False;
  if FRegion = nil then Exit;
  // Podczas przesuwania region nie jest jeszcze przerasteryzowany — odejmujemy
  // bieżącą deltę, by Contains/HitTest widziały region w nowym położeniu.
  if FMoveActive then
  begin
    Px := Px - FMoveDx;
    Py := Py - FMoveDy;
  end;
  X := Floor(Px);
  Y := Floor(Py);
  if (X < 0) or (Y < 0) or (X >= FRegion.Width) or (Y >= FRegion.Height) then Exit;
  Result := PByte(FRegion.ScanLine[Y])[X] <> 0;
end;

procedure TSelection.BeginRegionMove;
begin
  if FRegion = nil then Exit;
  FMoveActive := True;
  FMoveDx := 0;
  FMoveDy := 0;
  FMoveBaseX1 := FX1;
  FMoveBaseY1 := FY1;
  FMoveBaseX2 := FX2;
  FMoveBaseY2 := FY2;
  FMoveImgW := FRegion.Width;
  FMoveImgH := FRegion.Height;
end;

procedure TSelection.PreviewRegionMove(Dx, Dy: Integer);
begin
  if not FMoveActive then Exit;
  FMoveDx := Dx;
  FMoveDy := Dy;
  FX1 := FMoveBaseX1 + Dx;
  FY1 := FMoveBaseY1 + Dy;
  FX2 := FMoveBaseX2 + Dx;
  FY2 := FMoveBaseY2 + Dy;
end;

procedure TSelection.CommitRegionMove;
var
  Pts: TArray<TPoint>;
  I, ImgW, ImgH: Integer;
begin
  if not FMoveActive then Exit;
  FMoveActive := False;
  ImgW := FMoveImgW;
  ImgH := FMoveImgH;
  if (FMoveDx = 0) and (FMoveDy = 0) then
  begin
    FMoveDx := 0;
    FMoveDy := 0;
    Exit;
  end;
  SetLength(Pts, Length(FRegionPts));
  for I := 0 to High(FRegionPts) do
  begin
    Pts[I].X := FRegionPts[I].X + FMoveDx;
    Pts[I].Y := FRegionPts[I].Y + FMoveDy;
  end;
  FMoveDx := 0;
  FMoveDy := 0;
  if Length(Pts) >= 3 then
    SetRegionFromPolygon(Pts, ImgW, ImgH)
  else
    Clear;
end;

procedure TSelection.CancelRegionMove;
begin
  if not FMoveActive then Exit;
  FX1 := FMoveBaseX1;
  FY1 := FMoveBaseY1;
  FX2 := FMoveBaseX2;
  FY2 := FMoveBaseY2;
  FMoveActive := False;
  FMoveDx := 0;
  FMoveDy := 0;
end;

procedure TSelection.SetRegionFromPolygon(const Pts: array of TPoint; ImgW, ImgH: Integer);
var
  X, Y: Integer;
  Tmp: TBitmap;
  TmpRow, MaskRow: PByte;
  MinX, MinY, MaxX, MaxY: Integer;
begin
  Clear;
  if (ImgW <= 0) or (ImgH <= 0) then Exit;
  if Length(Pts) < 3 then Exit;

  // Rasteryzacja zamkniętego wielokąta do tymczasowej bitmapy 24-bit (GDI fill),
  // potem progowanie jasności do maski 1 B/px. Kolor tła = czarny, wypełnienie
  // = biały, więc test "piksel <> 0" jednoznacznie rozstrzyga przynależność.
  Tmp := TBitmap.Create;
  Tmp.PixelFormat := pf24bit;
  Tmp.SetSize(ImgW, ImgH);
  Tmp.Canvas.Brush.Style := bsSolid;
  Tmp.Canvas.Brush.Color := clBlack;
  Tmp.Canvas.FillRect(Rect(0, 0, ImgW, ImgH));
  Tmp.Canvas.Brush.Color := clWhite;
  Tmp.Canvas.Pen.Color := clWhite;
  Tmp.Canvas.Pen.Style := psSolid;
  Tmp.Canvas.Pen.Width := 1;
  Tmp.Canvas.Polygon(Pts);

  FRegion := TBitmap.Create;
  FRegion.PixelFormat := pf8bit;
  FRegion.SetSize(ImgW, ImgH);
  MinX := ImgW; MinY := ImgH; MaxX := -1; MaxY := -1;
  for Y := 0 to ImgH - 1 do
  begin
    TmpRow := Tmp.ScanLine[Y];
    MaskRow := FRegion.ScanLine[Y];
    for X := 0 to ImgW - 1 do
      if TmpRow[X * 3] <> 0 then
      begin
        MaskRow[X] := 255;
        if X < MinX then MinX := X;
        if X > MaxX then MaxX := X;
        if Y < MinY then MinY := Y;
        if Y > MaxY then MaxY := Y;
      end
      else
        MaskRow[X] := 0;
  end;
  Tmp.Free;

  if MaxX < 0 then
  begin
    ClearRegion;
    Exit;
  end;
  FX1 := MinX; FY1 := MinY;
  FX2 := MaxX + 1; FY2 := MaxY + 1;
  SetLength(FRegionPts, Length(Pts));
  if Length(Pts) > 0 then
    Move(Pts[0], FRegionPts[0], Length(Pts) * SizeOf(TPoint));
  FActive := True;
  FTimer.Enabled := True;
end;

procedure TSelection.SetRegionFromSeed(Bitmap: TBitmap; X, Y, Tolerance: Integer);
var
  W, H, Row, X2: Integer;
  X1r, Y1r, X2r, Y2r: Integer;
  Mask: TArray<Byte>;
  NeedCreate: Boolean;
  DstRow: PByte;
begin
  if (Bitmap = nil) or (Tolerance < 0) then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W <= 0) or (H <= 0) then Exit;
  if (X < 0) or (Y < 0) or (X >= W) or (Y >= H) then Exit;
  Clear;

  FSeedX := X;
  FSeedY := Y;

  // Synchroniczne zalewanie - ten sam algorytm co różdżka po kliknięciu:
  // maska 1 B/px z bboxem. Nic asynchronicznego - wynik gotowy natychmiast.
  BuildFillMask(Bitmap, X, Y, Tolerance, Mask, W, H, X1r, Y1r, X2r, Y2r);
  if (Length(Mask) < W * H) or (X2r < X1r) or (Y2r < Y1r) then
  begin
    Clear;
    Exit;
  end;

  NeedCreate := (FRegion = nil) or (FRegion.Width <> W) or (FRegion.Height <> H);
  if NeedCreate then
  begin
    FRegion.Free;
    FRegion := TBitmap.Create;
    FRegion.PixelFormat := pf8bit;
    FRegion.SetSize(W, H);
  end;
  for Row := 0 to H - 1 do
  begin
    DstRow := FRegion.ScanLine[Row];
    for X2 := 0 to W - 1 do
    begin
      if Mask[Row * W + X2] <> 0 then
        DstRow[X2] := 255
      else
        DstRow[X2] := 0;
    end;
  end;

  SetLength(FRegionPts, 0);
  FX1 := X1r;
  FY1 := Y1r;
  FX2 := X2r + 1;
  FY2 := Y2r + 1;
  FActive := True;
  FMoveActive := False;
  FTimer.Enabled := False;

  if Assigned(FOnChanged) then FOnChanged(Self);
  if Assigned(FOnRepaintReq) then FOnRepaintReq(Self);
end;

function TSelection.HasValidSeed: Boolean;
begin
  Result := (FSeedX >= 0) and (FSeedY >= 0);
end;

procedure TSelection.RecomputeFromSeed(Bitmap: TBitmap; Tolerance: Integer);
begin
  // Ponowne zalewanie od zapamiętanego punktu - bez nowego kliknięcia.
  // Omija walkę z wątkami: wykonuje się synchronicznie i natychmiast.
  if not HasValidSeed then Exit;
  SetRegionFromSeed(Bitmap, FSeedX, FSeedY, Tolerance);
end;

function TSelection.RegionFromMask(const Mask: TBitmap; Zoom: Double; OffsetX, OffsetY: Integer): HRGN;
var
  W, H, Y, X, RunStart, N, Cap: Integer;
  P: PByte;
  Rects: array of TRect;
  Data: PRgnData;
  BufSize: Integer;
  L, T, R, B: Integer;
begin
  Result := 0;
  if Mask = nil then Exit;
  W := Mask.Width;
  H := Mask.Height;
  if (W <= 0) or (H <= 0) then Exit;

  Cap := 256;
  N := 0;
  SetLength(Rects, Cap);
  L := MaxInt; T := MaxInt; R := -MaxInt; B := -MaxInt;

  for Y := 0 to H - 1 do
  begin
    P := Mask.ScanLine[Y];
    RunStart := -1;
    X := 0;
    while X <= W do
    begin
      if (X < W) and (P[X] <> 0) then
      begin
        if RunStart < 0 then RunStart := X;
      end
      else if RunStart >= 0 then
      begin
        if N >= Cap then
        begin
          Cap := Cap * 2;
          SetLength(Rects, Cap);
        end;
        Rects[N] := Rect(
          OffsetX + Round(RunStart * Zoom),
          OffsetY + Round(Y * Zoom),
          OffsetX + Round(X * Zoom),
          OffsetY + Round((Y + 1) * Zoom));
        if Rects[N].Left < L then L := Rects[N].Left;
        if Rects[N].Top < T then T := Rects[N].Top;
        if Rects[N].Right > R then R := Rects[N].Right;
        if Rects[N].Bottom > B then B := Rects[N].Bottom;
        Inc(N);
        RunStart := -1;
      end;
      Inc(X);
    end;
  end;

  if N = 0 then Exit;

  BufSize := SizeOf(TRgnDataHeader) + N * SizeOf(TRect);
  GetMem(Data, BufSize);
  try
    Data.rdh.dwSize := SizeOf(TRgnDataHeader);
    Data.rdh.iType := RDH_RECTANGLES;
    Data.rdh.nCount := N;
    Data.rdh.nRgnSize := N * SizeOf(TRect);
    Data.rdh.rcBound := Rect(L, T, R, B);
    Move(Rects[0], Data.Buffer, N * SizeOf(TRect));
    Result := ExtCreateRegion(nil, BufSize, Data^);
  finally
    FreeMem(Data);
  end;
end;

procedure TSelection.DrawRegionOutline(Canvas: TCanvas; Zoom: Double; OffsetX, OffsetY: Integer);
var
  Rgn: HRGN;
begin
  if FRegion = nil then Exit;
  Rgn := RegionFromMask(FRegion, Zoom, OffsetX, OffsetY);
  if Rgn = 0 then Exit;
  // Kontrastowa kreska widoczna na każdym tle: gruby biały rąbek pod spodem,
  // na nim czarna linia (wzorowane na white-base marching ants prostokąta).
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clWhite;
  FrameRgn(Canvas.Handle, Rgn, Canvas.Brush.Handle, 2, 2);
  Canvas.Brush.Color := clBlack;
  FrameRgn(Canvas.Handle, Rgn, Canvas.Brush.Handle, 1, 1);
  Canvas.Brush.Style := bsClear;
  DeleteObject(Rgn);
end;

procedure TSelection.DrawRegionFill(Canvas: TCanvas; Zoom: Double; OffsetX, OffsetY: Integer);
var
  L, T, R, B, I, N, Saved: Integer;
  SP: TArray<TPoint>;
  Rgn: HRGN;
begin
  if FRegion = nil then Exit;
  // Bbox w pikselach ekranu (klip i tak zatnie do kształtu).
  L := OffsetX + Trunc(Min(FX1, FX2) * Zoom);
  T := OffsetY + Trunc(Min(FY1, FY2) * Zoom);
  R := OffsetX + Trunc(Max(FX1, FX2) * Zoom);
  B := OffsetY + Trunc(Max(FY1, FY2) * Zoom);
  if (R <= L) or (B <= T) then Exit;

  N := Length(FRegionPts);
  if N >= 3 then
  begin
    SetLength(SP, N);
    for I := 0 to N - 1 do
      SP[I] := System.Types.Point(
        OffsetX + Round((FRegionPts[I].X + FMoveDx) * Zoom),
        OffsetY + Round((FRegionPts[I].Y + FMoveDy) * Zoom));
    Rgn := CreatePolygonRgn(SP[0], N, ALTERNATE);
  end
  else
    // Różdżka (bez ścieżki): region GDI z maski 1 B/px.
    Rgn := RegionFromMask(FRegion, Zoom, OffsetX, OffsetY);

  if Rgn = 0 then Exit;
  // SaveDC/RestoreDC chroni ewentualny wcześniejszy klip (dirty rect).
  Saved := SaveDC(Canvas.Handle);
  try
    SelectClipRgn(Canvas.Handle, Rgn);
    Canvas.Pen.Style := psClear;
    Canvas.Brush.Style := bsBDiagonal;
    Canvas.Brush.Color := clRed;
    Canvas.Rectangle(L, T, R, B);
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsSolid;
    RestoreDC(Canvas.Handle, Saved);
  finally
    DeleteObject(Rgn);
  end;
end;

procedure TSelection.Draw(Canvas: TCanvas; Zoom: Double;
  OffsetX, OffsetY: Integer; ShowHandles: Boolean;
  ImgW, ImgH: Integer);
var
  L, T, R, B, MidX, MidY: Integer;
  vx, vy, vw, vh: Integer;
begin
  L := Round(GetLeft * Zoom);
  T := Round(GetTop * Zoom);
  R := Round(GetRight * Zoom);
  B := Round(GetBottom * Zoom);
  vx := OffsetX + L;
  vy := OffsetY + T;
  vw := R - L;
  vh := B - T;
  if (vw <= 0) or (vh <= 0) then Exit;

  // Lasso/różdżka: dowolny region.
  //  - lasso ze ścieżką: obrys (przerywana linia po ścieżce) albo Filled
  //    (szrafura + obrys), wg Selection display,
  //  - podczas przesuwania: sam obrys w nowym położeniu (podgląd),
  //  - różdżka (region z maski): szrafura wg maski (Filled) i/lub solidny
  //    obrys regionu — bez ścieżki, więc bez marching ants.
  if FShape in [hsLasso, hsWand] then
  begin
    if (FShape = hsLasso) and (Length(FRegionPts) >= 3) then
    begin
      if not FMoveActive then
      begin
        if FView = svMask then
          DrawRegionFill(Canvas, Zoom, OffsetX, OffsetY);
        MarchingAntsPolyline(Canvas, FRegionPts, Zoom, OffsetX, OffsetY,
          FDashOffset, 0, 0);
      end
      else
        MarchingAntsPolyline(Canvas, FRegionPts, Zoom, OffsetX, OffsetY,
          FDashOffset, FMoveDx, FMoveDy);
    end
    else
    begin
      // Różdżka: szrafura wg maski (Filled) i/lub solidny obrys regionu.
      if FView = svMask then
        DrawRegionFill(Canvas, Zoom, OffsetX, OffsetY);
      DrawRegionOutline(Canvas, Zoom, OffsetX, OffsetY);
    end;
    Exit;
  end;

  // mask view: wypełnienie kształtu szrafurą (quick-mask style), potem obrys
  if FView = svMask then
  begin
    Canvas.Pen.Style := psClear;
    Canvas.Brush.Style := bsBDiagonal;
    Canvas.Brush.Color := clRed;
    if FShape = hsEllipse then
      Canvas.Ellipse(Rect(vx, vy, vx + vw, vy + vh))
    else
      Canvas.Rectangle(Rect(vx, vy, vx + vw, vy + vh));
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsClear;
  end;

  // marching ants
  if FShape = hsEllipse then
    MarchingAntsEllipse(Canvas, Rect(vx, vy, vx + vw, vy + vh), FDashOffset)
  else
    MarchingAntsRect(Canvas, Rect(vx, vy, vx + vw, vy + vh), FDashOffset);

  // handles
  if ShowHandles then
  begin
    MidX := vx + vw div 2;
    MidY := vy + vh div 2;
    DrawHandle(Canvas, vx, vy, 8);       // TL
    DrawHandle(Canvas, MidX, vy, 8);     // TM
    DrawHandle(Canvas, vx + vw, vy, 8);  // TR
    DrawHandle(Canvas, vx, MidY, 8);     // ML
    DrawHandle(Canvas, vx + vw, MidY, 8);// MR
    DrawHandle(Canvas, vx, vy + vh, 8);  // BL
    DrawHandle(Canvas, MidX, vy + vh, 8);// BM
    DrawHandle(Canvas, vx + vw, vy + vh, 8);// BR
  end;
end;

{ --- Crop --- }

function SelectionCrop(Bitmap: TBitmap; const Sel: TSelection): TBitmap;
var
  R: TRect;
  W, H: Integer;
  SrcRow, DstRow: PRGBTripleArray;
  Y: Integer;
begin
  Result := nil;
  if (Bitmap = nil) or (Sel = nil) or (not Sel.IsValid) then Exit;
  R := Sel.ClampedRect(Bitmap.Width, Bitmap.Height);
  W := R.Right - R.Left + 1;
  H := R.Bottom - R.Top + 1;
  if (W < 1) or (H < 1) then Exit;

  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(W, H);

  for Y := 0 to H - 1 do
  begin
    SrcRow := Bitmap.ScanLine[R.Top + Y];
    DstRow := Result.ScanLine[Y];
    Move(SrcRow[R.Left], DstRow[0], W * 3);
  end;
end;

end.
