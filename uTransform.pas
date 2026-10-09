unit uTransform;

interface

uses
  Winapi.Windows, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Math, System.Types, Vcl.Graphics;

type
  TQuad = array[0..3] of TPointF;

procedure RotateAndCrop(Bmp: TBitmap; AngleDeg: Double);
procedure ImageResize(Bmp: TBitmap; NewW, NewH: Integer);
procedure ImageResizeCrop(Bmp: TBitmap; TargetW, TargetH, Corner: Integer);
procedure ImageTile(Bmp: TBitmap; TargetW, TargetH: Integer);
procedure PerspectiveOutputSize(const Quad: TQuad; out OutW, OutH: Integer);
function QuadIsConvex(const Q: TQuad): Boolean;
function PerspectiveWarp(Src: TBitmap; const Quad: TQuad; OutW, OutH: Integer): TBitmap;

implementation

procedure RotateAndCrop(Bmp: TBitmap; AngleDeg: Double);
var
  SrcGP: TGPBitmap;
  G: TGPGraphics;
  RotM: TGPMatrix;
  W, H: Integer;
  Rad, AbsCos, AbsSin, Cos2: Double;
  IW, IH: Double;
  CW, CH, CropX, CropY: Integer;
  RotBmp: TBitmap;
  Y: Integer;
  SrcRow, DstRow: PByte;
begin
  if (Bmp = nil) or (Bmp.Width = 0) or (Bmp.Height = 0) or (AngleDeg = 0) then Exit;

  W := Bmp.Width;
  H := Bmp.Height;

  // 1. Zabezpieczamy format 24-bit
  Bmp.PixelFormat := pf24bit;

  // 2. Obrót GDI+ w czystym, pełnym wymiarze (maksymalna ostrość interpolacji)
  RotBmp := TBitmap.Create;
  try
    RotBmp.PixelFormat := pf24bit;
    RotBmp.SetSize(W, H);

    SrcGP := TGPBitmap.Create(Bmp.Handle, Bmp.Palette);
    try
      G := TGPGraphics.Create(RotBmp.Canvas.Handle);
      try
        // Interpolacja wysokiej jakości bez sztucznych przesunięć
        G.SetInterpolationMode(InterpolationModeHighQualityBilinear);
        G.Clear(MakeColor(255, 0, 0, 0));

        RotM := TGPMatrix.Create;
        try
          RotM.RotateAt(AngleDeg, MakePoint(W / 2.0, H / 2.0));
          G.SetTransform(RotM);
          G.DrawImage(SrcGP, 0, 0, W, H);
        finally
          RotM.Free;
        end;
      finally
        G.Free;
      end;
    finally
      SrcGP.Free;
    end;

    // 3. Wyliczenie czystego docięcia (Inscribed Rectangle)
    Rad := AngleDeg * Pi / 180.0;
    AbsCos := Abs(Cos(Rad));
    AbsSin := Abs(Sin(Rad));
    Cos2 := Cos(2 * Rad);

    CW := W;
    CH := H;
    CropX := 0;
    CropY := 0;

    if Abs(Cos2) > 0.01 then
    begin
      IW := (W * AbsCos - H * AbsSin) / Cos2;
      IH := (H * AbsCos - W * AbsSin) / Cos2;

      if (IW > W * 0.5) and (IH > H * 0.5) then
      begin
        CropX := Integer(Trunc((W - IW) / 2));
        CropY := Integer(Trunc((H - IH) / 2));
        CW := Min(Integer(Trunc(IW)), W - CropX);
        CH := Min(Integer(Trunc(IH)), H - CropY);
      end;
    end;

    // 4. Jeśli trzeba przyciąć - po prostu przepisujemy szybkim Move (bez ponownej interpolacji!)
    if (CW < W) or (CH < H) then
    begin
      Bmp.SetSize(CW, CH);
      Bmp.PixelFormat := pf24bit;

      for Y := 0 to CH - 1 do
      begin
        SrcRow := RotBmp.ScanLine[Y + CropY];
        DstRow := Bmp.ScanLine[Y];
        Move(SrcRow[CropX * 3], DstRow^, CW * 3);
      end;
    end
    else
    begin
      // Jeśli obrót nie wymagał docięcia, po prostu podmieniamy obrazek
      Bmp.Assign(RotBmp);
    end;

  finally
    RotBmp.Free;
  end;
end;

procedure ImageResize(Bmp: TBitmap; NewW, NewH: Integer);
var
  Tmp: TBitmap;
