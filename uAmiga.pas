unit uAmiga;

interface

uses
  Winapi.Windows, System.Types, System.Math,
  Vcl.Graphics;

procedure ApplyHAM(Bitmap: TBitmap; Bits: Integer);
procedure ApplyWorkbench1(Bitmap: TBitmap);
procedure ApplyWorkbench2(Bitmap: TBitmap);
procedure ApplyMagicWB(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyOCS32(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyEHB(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyAGA256(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyWB256(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyAmigaGradient(Bitmap: TBitmap; Pct: Integer);
procedure ApplyAmigaGradientAgony(Bitmap: TBitmap; HueTop, HueBot, Bars: Integer);
procedure ApplyAmigaBackground(Bitmap: TBitmap; TargetW, TargetH: Integer; FillColor: TColor);
procedure ApplyAmigaBackgroundStretch(Bitmap: TBitmap; TargetW, TargetH: Integer);
procedure ApplyC64(Bitmap: TBitmap; PalType, DitherMode: Integer);
procedure ApplyZXSpectrum(Bitmap: TBitmap; Dither: Boolean);
procedure ApplyGameBoy(Bitmap: TBitmap; PalType: Integer; Dither: Boolean);
procedure ApplyNES(Bitmap: TBitmap; Dither: Boolean);

implementation

type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

const
  // Standard palettes dumped from Hollywood 11 (CreatePalette(#PALETTE_OCS/AGA/WORKBENCH))
  OCS32_R: array[0..31] of Byte = ($00, $A0, $EE, $AA, $DD, $FF, $88, $00, $00, $00, $00, $00, $00, $77, $CC, $CC, $66, $EE, $AA, $FF, $33, $44, $55, $66, $77, $88, $99, $AA, $CC, $DD, $EE, $FF);
  OCS32_G: array[0..31] of Byte = ($00, $A0, $00, $00, $88, $EE, $FF, $88, $BB, $DD, $AA, $77, $00, $00, $00, $00, $22, $55, $55, $CC, $33, $44, $55, $66, $77, $88, $99, $AA, $CC, $DD, $EE, $FF);
  OCS32_B: array[0..31] of Byte = ($00, $A0, $00, $00, $00, $00, $00, $00, $66, $DD, $FF, $CC, $FF, $FF, $EE, $88, $00, $22, $22, $AA, $33, $44, $55, $66, $77, $88, $99, $AA, $CC, $DD, $EE, $FF);

  AGA256_R: array[0..255] of Byte = (
    $00, $A0, $FF, $FF, $80, $02, $00, $00,
    $00, $00, $7A, $CD, $FF, $FF, $FF, $FF,
    $CA, $96, $63, $FF, $C2, $80, $80, $80,
    $80, $80, $A7, $CE, $F8, $FF, $FF, $FF,
    $80, $80, $80, $80, $80, $80, $43, $01,
    $00, $00, $00, $00, $28, $4F, $79, $80,
    $00, $11, $22, $33, $44, $55, $66, $77,
    $87, $98, $A9, $BA, $CB, $DC, $ED, $FF,
    $4D, $58, $70, $87, $9E, $B6, $CE, $E6,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $4E, $57, $6F, $86, $9E, $B6, $CE, $E6,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $4D, $58, $70, $87, $9E, $B6, $CE, $E6,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $00, $00, $00, $01, $01, $01, $01, $01,
    $00, $1E, $39, $54, $72, $8B, $A5, $C0,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $58, $76, $88, $9E, $B9, $CB, $DA,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6E, $88, $A3, $BE,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6E, $88, $A3, $BE,
    $27, $33, $40, $4D, $59, $66, $73, $80,
    $7A, $8D, $96, $A4, $AF, $BD, $CA, $D9,
    $4B, $5E, $75, $89, $9E, $B5, $CA, $E0,
    $F1, $F3, $F9, $FA, $FB, $FC, $FF, $FF,
    $21, $2E, $3B, $48, $55, $63, $70, $7D,
    $87, $98, $A9, $BA, $CB, $DC, $ED, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
  AGA256_G: array[0..255] of Byte = (
    $00, $A0, $FF, $FB, $FF, $FF, $FF, $FF,
    $81, $00, $00, $00, $00, $00, $00, $7E,
    $98, $3F, $00, $F7, $FF, $FF, $FF, $FF,
    $C0, $81, $80, $80, $80, $80, $80, $9D,
    $00, $1E, $3F, $51, $66, $7B, $80, $80,
    $80, $80, $41, $02, $00, $00, $00, $00,
    $00, $11, $22, $33, $44, $55, $66, $77,
    $87, $98, $A9, $BA, $CB, $DC, $ED, $FF,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6E, $88, $A3, $BE,
    $24, $28, $34, $3F, $4A, $5A, $65, $71,
    $7E, $8C, $99, $A7, $B1, $BF, $CD, $DC,
    $48, $52, $69, $81, $97, $AE, $C5, $E2,
    $FF, $FC, $F8, $F9, $F6, $F8, $F8, $FB,
    $4D, $63, $79, $8F, $A5, $BB, $D1, $E8,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $40, $58, $70, $87, $9E, $B6, $CE, $E6,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $20, $2C, $38, $45, $51, $5C, $69, $75,
    $81, $8F, $9D, $AA, $BB, $C8, $D4, $E1,
    $03, $03, $04, $05, $06, $02, $03, $03,
    $00, $25, $3F, $5D, $78, $93, $AB, $C6,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6C, $86, $A1, $BC,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6D, $87, $A2, $BE,
    $00, $03, $07, $0E, $17, $21, $2B, $38,
    $46, $59, $6D, $82, $99, $B2, $CC, $E9,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
  AGA256_B: array[0..255] of Byte = (
    $00, $A0, $FF, $00, $00, $00, $7C, $FF,
    $FF, $FF, $FF, $FF, $D7, $83, $00, $00,
    $44, $19, $00, $80, $80, $80, $BD, $FF,
    $FF, $FF, $FF, $FF, $FF, $C1, $80, $80,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $3E, $80, $80, $80, $80, $80, $80, $42,
    $00, $11, $22, $33, $44, $55, $66, $77,
    $87, $98, $A9, $BA, $CB, $DC, $ED, $FF,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6E, $88, $A3, $BE,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $36, $51, $6C, $86, $A0, $BF,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6D, $87, $A2, $BE,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $1C, $37, $52, $6D, $87, $A2, $BF,
    $40, $58, $70, $87, $9E, $B6, $CE, $E6,
    $FF, $F8, $F9, $FD, $FB, $FC, $FD, $FF,
    $40, $58, $70, $87, $9F, $B6, $CE, $E6,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $4E, $64, $7A, $8F, $A5, $BC, $D2, $E8,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $4E, $67, $80, $99, $B2, $CB, $E5, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $4C, $62, $79, $8E, $A4, $BB, $D1, $E8,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $00, $02, $06, $0B, $12, $1A, $24, $2E,
    $3B, $4C, $5E, $74, $8A, $A3, $BE, $DE,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  WB256_R: array[0..255] of Byte = (
    $C0, $00, $F0, $20, $00, $F0, $00, $F0,
    $60, $E0, $90, $E0, $50, $90, $00, $C0,
    $00, $E0, $00, $E0, $40, $50, $60, $70,
    $80, $90, $A0, $B0, $C0, $D0, $E0, $F0,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $80,
    $40, $C0, $60, $20, $A0, $E0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $40, $20, $60,
    $30, $10, $50, $70, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $80, $40, $C0, $60, $20,
    $A0, $E0, $C0, $60, $F0, $90, $30, $F0,
    $F0, $40, $20, $60, $30, $10, $50, $70,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $80,
    $40, $C0, $60, $20, $A0, $E0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $40, $20, $60,
    $30, $10, $50, $70, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $80, $40, $C0, $60, $20,
    $A0, $E0, $C0, $60, $F0, $90, $30, $F0,
    $F0, $40, $20, $60, $30, $10, $50, $70,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $80,
    $40, $C0, $60, $20, $A0, $E0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $40, $20, $60,
    $30, $10, $50, $70, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $80, $40, $C0, $60, $20,
    $A0, $E0, $C0, $60, $F0, $90, $30, $F0,
    $F0, $40, $20, $60, $30, $10, $50, $70,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $80,
    $40, $C0, $60, $20, $A0, $E0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $40, $20, $60,
    $30, $10, $50, $70, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $80, $40, $C0, $60, $20,
    $A0, $E0, $C0, $60, $F0, $90, $30, $F0,
    $F0, $40, $20, $60, $E0, $50, $00, $E0);
  WB256_G: array[0..255] of Byte = (
    $C0, $00, $F0, $C0, $00, $00, $F0, $F0,
    $20, $50, $F0, $B0, $50, $20, $F0, $C0,
    $00, $40, $00, $E0, $40, $50, $60, $70,
    $80, $90, $A0, $B0, $C0, $D0, $E0, $F0,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $F0,
    $80, $F0, $C0, $40, $F0, $F0, $F0, $80,
    $F0, $C0, $40, $F0, $F0, $F0, $80, $F0,
    $C0, $40, $F0, $F0, $80, $40, $C0, $60,
    $20, $A0, $E0, $80, $40, $C0, $60, $20,
    $A0, $E0, $80, $40, $C0, $60, $20, $A0,
    $E0, $80, $40, $C0, $60, $20, $A0, $E0,
    $C0, $60, $F0, $90, $30, $F0, $F0, $C0,
    $60, $F0, $90, $30, $F0, $F0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $C0, $60, $F0,
    $90, $30, $F0, $F0, $40, $20, $60, $30,
    $10, $50, $70, $40, $20, $60, $30, $10,
    $50, $70, $40, $20, $60, $30, $10, $50,
    $70, $40, $20, $60, $30, $10, $50, $70,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $F0,
    $80, $F0, $C0, $40, $F0, $F0, $F0, $80,
    $F0, $C0, $40, $F0, $F0, $F0, $80, $F0,
    $C0, $40, $F0, $F0, $80, $40, $C0, $60,
    $20, $A0, $E0, $80, $40, $C0, $60, $20,
    $A0, $E0, $80, $40, $C0, $60, $20, $A0,
    $E0, $80, $40, $C0, $60, $20, $A0, $E0,
    $C0, $60, $F0, $90, $30, $F0, $F0, $C0,
    $60, $F0, $90, $30, $F0, $F0, $C0, $60,
    $F0, $90, $30, $F0, $F0, $C0, $60, $F0,
    $90, $30, $F0, $F0, $40, $20, $60, $30,
    $10, $50, $70, $40, $20, $60, $30, $10,
    $50, $70, $40, $20, $60, $30, $10, $50,
    $70, $40, $20, $60, $40, $D0, $40, $90);
  WB256_B: array[0..255] of Byte = (
    $C0, $00, $F0, $D0, $F0, $F0, $F0, $F0,
    $00, $00, $10, $00, $F0, $F0, $80, $C0,
    $00, $40, $00, $C0, $40, $50, $60, $70,
    $80, $90, $A0, $B0, $C0, $D0, $E0, $F0,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $F0,
    $80, $F0, $C0, $40, $F0, $F0, $F0, $80,
    $F0, $C0, $40, $F0, $F0, $F0, $80, $F0,
    $C0, $40, $F0, $F0, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $F0, $80, $F0, $C0, $40,
    $F0, $F0, $F0, $80, $F0, $C0, $40, $F0,
    $F0, $F0, $80, $F0, $C0, $40, $F0, $F0,
    $F0, $80, $F0, $C0, $40, $F0, $F0, $F0,
    $80, $F0, $C0, $40, $F0, $F0, $F0, $80,
    $F0, $C0, $40, $F0, $F0, $F0, $80, $F0,
    $C0, $40, $F0, $F0, $F0, $80, $F0, $C0,
    $40, $F0, $F0, $F0, $80, $F0, $C0, $40,
    $F0, $F0, $F0, $80, $F0, $C0, $40, $F0,
    $F0, $F0, $80, $F0, $C0, $40, $F0, $F0,
    $80, $40, $C0, $60, $20, $A0, $E0, $80,
    $40, $C0, $60, $20, $A0, $E0, $80, $40,
    $C0, $60, $20, $A0, $E0, $80, $40, $C0,
    $60, $20, $A0, $E0, $80, $40, $C0, $60,
    $20, $A0, $E0, $80, $40, $C0, $60, $20,
    $A0, $E0, $80, $40, $C0, $60, $20, $A0,
    $E0, $80, $40, $C0, $60, $20, $A0, $E0,
    $80, $40, $C0, $60, $20, $A0, $E0, $80,
    $40, $C0, $60, $20, $A0, $E0, $80, $40,
    $C0, $60, $20, $A0, $E0, $80, $40, $C0,
    $60, $20, $A0, $E0, $80, $40, $C0, $60,
    $20, $A0, $E0, $80, $40, $C0, $60, $20,
    $A0, $E0, $80, $40, $C0, $60, $20, $A0,
    $E0, $80, $40, $C0, $40, $50, $D0, $00);

function HamLut(I: Integer; Bits: Integer): Byte; inline;
var
  BitMask, ShiftBits, ExpandMask: Integer;
begin
  if Bits = 4 then
  begin
    BitMask := $F0;  ShiftBits := 4;  ExpandMask := $0F;
  end
  else
  begin
    BitMask := $FC;  ShiftBits := 2;  ExpandMask := $03;
  end;
  Result := (I and BitMask) or ((I shr ShiftBits) and ExpandMask);
end;

procedure ApplyHAM(Bitmap: TBitmap; Bits: Integer);
var
  W, H, X, Y, J, NColors, PalCount: Integer;
  Row: PRGBTripleArray;
  PalR, PalG, PalB: array of Byte;
  Dist, BestDist, Mind: Int64;
  Dr1, Dg1, Db1: Int64;
  BestJ, InitJ: Integer;
  Qr, Qg, Qb: Byte;
  CurR, CurG, CurB: Byte;
  Pr, Pg, Pb: Byte;
  Freq: array of Integer;
  Key, RIdx, GIdx, BIdx, ShiftBits, BestKey, BestCount, K: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  NColors := 16;
  if Bits = 6 then NColors := 64;
  if Bits = 4 then ShiftBits := 4 else ShiftBits := 2;

  SetLength(PalR, NColors);
  SetLength(PalG, NColors);
  SetLength(PalB, NColors);

  // --- Step 1: Baza palety = NColors NAJCZESTSZYCH kwantyzowanych kolorow
  // (histogram), nie pierwsze napotkane w kolejnosci skanowania - to drugie
  // marnowalo sloty na warianty tla zanim dotarlo do wazniejszych partii obrazu.
  SetLength(Freq, NColors * NColors * NColors);
  for J := 0 to High(Freq) do Freq[J] := 0;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      RIdx := Row[X].rgbtRed shr ShiftBits;
      GIdx := Row[X].rgbtGreen shr ShiftBits;
      BIdx := Row[X].rgbtBlue shr ShiftBits;
      Key := (RIdx * NColors + GIdx) * NColors + BIdx;
      Inc(Freq[Key]);
    end;
  end;

  PalCount := 0;
  while PalCount < NColors do
  begin
    BestKey := -1; BestCount := 0;
    for K := 0 to High(Freq) do
      if Freq[K] > BestCount then
      begin
        BestCount := Freq[K]; BestKey := K;
      end;
    if BestKey < 0 then Break; // mniej niz NColors unikalnych kolorow w obrazie
    RIdx := BestKey div (NColors * NColors);
    GIdx := (BestKey div NColors) mod NColors;
    BIdx := BestKey mod NColors;
    PalR[PalCount] := HamLut(RIdx shl ShiftBits, Bits);
    PalG[PalCount] := HamLut(GIdx shl ShiftBits, Bits);
    PalB[PalCount] := HamLut(BIdx shl ShiftBits, Bits);
    Freq[BestKey] := 0;
    Inc(PalCount);
  end;

  // Fill remaining with black
  while PalCount < NColors do
  begin
    PalR[PalCount] := 0; PalG[PalCount] := 0; PalB[PalCount] := 0;
    Inc(PalCount);
  end;

  // --- Step 2: HAM encoding ---
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];

    // First pixel: nearest palette color
    Pr := Row[0].rgbtRed; Pg := Row[0].rgbtGreen; Pb := Row[0].rgbtBlue;
    BestDist := MaxInt; InitJ := 0;
    for J := 0 to NColors - 1 do
    begin
      Dist := (Pr - PalR[J]) * (Pr - PalR[J]) +
              (Pg - PalG[J]) * (Pg - PalG[J]) +
              (Pb - PalB[J]) * (Pb - PalB[J]);
      if Dist < BestDist then
      begin
        BestDist := Dist; InitJ := J;
        if Dist = 0 then Break;
      end;
    end;
    CurR := PalR[InitJ]; CurG := PalG[InitJ]; CurB := PalB[InitJ];
    Row[0].rgbtRed := CurR; Row[0].rgbtGreen := CurG; Row[0].rgbtBlue := CurB;

    // Remaining pixels: HAM decision
    for X := 1 to W - 1 do
    begin
      Pr := Row[X].rgbtRed; Pg := Row[X].rgbtGreen; Pb := Row[X].rgbtBlue;

      // Mode 0: nearest base palette color
      BestDist := MaxInt; BestJ := 0;
      for J := 0 to NColors - 1 do
      begin
        Dist := (Pr - PalR[J]) * (Pr - PalR[J]) +
                (Pg - PalG[J]) * (Pg - PalG[J]) +
                (Pb - PalB[J]) * (Pb - PalB[J]);
        if Dist < BestDist then
        begin
          BestDist := Dist; BestJ := J;
          if Dist = 0 then Break;
        end;
      end;

      // Mode 1: modify R (hold G, B)
      Qr := HamLut(Pr, Bits);
      Dr1 := (Qr - Pr) * (Qr - Pr) +
             (CurG - Pg) * (CurG - Pg) +
             (CurB - Pb) * (CurB - Pb);

      // Mode 2: modify G (hold R, B)
      Qg := HamLut(Pg, Bits);
      Dg1 := (CurR - Pr) * (CurR - Pr) +
             (Qg - Pg) * (Qg - Pg) +
             (CurB - Pb) * (CurB - Pb);

      // Mode 3: modify B (hold R, G)
      Qb := HamLut(Pb, Bits);
      Db1 := (CurR - Pr) * (CurR - Pr) +
             (CurG - Pg) * (CurG - Pg) +
             (Qb - Pb) * (Qb - Pb);

      // Pick best mode
      Mind := BestDist;
      if Dr1 < Mind then Mind := Dr1;
      if Dg1 < Mind then Mind := Dg1;
      if Db1 < Mind then Mind := Db1;

      if BestDist = Mind then
      begin
        CurR := PalR[BestJ]; CurG := PalG[BestJ]; CurB := PalB[BestJ];
      end
      else if Dr1 = Mind then
        CurR := Qr
      else if Dg1 = Mind then
        CurG := Qg
      else
        CurB := Qb;

      Row[X].rgbtRed := CurR;
      Row[X].rgbtGreen := CurG;
      Row[X].rgbtBlue := CurB;
    end;
  end;
end;

procedure ApplyWorkbenchPalette(Bitmap: TBitmap; const PalR, PalG, PalB: array of Byte);
var
  W, H, X, Y, RR, GG, BB, Idx, C, Best, BestD, D, Pr, Pg, Pb, N: Integer;
  Row: PRGBTripleArray;
  LutR, LutG, LutB: array[0..511] of Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  N := High(PalR);

  // Precompute 8x8x8 LUT (nearest palette colour per quantized RGB cell)
  for RR := 0 to 7 do
  begin
    Pr := RR * 32 + 16;
    for GG := 0 to 7 do
    begin
      Pg := GG * 32 + 16;
      for BB := 0 to 7 do
      begin
        Pb := BB * 32 + 16;
        Best := 0;
        BestD := MaxInt;
        for C := 0 to N do
        begin
          D := (Pr - PalR[C]) * (Pr - PalR[C]) +
               (Pg - PalG[C]) * (Pg - PalG[C]) +
               (Pb - PalB[C]) * (Pb - PalB[C]);
          if D < BestD then
          begin
            BestD := D;
            Best := C;
          end;
        end;
        Idx := (RR shl 6) or (GG shl 3) or BB;
        LutR[Idx] := PalR[Best];
        LutG[Idx] := PalG[Best];
        LutB[Idx] := PalB[Best];
      end;
    end;
  end;

  // Map each pixel via top 3 bits of each channel
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Idx := ((Row[X].rgbtRed shr 5) shl 6) or
             ((Row[X].rgbtGreen shr 5) shl 3) or
             (Row[X].rgbtBlue shr 5);
      Row[X].rgbtRed := LutR[Idx];
      Row[X].rgbtGreen := LutG[Idx];
      Row[X].rgbtBlue := LutB[Idx];
    end;
  end;
end;

procedure ApplyWorkbench1(Bitmap: TBitmap);
begin
  // OCS ROM palette: $055, $022, $FFF, $F80
  ApplyWorkbenchPalette(Bitmap,
    [0, 0, 255, 255],
    [85, 0, 255, 136],
    [170, 34, 255, 0]);
end;

procedure ApplyWorkbench2(Bitmap: TBitmap);
begin
  // OCS ROM palette: $AAA, $000, $FFF, $68B
  ApplyWorkbenchPalette(Bitmap,
    [170, 0, 255, 102],
    [170, 0, 255, 136],
    [170, 0, 255, 187]);
end;

procedure ApplyMagicWB(Bitmap: TBitmap; Dither: Boolean);
const
  PalR: array[0..7] of Byte = ($95, $00, $FF, $3B, $7B, $AF, $AA, $FF);
  PalG: array[0..7] of Byte = ($95, $00, $FF, $67, $7B, $AF, $90, $A9);
  PalB: array[0..7] of Byte = ($95, $00, $FF, $A2, $7B, $AF, $7C, $97);
  // Wazenie percepcyjne kanalow przy szukaniu najblizszego koloru palety,
  // standard ITU-R BT.601 (luma): R*0.299 + G*0.587 + B*0.114 (skalowane
  // x1000, liczby calkowite). Oko jest dużo czulsze na jasnosc (zielen) niz
  // na barwe (niebieski) - naiwny, niewazony Euklides w RGB nie jest
  // poprawnym dopasowaniem koloru do palety.
  WR = 299; WG = 587; WB = 114;
var
  W, H, X, Y, I, Best, BestD, D, PrR, PrG, PrB: Integer;
  K, Col, Idx, Dir: Integer;
  LTR: Boolean;
  Row: PRGBTripleArray;
  Er, Eg, Eb, ErN, EgN, EbN, ErN2, EgN2, EbN2: array of Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Dither then
  begin
    // Dithering Atkinsona (Bill Atkinson, Apple, lata 80.) zamiast Floyd-Steinberga.
    // Rozprasza tylko 6/8 bledu (2 piksele w prawo/lewo w tym samym wierszu az do
    // Idx+-2, plus 3 piksele w nastepnym wierszu, plus 1 piksel dwa wiersze nizej) -
    // reszte bledu (1/4) odrzuca, co daje jasniejszy, bardziej kontrastowy obraz
    // niz FS. Skanowanie wezykiem jak poprzednio.
    SetLength(Er, W + 4);
    SetLength(Eg, W + 4);
    SetLength(Eb, W + 4);
    SetLength(ErN, W + 4);
    SetLength(EgN, W + 4);
    SetLength(EbN, W + 4);
    SetLength(ErN2, W + 4);
    SetLength(EgN2, W + 4);
    SetLength(EbN2, W + 4);
    for I := 0 to W + 3 do
    begin
      Er[I] := 0; Eg[I] := 0; Eb[I] := 0;
      ErN[I] := 0; EgN[I] := 0; EbN[I] := 0;
      ErN2[I] := 0; EgN2[I] := 0; EbN2[I] := 0;
    end;

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      LTR := (Y and 1) = 0;
      if LTR then Dir := 1 else Dir := -1;
      for K := 0 to W - 1 do
      begin
        if LTR then Col := K else Col := W - 1 - K;
        Idx := Col + 2;

        PrR := Row[Col].rgbtRed + Er[Idx] div 8;
        PrG := Row[Col].rgbtGreen + Eg[Idx] div 8;
        PrB := Row[Col].rgbtBlue + Eb[Idx] div 8;
        if PrR < 0 then PrR := 0 else if PrR > 255 then PrR := 255;
        if PrG < 0 then PrG := 0 else if PrG > 255 then PrG := 255;
        if PrB < 0 then PrB := 0 else if PrB > 255 then PrB := 255;

        Best := 0;
        BestD := MaxInt;
        for I := 0 to 7 do
        begin
          D := (PrR - PalR[I]) * (PrR - PalR[I]) +
               (PrG - PalG[I]) * (PrG - PalG[I]) +
               (PrB - PalB[I]) * (PrB - PalB[I]);
          if D < BestD then
          begin
            BestD := D;
            Best := I;
          end;
        end;

        // 6 sasiadow x 1/8, reszta bledu (1/4) odrzucona - charakterystyka Atkinsona.
        Er[Idx + Dir]     := Er[Idx + Dir]     + (PrR - PalR[Best]);
        Er[Idx + 2*Dir]   := Er[Idx + 2*Dir]   + (PrR - PalR[Best]);
        ErN[Idx - Dir]    := ErN[Idx - Dir]    + (PrR - PalR[Best]);
        ErN[Idx]          := ErN[Idx]          + (PrR - PalR[Best]);
        ErN[Idx + Dir]    := ErN[Idx + Dir]    + (PrR - PalR[Best]);
        ErN2[Idx]         := ErN2[Idx]         + (PrR - PalR[Best]);

        Eg[Idx + Dir]     := Eg[Idx + Dir]     + (PrG - PalG[Best]);
        Eg[Idx + 2*Dir]   := Eg[Idx + 2*Dir]   + (PrG - PalG[Best]);
        EgN[Idx - Dir]    := EgN[Idx - Dir]    + (PrG - PalG[Best]);
        EgN[Idx]          := EgN[Idx]          + (PrG - PalG[Best]);
        EgN[Idx + Dir]    := EgN[Idx + Dir]    + (PrG - PalG[Best]);
        EgN2[Idx]         := EgN2[Idx]         + (PrG - PalG[Best]);

        Eb[Idx + Dir]     := Eb[Idx + Dir]     + (PrB - PalB[Best]);
        Eb[Idx + 2*Dir]   := Eb[Idx + 2*Dir]   + (PrB - PalB[Best]);
        EbN[Idx - Dir]    := EbN[Idx - Dir]    + (PrB - PalB[Best]);
        EbN[Idx]          := EbN[Idx]          + (PrB - PalB[Best]);
        EbN[Idx + Dir]    := EbN[Idx + Dir]    + (PrB - PalB[Best]);
        EbN2[Idx]         := EbN2[Idx]         + (PrB - PalB[Best]);

        Row[Col].rgbtRed := PalR[Best];
        Row[Col].rgbtGreen := PalG[Best];
        Row[Col].rgbtBlue := PalB[Best];
      end;
      for I := 0 to W + 3 do
      begin
        Er[I] := ErN[I]; ErN[I] := ErN2[I]; ErN2[I] := 0;
        Eg[I] := EgN[I]; EgN[I] := EgN2[I]; EgN2[I] := 0;
        Eb[I] := EbN[I]; EbN[I] := EbN2[I]; EbN2[I] := 0;
      end;
    end;
  end
  else
  begin
    // Plain nearest-match, no dither
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Best := 0;
        BestD := MaxInt;
        for I := 0 to 7 do
        begin
          D := WR * (Row[X].rgbtRed - PalR[I]) * (Row[X].rgbtRed - PalR[I]) +
               WG * (Row[X].rgbtGreen - PalG[I]) * (Row[X].rgbtGreen - PalG[I]) +
               WB * (Row[X].rgbtBlue - PalB[I]) * (Row[X].rgbtBlue - PalB[I]);
          if D < BestD then
          begin
            BestD := D;
            Best := I;
          end;
        end;
        Row[X].rgbtRed := PalR[Best];
        Row[X].rgbtGreen := PalG[Best];
        Row[X].rgbtBlue := PalB[Best];
      end;
    end;
  end;
end;

procedure RemapToPalette(Bitmap: TBitmap; const PalR, PalG, PalB: array of Byte;
  Dither: Boolean);
// Mapowanie do palety (odpowiednik Hollywood RemapBrush({Dither = dither})):
// Dithering Atkinsona (6 sasiadow, waga 1/8 kazdy) gdy Dither, inaczej nearest-match.
// Dobor najblizszego koloru wazony percepcyjnie (ITU-R BT.601), tak jak w ApplyMagicWB.
const
  WR = 299; WG = 587; WB = 114;
  MaxErr = 48; // clamping bledu dithera (patrz komentarz przy uzyciu nizej)
var
  W, H, X, Y, I, N, Best, BestD, D, PrR, PrG, PrB: Integer;
  K, Col, Idx, Dir, ErrR, ErrG, ErrB: Integer;
  LTR: Boolean;
  Row: PRGBTripleArray;
  Er, Eg, Eb, ErN, EgN, EbN, ErN2, EgN2, EbN2: array of Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  N := High(PalR);

  if Dither then
  begin
    // Dithering Atkinsona - patrz ApplyMagicWB. Ta sama funkcja RemapBrush
    // w Hollywood obsluguje OCS/AGA/WB256/EHB co MagicWB, wiec ten sam
    // algorytm dithering powinien tu obowiazywac.
    SetLength(Er, W + 4); SetLength(Eg, W + 4); SetLength(Eb, W + 4);
    SetLength(ErN, W + 4); SetLength(EgN, W + 4); SetLength(EbN, W + 4);
    SetLength(ErN2, W + 4); SetLength(EgN2, W + 4); SetLength(EbN2, W + 4);
    for I := 0 to W + 3 do
    begin
      Er[I] := 0; Eg[I] := 0; Eb[I] := 0;
      ErN[I] := 0; EgN[I] := 0; EbN[I] := 0;
      ErN2[I] := 0; EgN2[I] := 0; EbN2[I] := 0;
    end;

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      LTR := (Y and 1) = 0;
      if LTR then Dir := 1 else Dir := -1;
      for K := 0 to W - 1 do
      begin
        if LTR then Col := K else Col := W - 1 - K;
        Idx := Col + 2;

        PrR := Row[Col].rgbtRed + Er[Idx] div 8;
        PrG := Row[Col].rgbtGreen + Eg[Idx] div 8;
        PrB := Row[Col].rgbtBlue + Eb[Idx] div 8;
        if PrR < 0 then PrR := 0 else if PrR > 255 then PrR := 255;
        if PrG < 0 then PrG := 0 else if PrG > 255 then PrG := 255;
        if PrB < 0 then PrB := 0 else if PrB > 255 then PrB := 255;

        Best := 0; BestD := MaxInt;
        for I := 0 to N do
        begin
          D := (PrR - PalR[I]) * (PrR - PalR[I]) +
               (PrG - PalG[I]) * (PrG - PalG[I]) +
               (PrB - PalB[I]) * (PrB - PalB[I]);
          if D < BestD then
          begin
            BestD := D; Best := I;
          end;
        end;

        // Clamping bledu przed rozproszeniem - przy rzadkich/nasyconych paletach
        // (np. OCS32) pojedynczy piksel moze miec bardzo duzy blad kwantyzacji,
        // co przy rozproszeniu tworzy nadmiernie widoczne smugi. Ograniczamy
        // ekstremalne przypadki; wiekszosc pikseli (male bledy) nie jest dotknieta.
        ErrR := PrR - PalR[Best];
        ErrG := PrG - PalG[Best];
        ErrB := PrB - PalB[Best];
        if ErrR > MaxErr then ErrR := MaxErr else if ErrR < -MaxErr then ErrR := -MaxErr;
        if ErrG > MaxErr then ErrG := MaxErr else if ErrG < -MaxErr then ErrG := -MaxErr;
        if ErrB > MaxErr then ErrB := MaxErr else if ErrB < -MaxErr then ErrB := -MaxErr;
        Er[Idx + Dir]     := Er[Idx + Dir]     + ErrR;
        Er[Idx + 2*Dir]   := Er[Idx + 2*Dir]   + ErrR;
        ErN[Idx - Dir]    := ErN[Idx - Dir]    + ErrR;
        ErN[Idx]          := ErN[Idx]          + ErrR;
        ErN[Idx + Dir]    := ErN[Idx + Dir]    + ErrR;
        ErN2[Idx]         := ErN2[Idx]         + ErrR;
        Eg[Idx + Dir]     := Eg[Idx + Dir]     + ErrG;
        Eg[Idx + 2*Dir]   := Eg[Idx + 2*Dir]   + ErrG;
        EgN[Idx - Dir]    := EgN[Idx - Dir]    + ErrG;
        EgN[Idx]          := EgN[Idx]          + ErrG;
        EgN[Idx + Dir]    := EgN[Idx + Dir]    + ErrG;
        EgN2[Idx]         := EgN2[Idx]         + ErrG;
        Eb[Idx + Dir]     := Eb[Idx + Dir]     + ErrB;
        Eb[Idx + 2*Dir]   := Eb[Idx + 2*Dir]   + ErrB;
        EbN[Idx - Dir]    := EbN[Idx - Dir]    + ErrB;
        EbN[Idx]          := EbN[Idx]          + ErrB;
        EbN[Idx + Dir]    := EbN[Idx + Dir]    + ErrB;
        EbN2[Idx]         := EbN2[Idx]         + ErrB;

        Row[Col].rgbtRed := PalR[Best];
        Row[Col].rgbtGreen := PalG[Best];
        Row[Col].rgbtBlue := PalB[Best];
      end;
      for I := 0 to W + 3 do
      begin
        Er[I] := ErN[I]; ErN[I] := ErN2[I]; ErN2[I] := 0;
        Eg[I] := EgN[I]; EgN[I] := EgN2[I]; EgN2[I] := 0;
        Eb[I] := EbN[I]; EbN[I] := EbN2[I]; EbN2[I] := 0;
      end;
    end;
  end
  else
  begin
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Best := 0; BestD := MaxInt;
        for I := 0 to N do
        begin
          D := WR * (Row[X].rgbtRed - PalR[I]) * (Row[X].rgbtRed - PalR[I]) +
               WG * (Row[X].rgbtGreen - PalG[I]) * (Row[X].rgbtGreen - PalG[I]) +
               WB * (Row[X].rgbtBlue - PalB[I]) * (Row[X].rgbtBlue - PalB[I]);
          if D < BestD then
          begin
            BestD := D; Best := I;
          end;
        end;
        Row[X].rgbtRed := PalR[Best];
        Row[X].rgbtGreen := PalG[Best];
        Row[X].rgbtBlue := PalB[Best];
      end;
    end;
  end;
end;

procedure ApplyOCS32(Bitmap: TBitmap; Dither: Boolean);
const
  WR = 299; WG = 587; WB = 114;
  MaxErr = 48;
var
  W, H, X, Y, I, N, Best, BestD, D, PrR, PrG, PrB: Integer;
  ErrR, ErrG, ErrB: Integer;
  Row: PRGBTripleArray;
  Er, Eg, Eb, ErN, EgN, EbN, ErN2, EgN2, EbN2: array of Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  N := High(OCS32_R);

  if not Dither then
  begin
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Best := 0; BestD := MaxInt;
        for I := 0 to N do
        begin
          D := WR * (Row[X].rgbtRed - OCS32_R[I]) * (Row[X].rgbtRed - OCS32_R[I]) +
               WG * (Row[X].rgbtGreen - OCS32_G[I]) * (Row[X].rgbtGreen - OCS32_G[I]) +
               WB * (Row[X].rgbtBlue - OCS32_B[I]) * (Row[X].rgbtBlue - OCS32_B[I]);
          if D < BestD then
          begin
            BestD := D; Best := I;
          end;
        end;
        Row[X].rgbtRed := OCS32_R[Best];
        Row[X].rgbtGreen := OCS32_G[Best];
        Row[X].rgbtBlue := OCS32_B[Best];
      end;
    end;
    Exit;
  end;

  // Dithering Atkinsona - czysty raster L->R (bez serpentyny, eliminuje "wezyki")
  SetLength(Er, W + 4); SetLength(Eg, W + 4); SetLength(Eb, W + 4);
  SetLength(ErN, W + 4); SetLength(EgN, W + 4); SetLength(EbN, W + 4);
  SetLength(ErN2, W + 4); SetLength(EgN2, W + 4); SetLength(EbN2, W + 4);
  for I := 0 to W + 3 do
  begin
    Er[I] := 0; Eg[I] := 0; Eb[I] := 0;
    ErN[I] := 0; EgN[I] := 0; EbN[I] := 0;
    ErN2[I] := 0; EgN2[I] := 0; EbN2[I] := 0;
  end;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      var Idx := X + 2;

      PrR := Row[X].rgbtRed + Er[Idx] div 8;
      PrG := Row[X].rgbtGreen + Eg[Idx] div 8;
      PrB := Row[X].rgbtBlue + Eb[Idx] div 8;
      if PrR < 0 then PrR := 0 else if PrR > 255 then PrR := 255;
      if PrG < 0 then PrG := 0 else if PrG > 255 then PrG := 255;
      if PrB < 0 then PrB := 0 else if PrB > 255 then PrB := 255;

      Best := 0; BestD := MaxInt;
      for I := 0 to N do
      begin
        D := WR * (PrR - OCS32_R[I]) * (PrR - OCS32_R[I]) +
             WG * (PrG - OCS32_G[I]) * (PrG - OCS32_G[I]) +
             WB * (PrB - OCS32_B[I]) * (PrB - OCS32_B[I]);
        if D < BestD then
        begin
          BestD := D; Best := I;
        end;
      end;

      ErrR := PrR - OCS32_R[Best];
      ErrG := PrG - OCS32_G[Best];
      ErrB := PrB - OCS32_B[Best];
      if ErrR > MaxErr then ErrR := MaxErr else if ErrR < -MaxErr then ErrR := -MaxErr;
      if ErrG > MaxErr then ErrG := MaxErr else if ErrG < -MaxErr then ErrG := -MaxErr;
      if ErrB > MaxErr then ErrB := MaxErr else if ErrB < -MaxErr then ErrB := -MaxErr;

      // Rozproszenie Atkinsona L->R
      Er[Idx + 1]     := Er[Idx + 1]     + ErrR;
      Er[Idx + 2]     := Er[Idx + 2]     + ErrR;
      ErN[Idx - 1]    := ErN[Idx - 1]    + ErrR;
      ErN[Idx]        := ErN[Idx]        + ErrR;
      ErN[Idx + 1]    := ErN[Idx + 1]    + ErrR;
      ErN2[Idx]       := ErN2[Idx]       + ErrR;

      Eg[Idx + 1]     := Eg[Idx + 1]     + ErrG;
      Eg[Idx + 2]     := Eg[Idx + 2]     + ErrG;
      EgN[Idx - 1]    := EgN[Idx - 1]    + ErrG;
      EgN[Idx]        := EgN[Idx]        + ErrG;
      EgN[Idx + 1]    := EgN[Idx + 1]    + ErrG;
      EgN2[Idx]       := EgN2[Idx]       + ErrG;

      Eb[Idx + 1]     := Eb[Idx + 1]     + ErrB;
      Eb[Idx + 2]     := Eb[Idx + 2]     + ErrB;
      EbN[Idx - 1]    := EbN[Idx - 1]    + ErrB;
      EbN[Idx]        := EbN[Idx]        + ErrB;
      EbN[Idx + 1]    := EbN[Idx + 1]    + ErrB;
      EbN2[Idx]       := EbN2[Idx]       + ErrB;

      Row[X].rgbtRed := OCS32_R[Best];
      Row[X].rgbtGreen := OCS32_G[Best];
      Row[X].rgbtBlue := OCS32_B[Best];
    end;

    for I := 0 to W + 3 do
    begin
      Er[I] := ErN[I]; ErN[I] := ErN2[I]; ErN2[I] := 0;
      Eg[I] := EgN[I]; EgN[I] := EgN2[I]; EgN2[I] := 0;
      Eb[I] := EbN[I]; EbN[I] := EbN2[I]; EbN2[I] := 0;
    end;
  end;
end;

procedure ApplyEHB(Bitmap: TBitmap; Dither: Boolean);
// EHB: 32 kolory OCS + 32 half-brite (r>>1, g>>1, b>>1) — 1:1 z p_FxEHB.
var
  PalR, PalG, PalB: array[0..63] of Byte;
  I: Integer;
begin
  for I := 0 to 31 do
  begin
    PalR[I] := OCS32_R[I];
    PalG[I] := OCS32_G[I];
    PalB[I] := OCS32_B[I];
    PalR[I + 32] := OCS32_R[I] shr 1;
    PalG[I + 32] := OCS32_G[I] shr 1;
    PalB[I + 32] := OCS32_B[I] shr 1;
  end;
  RemapToPalette(Bitmap, PalR, PalG, PalB, Dither);
end;

procedure ApplyAGA256(Bitmap: TBitmap; Dither: Boolean);
begin
  RemapToPalette(Bitmap, AGA256_R, AGA256_G, AGA256_B, Dither);
end;

procedure ApplyWB256(Bitmap: TBitmap; Dither: Boolean);
begin
  RemapToPalette(Bitmap, WB256_R, WB256_G, WB256_B, Dither);
end;

procedure HsvToRgb(H, S, V: Double; out R, G, B: Byte);
// 1:1 z p_HsvToRgb (image_fx_effects.hws:1898) — Int() = Trunc dla dodatnich.
var
  Hi: Integer;
  F, P, Q, T, Vi: Double;
begin
  Hi := (Trunc(H / 60)) mod 6;
  F := H / 60 - Trunc(H / 60);
  P := Int(V * (1 - S) * 255);
  Q := Int(V * (1 - F * S) * 255);
  T := Int(V * (1 - (1 - F) * S) * 255);
  Vi := Int(V * 255);
  case Hi of
    0: begin R := Byte(Trunc(Vi)); G := Byte(Trunc(T));  B := Byte(Trunc(P)); end;
    1: begin R := Byte(Trunc(Q));  G := Byte(Trunc(Vi)); B := Byte(Trunc(P)); end;
    2: begin R := Byte(Trunc(P));  G := Byte(Trunc(Vi)); B := Byte(Trunc(T)); end;
    3: begin R := Byte(Trunc(P));  G := Byte(Trunc(Q));  B := Byte(Trunc(Vi)); end;
    4: begin R := Byte(Trunc(T));  G := Byte(Trunc(P));  B := Byte(Trunc(Vi)); end;
  else
       begin R := Byte(Trunc(Vi)); G := Byte(Trunc(P));  B := Byte(Trunc(Q)); end;
  end;
end;

procedure ApplyAmigaGradient(Bitmap: TBitmap; Pct: Integer);
// Klasyczna paleta copper 16 kolorów — 1:1 z p_FxAmigaGradient (image_fx_effects.hws:1852).
const
  GrR: array[0..15] of Byte = ($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$44,$88,$CC,$FF,$FF,$FF);
  GrG: array[0..15] of Byte = ($00,$00,$22,$44,$66,$88,$AA,$CC,$EE,$FF,$FF,$FF,$FF,$EE,$AA,$66);
  GrB: array[0..15] of Byte = ($88,$AA,$CC,$EE,$FF,$FF,$FF,$EE,$CC,$AA,$88,$44,$00,$00,$00,$00);
var
  W, H, X, Y, Bar, Cr, Cg, Cb, Pr, Pg, Pb: Integer;
  T: Double;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  T := Pct / 100.0;
  for Y := 0 to H - 1 do
  begin
    Bar := Y * 16 div H;
    if Bar > 15 then Bar := 15;
    Cr := GrR[Bar]; Cg := GrG[Bar]; Cb := GrB[Bar];
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Pr := Row[X].rgbtRed; Pg := Row[X].rgbtGreen; Pb := Row[X].rgbtBlue;
      Row[X].rgbtRed   := Byte(Trunc(Pr + (Cr - Pr) * T));
      Row[X].rgbtGreen := Byte(Trunc(Pg + (Cg - Pg) * T));
      Row[X].rgbtBlue  := Byte(Trunc(Pb + (Cb - Pb) * T));
    end;
  end;
end;

procedure ApplyAmigaGradientAgony(Bitmap: TBitmap; HueTop, HueBot, Bars: Integer);
// Tęczowe pasy w stylu Agony — 1:1 z p_FxAmigaGradientAgony (image_fx_effects.hws:2016).
var
  W, H, X, Y, Bar, Pr, Pg, Pb: Integer;
  Cr, Cg, Cb: Byte;
  T, Hue: Double;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  if Bars < 2 then Bars := 2;
  for Y := 0 to H - 1 do
  begin
    Bar := Y * Bars div H;
    if Bar > Bars - 1 then Bar := Bars - 1;
    T := Bar / (Bars - 1);
    Hue := HueTop + (HueBot - HueTop) * T;
    while Hue < 0 do Hue := Hue + 360;
    while Hue >= 360 do Hue := Hue - 360;
    HsvToRgb(Hue, 0.6, 0.7, Cr, Cg, Cb);
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Pr := Row[X].rgbtRed; Pg := Row[X].rgbtGreen; Pb := Row[X].rgbtBlue;
      Row[X].rgbtRed   := Byte(Trunc(Pr * 0.55 + Cr * 0.45));
      Row[X].rgbtGreen := Byte(Trunc(Pg * 0.55 + Cg * 0.45));
      Row[X].rgbtBlue  := Byte(Trunc(Pb * 0.55 + Cb * 0.45));
    end;
  end;
end;

procedure ApplyAmigaBackground(Bitmap: TBitmap; TargetW, TargetH: Integer; FillColor: TColor);
// 1:1 z p_AmigaBackground (image_fx.hws:619) — skala min (proporcje zachowane),
// wypełnienie tła kolorem, obraz wyśrodkowany.
var
  SrcW, SrcH, ScaleX, ScaleY, Scale, NewW, NewH, PosX, PosY: Integer;
  Scaled, OutBmp: TBitmap;
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;

  SrcW := Bitmap.Width;
  SrcH := Bitmap.Height;

  ScaleX := TargetW * 10000 div SrcW;
  ScaleY := TargetH * 10000 div SrcH;
  if ScaleX < ScaleY then Scale := ScaleX else Scale := ScaleY;
  NewW := Max(1, SrcW * Scale div 10000);
  NewH := Max(1, SrcH * Scale div 10000);

  PosX := (TargetW - NewW) div 2;
  PosY := (TargetH - NewH) div 2;

  Scaled := TBitmap.Create;
  try
    Scaled.PixelFormat := pf24bit;
    Scaled.SetSize(NewW, NewH);
    SetStretchBltMode(Scaled.Canvas.Handle, HALFTONE);
    Scaled.Canvas.StretchDraw(Rect(0, 0, NewW, NewH), Bitmap);

    OutBmp := TBitmap.Create;
    try
      OutBmp.PixelFormat := pf24bit;
      OutBmp.SetSize(TargetW, TargetH);
      OutBmp.Canvas.Brush.Color := FillColor;
      OutBmp.Canvas.FillRect(Rect(0, 0, TargetW, TargetH));
      OutBmp.Canvas.Draw(PosX, PosY, Scaled);
      Bitmap.Assign(OutBmp);
    finally
      OutBmp.Free;
    end;
  finally
    Scaled.Free;
  end;
end;

procedure ApplyAmigaBackgroundStretch(Bitmap: TBitmap; TargetW, TargetH: Integer);
// 1:1 z p_AmigaBackgroundStretch (image_fx.hws:672) — skala min, obraz wyśrodkowany,
// krawędzie (paski) rozciągnięte od brzegów obrazu, na końcu remap do palety MagicWB
// z ditheringiem (jak RemapBrush {Dither = True}).
var
  SrcW, SrcH, ScaleX, ScaleY, Scale, NewW, NewH, PosX, PosY: Integer;
  Scaled, OutBmp, Strip: TBitmap;
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  if (TargetW < 1) or (TargetH < 1) then Exit;

  SrcW := Bitmap.Width;
  SrcH := Bitmap.Height;

  ScaleX := TargetW * 10000 div SrcW;
  ScaleY := TargetH * 10000 div SrcH;
  if ScaleX < ScaleY then Scale := ScaleX else Scale := ScaleY;
  NewW := Max(1, SrcW * Scale div 10000);
  NewH := Max(1, SrcH * Scale div 10000);

  PosX := (TargetW - NewW) div 2;
  PosY := (TargetH - NewH) div 2;

  Scaled := TBitmap.Create;
  try
    Scaled.PixelFormat := pf24bit;
    Scaled.SetSize(NewW, NewH);
    SetStretchBltMode(Scaled.Canvas.Handle, HALFTONE);
    Scaled.Canvas.StretchDraw(Rect(0, 0, NewW, NewH), Bitmap);

    OutBmp := TBitmap.Create;
    try
      OutBmp.PixelFormat := pf24bit;
      OutBmp.SetSize(TargetW, TargetH);
      SetStretchBltMode(OutBmp.Canvas.Handle, HALFTONE);

      // Pasek lewy — 1px kolumna od lewej krawędzi, rozciągnięta w lewo
      if PosX > 0 then
      begin
        Strip := TBitmap.Create;
        try
          Strip.PixelFormat := pf24bit;
          Strip.SetSize(1, NewH);
          BitBlt(Strip.Canvas.Handle, 0, 0, 1, NewH, Scaled.Canvas.Handle, 0, 0, SRCCOPY);
          OutBmp.Canvas.StretchDraw(Rect(0, PosY, PosX, PosY + NewH), Strip);
        finally
          Strip.Free;
        end;
      end;

      // Pasek prawy — 1px kolumna od prawej krawędzi, rozciągnięta w prawo
      if PosX > 0 then
      begin
        Strip := TBitmap.Create;
        try
          Strip.PixelFormat := pf24bit;
          Strip.SetSize(1, NewH);
          BitBlt(Strip.Canvas.Handle, 0, 0, 1, NewH, Scaled.Canvas.Handle, NewW - 1, 0, SRCCOPY);
          OutBmp.Canvas.StretchDraw(Rect(PosX + NewW, PosY, TargetW, PosY + NewH), Strip);
        finally
          Strip.Free;
        end;
      end;

      // Pasek górny — 1px wiersz od górnej krawędzi, rozciągnięty w górę
      if PosY > 0 then
      begin
        Strip := TBitmap.Create;
        try
          Strip.PixelFormat := pf24bit;
          Strip.SetSize(NewW, 1);
          BitBlt(Strip.Canvas.Handle, 0, 0, NewW, 1, Scaled.Canvas.Handle, 0, 0, SRCCOPY);
          OutBmp.Canvas.StretchDraw(Rect(PosX, 0, PosX + NewW, PosY), Strip);
        finally
          Strip.Free;
        end;
      end;

      // Pasek dolny — 1px wiersz od dolnej krawędzi, rozciągnięty w dół
      if PosY > 0 then
      begin
        Strip := TBitmap.Create;
        try
          Strip.PixelFormat := pf24bit;
          Strip.SetSize(NewW, 1);
          BitBlt(Strip.Canvas.Handle, 0, 0, NewW, 1, Scaled.Canvas.Handle, 0, NewH - 1, SRCCOPY);
          OutBmp.Canvas.StretchDraw(Rect(PosX, PosY + NewH, PosX + NewW, TargetH), Strip);
        finally
          Strip.Free;
        end;
      end;

      // Wklej główny obraz
      OutBmp.Canvas.Draw(PosX, PosY, Scaled);
      Bitmap.Assign(OutBmp);
    finally
      OutBmp.Free;
    end;
  finally
    Scaled.Free;
  end;

  // Konwersja całego wyniku do palety MagicWB (Hollywood: RemapBrush {Dither = True})
  ApplyMagicWB(Bitmap, True);
end;

{ ------------------------------------------------------------------ }
{  INNE RETROKOMPUTERY                                              }
{ ------------------------------------------------------------------ }

const
  // C64 — Pepto (pal_type = 0), 16 kolorów
  C64Pepto_R: array[0..15] of Byte = ($00,$FF,$81,$75,$8E,$6B,$AB,$A7,$6B,$5A,$29,$32,$89,$55,$A3,$AC);
  C64Pepto_G: array[0..15] of Byte = ($00,$FF,$33,$CE,$54,$32,$32,$A7,$6B,$B3,$6B,$4F,$A3,$A3,$4B,$AC);
  C64Pepto_B: array[0..15] of Byte = ($00,$FF,$38,$48,$29,$96,$32,$A7,$6B,$4A,$A3,$AA,$AD,$49,$4B,$AC);

  // C64 — Colodore (pal_type = 1)
  C64Colo_R: array[0..15] of Byte = ($00,$FF,$68,$70,$6E,$40,$86,$9B,$44,$5E,$2D,$41,$65,$4E,$8C,$91);
  C64Colo_G: array[0..15] of Byte = ($00,$FF,$37,$A4,$3C,$31,$41,$A5,$44,$B8,$6D,$4B,$95,$9A,$3F,$91);
  C64Colo_B: array[0..15] of Byte = ($00,$FF,$2B,$41,$34,$8D,$2E,$9B,$44,$45,$A4,$9C,$95,$4E,$3F,$91);

  // ZX Spectrum — 8 normalnych + 8 bright (bright black = czarny)
  ZX_R: array[0..15] of Byte = ($00,$00,$D7,$D7,$00,$00,$D7,$D7,$00,$00,$FF,$FF,$00,$00,$FF,$FF);
  ZX_G: array[0..15] of Byte = ($00,$00,$00,$00,$D7,$D7,$D7,$D7,$00,$00,$00,$00,$FF,$FF,$FF,$FF);
  ZX_B: array[0..15] of Byte = ($00,$D7,$00,$D7,$00,$D7,$00,$D7,$00,$FF,$00,$FF,$00,$FF,$00,$FF);

  // Game Boy — DMG zielony (pal_type = 0)
  GBDMG_R: array[0..3] of Byte = ($9B,$8B,$30,$0F);
  GBDMG_G: array[0..3] of Byte = ($BC,$AC,$62,$38);
  GBDMG_B: array[0..3] of Byte = ($0F,$0F,$30,$0F);

  // Game Boy — Pocket szary (pal_type = 1)
  GBPocket_R: array[0..3] of Byte = ($AA,$66,$33,$00);
  GBPocket_G: array[0..3] of Byte = ($AA,$66,$33,$00);
  GBPocket_B: array[0..3] of Byte = ($AA,$66,$33,$00);

  // NES Nestopia — 56 kolorów (4 wiersze po 14)
  NES_R: array[0..55] of Byte = (
    $80,$00,$37,$84,$BB,$B7,$B7,$8F,$54,$1C,$00,$00,$00,$00,
    $BB,$00,$47,$AA,$FF,$FF,$FF,$CC,$66,$00,$00,$00,$00,$00,
    $FF,$00,$33,$B3,$FF,$FF,$FF,$FF,$99,$00,$00,$00,$00,$00,
    $FF,$55,$88,$CC,$FF,$FF,$FF,$FF,$CC,$00,$00,$00,$00,$00);
  NES_G: array[0..55] of Byte = (
    $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $BB,$55,$00,$00,$00,$00,$00,$33,$33,$00,$00,$00,$00,$00,
    $FF,$66,$33,$33,$33,$33,$66,$99,$99,$00,$00,$00,$00,$00,
    $FF,$AA,$88,$88,$88,$88,$AA,$CC,$CC,$00,$00,$00,$00,$00);
  NES_B: array[0..55] of Byte = (
    $80,$BB,$BF,$A6,$6A,$1E,$00,$00,$00,$00,$00,$00,$00,$00,
    $BB,$FF,$FF,$FF,$BB,$66,$19,$00,$00,$00,$00,$00,$00,$00,
    $FF,$FF,$FF,$FF,$FF,$99,$33,$19,$00,$00,$00,$00,$00,$00,
    $FF,$FF,$FF,$FF,$FF,$BB,$66,$55,$44,$00,$00,$00,$00,$00);

procedure ApplyC64(Bitmap: TBitmap; PalType, DitherMode: Integer);
// 1:1 z p_FxC64 (image_fx_effects.hws:1123).
// PalType: 0 = Pepto, 1 = Colodore.
// DitherMode: 0 = Floyd-Steinberg, 1 = bez roztrząsania, 2 = wzór 2x2 (retro).
var
  W, H, X, Y, I, Dr, Dg, Db, D: Integer;
  R, G, B: Byte;
  Lum: Double;
  NearestDark, NearestLight: Integer;
  MDark, MLight: Integer;
  PL: Double;
  Bayer: array[0..3] of Integer;
  Row: PRGBTripleArray;
  PalR, PalG, PalB: array[0..15] of Byte;
  Threshold: Integer;
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then Bitmap.PixelFormat := pf24bit;
  W := Bitmap.Width;
  H := Bitmap.Height;

  if PalType = 1 then
  begin
    Move(C64Colo_R, PalR, SizeOf(PalR));
    Move(C64Colo_G, PalG, SizeOf(PalG));
    Move(C64Colo_B, PalB, SizeOf(PalB));
  end
  else
  begin
    Move(C64Pepto_R, PalR, SizeOf(PalR));
    Move(C64Pepto_G, PalG, SizeOf(PalG));
    Move(C64Pepto_B, PalB, SizeOf(PalB));
  end;

  if DitherMode = 2 then
  begin
    // Pattern dither 2x2 — czyta ORYGINALNE piksele (Hollywood: p_C64PreviewUpdate / p_FxC64)
    Bayer[0] := 0; Bayer[1] := 128; Bayer[2] := 192; Bayer[3] := 64;
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        R := Row[X].rgbtRed;
        G := Row[X].rgbtGreen;
        B := Row[X].rgbtBlue;
        Lum := 0.299 * R + 0.587 * G + 0.114 * B;
        NearestDark := 0;
        NearestLight := 0;
        MDark := MaxInt;
        MLight := MaxInt;
        for I := 0 to 15 do
        begin
          PL := 0.299 * PalR[I] + 0.587 * PalG[I] + 0.114 * PalB[I];
          Dr := R - PalR[I];
          Dg := G - PalG[I];
          Db := B - PalB[I];
          D := Dr * Dr + Dg * Dg + Db * Db;
          if (PL <= Lum) and (D < MDark) then
          begin
            MDark := D;
            NearestDark := I;
          end;
          if (PL > Lum) and (D < MLight) then
          begin
            MLight := D;
            NearestLight := I;
          end;
        end;
        if MLight = MaxInt then NearestLight := NearestDark;
        if MDark = MaxInt then NearestDark := NearestLight;
        Threshold := Bayer[(X mod 2) * 2 + (Y mod 2)];
        if Lum > Threshold then I := NearestLight else I := NearestDark;
        Row[X].rgbtRed := PalR[I];
        Row[X].rgbtGreen := PalG[I];
        Row[X].rgbtBlue := PalB[I];
      end;
    end;
  end
  else
    RemapToPalette(Bitmap, PalR, PalG, PalB, DitherMode = 0);
end;

procedure ApplyZXSpectrum(Bitmap: TBitmap; Dither: Boolean);
// 1:1 z p_FxZXSpectrum (image_fx_effects.hws:1194).
begin
  RemapToPalette(Bitmap, ZX_R, ZX_G, ZX_B, Dither);
end;

procedure ApplyGameBoy(Bitmap: TBitmap; PalType: Integer; Dither: Boolean);
// 1:1 z p_FxGameBoy (image_fx_effects.hws:1206).
// PalType: 0 = DMG (zielony), 1 = Pocket (szary).
begin
  if PalType = 1 then
    RemapToPalette(Bitmap, GBPocket_R, GBPocket_G, GBPocket_B, Dither)
  else
    RemapToPalette(Bitmap, GBDMG_R, GBDMG_G, GBDMG_B, Dither);
end;

procedure ApplyNES(Bitmap: TBitmap; Dither: Boolean);
// 1:1 z p_FxNESNestopia (image_fx_effects.hws:1225).
begin
  RemapToPalette(Bitmap, NES_R, NES_G, NES_B, Dither);
end;

end.
