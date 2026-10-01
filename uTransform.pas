unit uTransform;

interface

uses
  Winapi.Windows, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Math, System.Types, Vcl.Graphics;

procedure RotateAndCrop(Bmp: TBitmap; AngleDeg: Double);
procedure ImageResize(Bmp: TBitmap; NewW, NewH: Integer);
procedure ImageResizeCrop(Bmp: TBitmap; TargetW, TargetH, Corner: Integer);
procedure ImageTile(Bmp: TBitmap; TargetW, TargetH: Integer);

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

end.