begin
  if (Bmp = nil) or (Bmp.Width = 0) or (Bmp.Height = 0) then Exit;
  if (NewW < 1) or (NewH < 1) then Exit;
  if (NewW = Bmp.Width) and (NewH = Bmp.Height) then Exit;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(NewW, NewH);
    SetStretchBltMode(Tmp.Canvas.Handle, HALFTONE);
    Tmp.Canvas.StretchDraw(Rect(0, 0, NewW, NewH), Bmp);
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure ImageResizeCrop(Bmp: TBitmap; TargetW, TargetH, Corner: Integer);
var
  Scale, SW, SH: Double;
  ScaledW, ScaledH, ExcessW, ExcessH, CropX, CropY: Integer;
  Scaled: TBitmap;
begin
  if (Bmp = nil) or (Bmp.Width = 0) or (Bmp.Height = 0) then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;

  SW := TargetW / Bmp.Width;
  SH := TargetH / Bmp.Height;
  if SW > SH then Scale := SW else Scale := SH;

  ScaledW := Max(1, Round(Bmp.Width * Scale));
  ScaledH := Max(1, Round(Bmp.Height * Scale));
  ExcessW := ScaledW - TargetW;
  ExcessH := ScaledH - TargetH;

  case Corner of
    0: begin CropX := 0;           CropY := 0; end;
    1: begin CropX := ExcessW;     CropY := 0; end;
    2: begin CropX := 0;           CropY := ExcessH; end;
  else
    begin CropX := ExcessW;       CropY := ExcessH; end;
  end;

  if CropX < 0 then CropX := 0;
  if CropY < 0 then CropY := 0;

  Scaled := TBitmap.Create;
  try
    Scaled.PixelFormat := pf24bit;
    Scaled.SetSize(ScaledW, ScaledH);
    SetStretchBltMode(Scaled.Canvas.Handle, HALFTONE);
    Scaled.Canvas.StretchDraw(Rect(0, 0, ScaledW, ScaledH), Bmp);

    Bmp.SetSize(TargetW, TargetH);
    Bmp.PixelFormat := pf24bit;
    BitBlt(Bmp.Canvas.Handle, 0, 0, TargetW, TargetH,
      Scaled.Canvas.Handle, CropX, CropY, SRCCOPY);
  finally
    Scaled.Free;
  end;
end;

procedure ImageTile(Bmp: TBitmap; TargetW, TargetH: Integer);
var
  X, Y, SrcW, SrcH: Integer;
  Tmp: TBitmap;
begin
  if (Bmp = nil) or (Bmp.Width = 0) or (Bmp.Height = 0) then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;

  SrcW := Bmp.Width;
  SrcH := Bmp.Height;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(TargetW, TargetH);

    Y := 0;
    while Y < TargetH do
    begin
      X := 0;
      while X < TargetW do
      begin
        BitBlt(Tmp.Canvas.Handle, X, Y, SrcW, SrcH,
          Bmp.Canvas.Handle, 0, 0, SRCCOPY);
        Inc(X, SrcW);
      end;
      Inc(Y, SrcH);
    end;

    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure PerspectiveOutputSize(const Quad: TQuad;
  out OutW, OutH: Integer);
var
  TopLen, BotLen, LeftLen, RightLen: Double;
begin
  TopLen := Sqrt(Sqr(Quad[1].X - Quad[0].X) + Sqr(Quad[1].Y - Quad[0].Y));
  BotLen := Sqrt(Sqr(Quad[2].X - Quad[3].X) + Sqr(Quad[2].Y - Quad[3].Y));
  LeftLen := Sqrt(Sqr(Quad[3].X - Quad[0].X) + Sqr(Quad[3].Y - Quad[0].Y));
  RightLen := Sqrt(Sqr(Quad[2].X - Quad[1].X) + Sqr(Quad[2].Y - Quad[1].Y));

  OutW := Max(1, Round(Max(TopLen, BotLen)));
  OutH := Max(1, Round(Max(LeftLen, RightLen)));
end;

function QuadIsConvex(const Q: TQuad): Boolean;
var
  I, J, K: Integer;
  Cr: Double;
  HasPos, HasNeg: Boolean;
begin
  HasPos := False;
  HasNeg := False;
  for I := 0 to 3 do
  begin
    J := (I + 1) mod 4;
    K := (I + 2) mod 4;
    Cr := (Q[J].X - Q[I].X) * (Q[K].Y - Q[J].Y)
        - (Q[J].Y - Q[I].Y) * (Q[K].X - Q[J].X);
    if Abs(Cr) < 1.0 then Exit(False);
    if Cr > 0 then HasPos := True else HasNeg := True;
  end;
  Result := not (HasPos and HasNeg);
end;

// Quad w kolejności: lewy górny, prawy górny, prawy dolny, lewy dolny,
// we współrzędnych krawędzi pikseli (0..W, 0..H), a nie w indeksach pikseli (0..W-1).
function PerspectiveWarp(Src: TBitmap; const Quad: TQuad;
  OutW, OutH: Integer): TBitmap;
