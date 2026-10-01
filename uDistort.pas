unit uDistort;

interface

uses
  Winapi.Windows, System.SysUtils, System.Math, Vcl.Graphics;

procedure ApplyBarrel(Bmp: TBitmap; Preset: Integer);
procedure ApplyArc(Bmp: TBitmap; Preset: Integer);
procedure ApplySwirl(Bmp: TBitmap; Preset: Integer);
procedure ApplyWaterRipple(Bmp: TBitmap; Preset: Integer);
procedure ApplyWaterRippleEx(Bmp: TBitmap; Preset: Integer; Strength, Density: Double);
procedure ApplyPolar(Bmp: TBitmap; Preset: Integer);

implementation

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

procedure GetPixelBilinear(Lines: array of PRGBTripleArray; W, H: Integer; X, Y: Double; out R, G, B: Byte);
var
  X0, Y0, X1, Y1: Integer;
  Dx, Dy: Double;
  P00, P01, P10, P11: TRGBTriple;
  C0R, C0G, C0B, C1R, C1G, C1B: Double;
begin
  X0 := Floor(X);
  Y0 := Floor(Y);
  X1 := X0 + 1;
  Y1 := Y0 + 1;
  Dx := X - X0;
  Dy := Y - Y0;

  if (X0 < 0) or (Y0 < 0) or (X1 >= W) or (Y1 >= H) then
  begin
    R := 0; G := 0; B := 0;
    Exit;
  end;

  P00 := Lines[Y0][X0];
  P01 := Lines[Y0][X1];
  P10 := Lines[Y1][X0];
  P11 := Lines[Y1][X1];

  C0R := P00.R * (1 - Dx) + P01.R * Dx;
  C0G := P00.G * (1 - Dx) + P01.G * Dx;
  C0B := P00.B * (1 - Dx) + P01.B * Dx;

  C1R := P10.R * (1 - Dx) + P11.R * Dx;
  C1G := P10.G * (1 - Dx) + P11.G * Dx;
  C1B := P10.B * (1 - Dx) + P11.B * Dx;

  R := Byte(Max(0, Min(255, Round(C0R * (1 - Dy) + C1R * Dy))));
  G := Byte(Max(0, Min(255, Round(C0G * (1 - Dy) + C1G * Dy))));
  B := Byte(Max(0, Min(255, Round(C0B * (1 - Dy) + C1B * Dy))));
end;

procedure ApplyBarrel(Bmp: TBitmap; Preset: Integer);
var
  W, H: Integer;
  A, B, C, D_coeff: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, MaxR: Double;
  Nx, Ny, R, R2, R3, Scale: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  case Preset of
    0: begin A := -0.05; B := 0.0;  C := 0.0; D_coeff := 1.05; end; // Słaba beczka
    1: begin A := -0.12; B := 0.0;  C := 0.0; D_coeff := 1.12; end; // Średnia beczka
    2: begin A := -0.20; B := 0.0;  C := 0.0; D_coeff := 1.20; end; // Mocna beczka
    3: begin A :=  0.0;  B := 0.05; C := 0.0; D_coeff := 0.95; end; // Słaba poduszka
    4: begin A :=  0.0;  B := 0.12; C := 0.0; D_coeff := 0.88; end; // Średnia poduszka
    5: begin A :=  0.0;  B := 0.20; C := 0.0; D_coeff := 0.80; end; // Mocna poduszka
  else
    begin A := -0.05; B := 0.0;  C := 0.0; D_coeff := 1.05; end;
  end;

  Cx := W / 2.0;
  Cy := H / 2.0;
  MaxR := Sqrt(Cx * Cx + Cy * Cy);

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Nx := (X - Cx) / MaxR;
        Ny := (Y - Cy) / MaxR;
        R2 := Nx * Nx + Ny * Ny;
        R := Sqrt(R2);
        if R > 0.0001 then
        begin
          R3 := R2 * R;
          Scale := A * R3 + B * R2 + C * R + D_coeff;
          // Przemapowanie wsteczne (beczka): dzielenie przez Scale
          SrcX := Cx + (Nx / Scale) * MaxR;
          SrcY := Cy + (Ny / Scale) * MaxR;
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure ApplySwirl(Bmp: TBitmap; Preset: Integer);
var
  W, H: Integer;
  Deg: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, MaxR: Double;
  Dx, Dy, R, Theta, Factor, NewTheta: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  case Preset of
    0: Deg :=  45;
    1: Deg :=  90;
    2: Deg := 180;
    3: Deg := 270;
    4: Deg := 360;
    5: Deg := -180;
  else
    Deg := 90;
  end;

  Cx := W / 2.0;
  Cy := H / 2.0;
  MaxR := Min(Cx, Cy);

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        R := Sqrt(Dx * Dx + Dy * Dy);
        if (R < MaxR) and (MaxR > 0) then
        begin
          Theta := ArcTan2(Dy, Dx);
          Factor := (1.0 - (R / MaxR));
          NewTheta := Theta - Deg * (Pi / 180.0) * Factor * Factor;
          SrcX := Cx + R * Cos(NewTheta);
          SrcY := Cy + R * Sin(NewTheta);
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure ApplyWaterRipple(Bmp: TBitmap; Preset: Integer);
begin
  ApplyWaterRippleEx(Bmp, Preset, 1.0, 1.0);
end;

procedure ApplyWaterRippleEx(Bmp: TBitmap; Preset: Integer; Strength, Density: Double);
const
  DecayFactor = 1.5;  // szybki zanik - kontrast blisko/daleko od zrodla
  PeakBoost = 3.0;    // wzmocnienie amplitudy blisko zrodla (dramatyczny efekt)
