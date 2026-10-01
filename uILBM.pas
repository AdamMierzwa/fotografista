unit uILBM;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Graphics;

function LoadILBM(const APath: string): TBitmap;

implementation

type
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTriple = ^TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

function BE16(P: PByte): Word;
begin
  Result := (Word(P[0]) shl 8) or P[1];
end;

function BE32(P: PByte): Cardinal;
begin
  Result := (Cardinal(P[0]) shl 24) or (Cardinal(P[1]) shl 16) or
            (Cardinal(P[2]) shl 8) or P[3];
end;

// ILBM ByteRun1: 0..127 = literal run of N+1 bytes, 129..255 = repeat next
// byte (257-N) times, 128 = no-op. Returns source pointer after consumed runs.
function DecodeByteRun1(Src, SrcEnd, Dst: PByte; Count: Integer): PByte;
var
  N: Integer;
  B: Byte;
begin
  Result := Src;
  while Count > 0 do
  begin
    if Result >= SrcEnd then Break;
    B := Result^;
    Inc(Result);
    if B = 128 then Continue;
    if B < 128 then
    begin
      N := B + 1;
      if N > Count then N := Count;
      if NativeInt(SrcEnd) - NativeInt(Result) < N then
        N := Integer(NativeInt(SrcEnd) - NativeInt(Result));
      if N <= 0 then Break;
      Move(Result^, Dst^, N);
      Inc(Result, N);
      Inc(Dst, N);
      Dec(Count, N);
    end
    else
    begin
      N := 257 - B;
      if N > Count then N := Count;
      if Result >= SrcEnd then Break;
      FillChar(Dst^, N, Result^);
      Inc(Result);
      Inc(Dst, N);
      Dec(Count, N);
    end;
  end;
end;

function LoadILBM(const APath: string): TBitmap;
var
  FS: TFileStream;
  Data: TBytes;
  Off: Integer;
  ChunkID: string;
  ChunkSize: Cardinal;
  DataOfs: Cardinal;
  W, H, NPlanes, Masking, Compression: Integer;
  RowSize, PlaneCount, ColorCount: Integer;
  I, X, Y, P, Idx, Ctl, Val, Ci, C8: Integer;
  CurR, CurG, CurB: Integer;
  IsEHB, IsHAM: Boolean;
  HasCamg, HasSham: Boolean;
  CamgMode: Cardinal;
  ColR, ColG, ColB: array of Byte;
  BODY: array of Byte;
  BODYLen: Integer;
  PlaneData: array of Byte;
  Src, SrcEnd: PByte;
  Row: PRGBTripleArray;
  R, G, B: Byte;
  BitNo, ByteOff: Integer;