var
  SrcW, SrcH, X, Y, K, V8, I: Integer;
  IX0, IY0, IX1, IY1: Integer;
  DX1, DX2, DX3, DY1, DY2, DY3, Den: Double;
  mA, mB, mC, mD, mE, mF, mG, mH: Double;
  U, V, Denom, SX, SY, FX, FY, TVal: Double;
  Row0, Row1, DstRow, P00, P10, P01, P11, DP: PByte;
  Rows: array of PByte;
  Dst: TBitmap;
begin
  Result := nil;
  if Src = nil then Exit;
  SrcW := Src.Width;
  SrcH := Src.Height;
  if (SrcW = 0) or (SrcH = 0) then Exit;
  if (OutW < 1) or (OutH < 1) then Exit;
  if Src.PixelFormat <> pf24bit then Exit;
  if not QuadIsConvex(Quad) then Exit;

  DX1 := Quad[1].X - Quad[2].X;
  DX2 := Quad[3].X - Quad[2].X;
  DX3 := Quad[0].X - Quad[1].X + Quad[2].X - Quad[3].X;
  DY1 := Quad[1].Y - Quad[2].Y;
  DY2 := Quad[3].Y - Quad[2].Y;
  DY3 := Quad[0].Y - Quad[1].Y + Quad[2].Y - Quad[3].Y;

  if (Abs(DX3) < 1E-12) and (Abs(DY3) < 1E-12) then
  begin
    mA := Quad[1].X - Quad[0].X;
    mB := Quad[3].X - Quad[0].X;
    mC := Quad[0].X;
    mD := Quad[1].Y - Quad[0].Y;
    mE := Quad[3].Y - Quad[0].Y;
    mF := Quad[0].Y;
    mG := 0;
    mH := 0;
  end
  else
  begin
    Den := DX1 * DY2 - DX2 * DY1;
    if Abs(Den) < 1E-12 then Exit;
    mG := (DX3 * DY2 - DX2 * DY3) / Den;
    mH := (DX1 * DY3 - DX3 * DY1) / Den;
    mA := Quad[1].X - Quad[0].X + mG * Quad[1].X;
    mB := Quad[3].X - Quad[0].X + mH * Quad[3].X;
    mC := Quad[0].X;
    mD := Quad[1].Y - Quad[0].Y + mG * Quad[1].Y;
    mE := Quad[3].Y - Quad[0].Y + mH * Quad[3].Y;
    mF := Quad[0].Y;
  end;

  SetLength(Rows, SrcH);
  for I := 0 to SrcH - 1 do
    Rows[I] := Src.ScanLine[I];

  Dst := TBitmap.Create;
  try
    Dst.PixelFormat := pf24bit;
    Dst.SetSize(OutW, OutH);
    for Y := 0 to OutH - 1 do
    begin
      V := Y / OutH;
      DstRow := Dst.ScanLine[Y];
      for X := 0 to OutW - 1 do
      begin
        U := X / OutW;
        Denom := mG * U + mH * V + 1;
        if Abs(Denom) < 1E-12 then Denom := 1E-12;
        SX := (mA * U + mB * V + mC) / Denom;
        SY := (mD * U + mE * V + mF) / Denom;

        if SX < 0 then SX := 0
        else if SX > SrcW - 1 then SX := SrcW - 1;
        if SY < 0 then SY := 0
        else if SY > SrcH - 1 then SY := SrcH - 1;

        IX0 := Trunc(SX);
        IY0 := Trunc(SY);
        if IX0 > SrcW - 2 then IX0 := SrcW - 2;
        if IY0 > SrcH - 2 then IY0 := SrcH - 2;
        if IX0 < 0 then IX0 := 0;
        if IY0 < 0 then IY0 := 0;
        IX1 := IX0 + 1;
        IY1 := IY0 + 1;
        if IX1 > SrcW - 1 then IX1 := SrcW - 1;
        if IY1 > SrcH - 1 then IY1 := SrcH - 1;

        FX := SX - IX0;
        FY := SY - IY0;

        Row0 := Rows[IY0];
        Row1 := Rows[IY1];
        P00 := Row0;
        Inc(P00, IX0 * 3);
        P10 := Row0;
        Inc(P10, IX1 * 3);
        P01 := Row1;
        Inc(P01, IX0 * 3);
        P11 := Row1;
        Inc(P11, IX1 * 3);

        DP := DstRow;
        Inc(DP, X * 3);
        for K := 0 to 2 do
        begin
          TVal := P00[K] * (1 - FX) * (1 - FY)
            + P10[K] * FX * (1 - FY)
            + P01[K] * (1 - FX) * FY
            + P11[K] * FX * FY;
          V8 := Round(TVal);
          if V8 < 0 then V8 := 0
          else if V8 > 255 then V8 := 255;
          DP[K] := Byte(V8);
        end;
      end;
    end;
    Result := Dst;
  except
    Dst.Free;
    raise;
  end;
end;

end.