var
  W, H: Integer;
  Base, Wavelength, Amplitude, DecayR, EffAmplitude: Double;
  CxNorm, CyNorm: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy: Double;
  Dx, Dy, R, NewR: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  Base := Max(W, H);
  CxNorm := 0.5; CyNorm := 0.5;
  case Preset of
    0: begin Wavelength := Base / 6.0;  Amplitude := Base / 120.0; end;
    1: begin Wavelength := Base / 10.0; Amplitude := Base / 100.0; end;
    2: begin Wavelength := Base / 15.0; Amplitude := Base / 80.0;  end;
    3: begin Wavelength := Base / 20.0; Amplitude := Base / 60.0;  end;
    4: begin Wavelength := Base / 10.0; Amplitude := Base / 100.0; CxNorm := 0.1; CyNorm := 0.1; end;
    5: begin Wavelength := Base / 30.0; Amplitude := Base / 300.0; end;
  else
    begin Wavelength := Base / 10.0; Amplitude := Base / 100.0; end;
  end;

  Cx := CxNorm * W;
  Cy := CyNorm * H;
  Amplitude := Amplitude * Strength;
  Wavelength := Wavelength / Density; // wieksza gestosc = krotsza fala
  DecayR := Wavelength * DecayFactor;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        R := Sqrt(Dx * Dx + Dy * Dy);
        if R > 0.0001 then
        begin
          EffAmplitude := Amplitude * PeakBoost * Exp(-R / DecayR);
          NewR := R + EffAmplitude * Sin(2.0 * Pi * R / Wavelength);
          SrcX := Cx + Dx * (NewR / R);
          SrcY := Cy + Dy * (NewR / R);
        end
        else
        begin
          SrcX := X;
          SrcY := Y;
        end;

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure ApplyArc(Bmp: TBitmap; Preset: Integer);
var
  W, H: Integer;
  Angle1, Angle2: Double;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, R0, Rad1, Rad2: Double;
  Dx, Dy, R, Theta: Double;
  SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  case Preset of
    0: begin Angle1 := 45;  Angle2 := 0;  end;
    1: begin Angle1 := 90;  Angle2 := 0;  end;
    2: begin Angle1 := 180; Angle2 := 0;  end;
    3: begin Angle1 := 360; Angle2 := 0;  end;
    4: begin Angle1 := 90;  Angle2 := 45; end;
    5: begin Angle1 := 180; Angle2 := 90; end;
  else
    begin Angle1 := 90; Angle2 := 0; end;
  end;

  Rad1 := Angle1 * Pi / 180.0;
  Rad2 := Angle2 * Pi / 180.0;

  if Abs(Rad1) > 0.0001 then
    R0 := W / Rad1
  else
    R0 := 10000;

  Cx := W / 2.0;
  Cy := H + R0;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Cy - Y;
        R := Sqrt(Dx * Dx + Dy * Dy);
        Theta := ArcTan2(Dx, Dy);

        Theta := Theta - Rad2;

        SrcX := Cx + Theta * R0;
        SrcY := H - (R - R0);

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure ApplyPolar(Bmp: TBitmap; Preset: Integer);
var
  W, H: Integer;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
  X, Y: Integer;
  Cx, Cy, Rmax, Rmin, StartAngle, EndAngle: Double;
  Dx, Dy, R, Theta: Double;
  Tx, Ty, SrcX, SrcY: Double;
  Red, Green, Blue: Byte;
begin
  W := Bmp.Width;
  H := Bmp.Height;
  if (W = 0) or (H = 0) then Exit;
  Bmp.PixelFormat := pf24bit;

  Cx := W / 2.0;
  Cy := H / 2.0;
  Rmax := Sqrt(Cx * Cx + Cy * Cy);
  Rmin := 0;
  StartAngle := -180;
  EndAngle := 180;

  case Preset of
    0: ;
    1: begin StartAngle := -90; EndAngle := 90; end;
    2: begin StartAngle := -45; EndAngle := 45; end;
    3: begin Rmin := Rmax / 2.0; end;
    4: begin Rmax := Rmax / 2.0; end;
    5: ;
    6: begin Rmin := Rmax * 0.8; end;
    7: begin StartAngle := -360; EndAngle := 360; end;
    8: begin Rmax := Rmax * 0.6; end;
    9: begin Rmax := Rmax; Rmin := Rmax * 0.6; end;
    10: begin StartAngle := -540; EndAngle := 540; end;
    11: begin StartAngle := -15; EndAngle := 15; end;
  end;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bmp.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
    begin
      for X := 0 to W - 1 do
      begin
        Dx := X - Cx;
        Dy := Y - Cy;
        R := Sqrt(Dx * Dx + Dy * Dy);
        Theta := ArcTan2(Dy, Dx) * 180.0 / Pi;

        if EndAngle <> StartAngle then
          Tx := (Theta - StartAngle) / (EndAngle - StartAngle)
        else
          Tx := 0;

        if Rmax <> Rmin then
          Ty := (R - Rmin) / (Rmax - Rmin)
        else
          Ty := 0;

        SrcX := Tx * (W - 1);
        SrcY := Ty * (H - 1);

        GetPixelBilinear(SrcLines, W, H, SrcX, SrcY, Red, Green, Blue);
        DstLines[Y][X].R := Red;
        DstLines[Y][X].G := Green;
        DstLines[Y][X].B := Blue;
      end;
    end;
    Bmp.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

end.