begin
  Result := nil;
  FS := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Data, FS.Size);
    if FS.Size > 0 then
      FS.ReadBuffer(Data[0], Integer(FS.Size));
  finally
    FS.Free;
  end;

  if Length(Data) < 12 then
    raise Exception.Create('Not an IFF file.');
  if (Data[0] <> Ord('F')) or (Data[1] <> Ord('O')) or
     (Data[2] <> Ord('R')) or (Data[3] <> Ord('M')) then
    raise Exception.Create('Not an IFF file.');
  if (Data[8] <> Ord('I')) or (Data[9] <> Ord('L')) or
     (Data[10] <> Ord('B')) or (Data[11] <> Ord('M')) then
    raise Exception.Create('Not an IFF ILBM file.');

  Off := 12;
  W := 0; H := 0; NPlanes := 0; Masking := 0; Compression := 0;
  ColorCount := 0;
  HasCamg := False; HasSham := False; CamgMode := 0;
  BODY := nil; BODYLen := 0;

  while Off + 8 <= Length(Data) do
  begin
    ChunkID := '';
    for I := 0 to 3 do
      ChunkID := ChunkID + Char(Data[Off + I]);
    ChunkSize := BE32(PByte(@Data[Off + 4]));
    DataOfs := Off + 8;
    if DataOfs + ChunkSize > Cardinal(Length(Data)) then
      ChunkSize := Length(Data) - Integer(DataOfs);

    if ChunkID = 'BMHD' then
    begin
      if ChunkSize < 20 then
        raise Exception.Create('Invalid ILBM header (BMHD).');
      W := BE16(PByte(@Data[DataOfs]));
      H := BE16(PByte(@Data[DataOfs + 2]));
      NPlanes := Data[DataOfs + 8];
      Masking := Data[DataOfs + 9];
      Compression := Data[DataOfs + 10];
    end
    else if ChunkID = 'CMAP' then
    begin
      ColorCount := Integer(ChunkSize) div 3;
      if ColorCount > 0 then
      begin
        SetLength(ColR, ColorCount);
        SetLength(ColG, ColorCount);
        SetLength(ColB, ColorCount);
        for I := 0 to ColorCount - 1 do
        begin
          ColR[I] := Data[Integer(DataOfs) + I * 3];
          ColG[I] := Data[Integer(DataOfs) + I * 3 + 1];
          ColB[I] := Data[Integer(DataOfs) + I * 3 + 2];
        end;
      end;
    end
    else if ChunkID = 'CAMG' then
    begin
      if ChunkSize >= 4 then
      begin
        CamgMode := BE32(PByte(@Data[DataOfs]));
        HasCamg := True;
      end;
    end
    else if ChunkID = 'SHAM' then
      HasSham := True
    else if ChunkID = 'BODY' then
    begin
      BODYLen := Integer(ChunkSize);
      SetLength(BODY, BODYLen);
      Move(Data[DataOfs], BODY[0], BODYLen);
    end;

    Off := Integer(DataOfs) + Integer(ChunkSize) + (Integer(ChunkSize) and 1);
  end;

  if (W <= 0) or (H <= 0) or (NPlanes <= 0) then
    raise Exception.Create('Invalid ILBM dimensions.');
  if BODYLen = 0 then
    raise Exception.Create('ILBM image has no BODY chunk.');
  if (Compression <> 0) and (Compression <> 1) then
    raise Exception.Create('Unsupported ILBM compression.');

  // EHB / HAM detection: CAMG mode bits (0x40 = EHB, 0x800 = HAM) win;
  // otherwise guess from plane count + palette size. SHAM always means HAM8.
  if HasCamg then
  begin
    IsEHB := (CamgMode and $40) <> 0;
    IsHAM := (CamgMode and $800) <> 0;
  end
  else
  begin
    IsEHB := False;
    IsHAM := False;
    if NPlanes = 6 then
    begin
      if ColorCount <= 16 then IsHAM := True
      else if ColorCount <= 32 then IsEHB := True;
    end
    else if (NPlanes = 8) and (ColorCount <= 64) then
      IsHAM := True;
  end;
  if HasSham then
    IsHAM := True;

  RowSize := ((W + 15) div 16) * 2;
  PlaneCount := NPlanes;
  if Masking = 1 then
    Inc(PlaneCount);

  SetLength(PlaneData, PlaneCount * H * RowSize);
  Src := @BODY[0];
  SrcEnd := @BODY[BODYLen - 1];
  Inc(SrcEnd);
  for Y := 0 to H - 1 do
    for P := 0 to PlaneCount - 1 do
    begin
      if Compression = 1 then
        Src := DecodeByteRun1(Src, SrcEnd, @PlaneData[(Y * PlaneCount + P) * RowSize], RowSize)
      else
      begin
        if NativeInt(SrcEnd) - NativeInt(Src) < RowSize then Break;
        Move(Src^, PlaneData[(Y * PlaneCount + P) * RowSize], RowSize);
        Inc(Src, RowSize);
      end;
    end;

  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.Width := W;
    Result.Height := H;
  except
    Result.Free;
    raise;
  end;

  CurR := 0; CurG := 0; CurB := 0;
  if ColorCount > 0 then
  begin
    CurR := ColR[0];
    CurG := ColG[0];
    CurB := ColB[0];
  end;

  for Y := 0 to H - 1 do
  begin
    Row := Result.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Idx := 0;
      BitNo := 7 - (X and 7);
      ByteOff := X shr 3;
      for P := 0 to NPlanes - 1 do
        if ((PlaneData[(Y * PlaneCount + P) * RowSize + ByteOff] shr BitNo) and 1) <> 0 then
          Idx := Idx or (1 shl P);

      if IsHAM then
      begin
        if NPlanes > 6 then
        begin
          Ctl := (Idx shr 6) and 3;
          Val := Idx and 63;
          C8 := (Val shl 2) or (Val shr 4);
          case Ctl of
            0: if Val < ColorCount then
               begin
                 CurR := ColR[Val];
                 CurG := ColG[Val];
                 CurB := ColB[Val];
               end;
            1: CurB := C8;
            2: CurR := C8;
            3: CurG := C8;
          end;
        end
        else
        begin
          Ctl := (Idx shr 4) and 3;
          Val := Idx and 15;
          case Ctl of
            0: if Val < ColorCount then
               begin
                 CurR := ColR[Val];
                 CurG := ColG[Val];
                 CurB := ColB[Val];
               end;
            1: CurB := Val * 17;
            2: CurR := Val * 17;
            3: CurG := Val * 17;
          end;
        end;
        Row[X].R := CurR;
        Row[X].G := CurG;
        Row[X].B := CurB;
      end
      else if IsEHB then
      begin
        Ci := Idx and 31;
        if (Idx and 32) <> 0 then
        begin
          if Ci < ColorCount then
          begin
            R := ColR[Ci] shr 1;
            G := ColG[Ci] shr 1;
            B := ColB[Ci] shr 1;
          end
          else
          begin
            R := 0; G := 0; B := 0;
          end;
        end
        else
        begin
          if Ci < ColorCount then
          begin
            R := ColR[Ci];
            G := ColG[Ci];
            B := ColB[Ci];
          end
          else
          begin
            R := 0; G := 0; B := 0;
          end;
        end;
        Row[X].R := R;
        Row[X].G := G;
        Row[X].B := B;
      end
      else
      begin
        if Idx < ColorCount then
        begin
          R := ColR[Idx];
          G := ColG[Idx];
          B := ColB[Idx];
        end
        else
        begin
          R := 0; G := 0; B := 0;
        end;
        Row[X].R := R;
        Row[X].G := G;
        Row[X].B := B;
      end;
    end;
  end;
end;

end.
