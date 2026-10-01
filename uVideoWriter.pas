unit uVideoWriter;

// Renderer MP4/H.264 przez Media Foundation Sink Writer (scenariusz A).
// Output type H264/MP4, input NV12; Sink Writer sam dobiera MFT enkodera
// (MFCreateSinkWriterFromURL + SetInputMediaType — wzorzec MSDN "Tutorial:
// Using the Sink Writer to Encode Video"). Fallback: WMV3 w .wmv, gdy H264
// MFT niedostępny. Konwersja RGB(BMP)→NV12 wg BT.601 (mnożniki Y/U/V 8-bitowe
// z dokumentacji Microsoft YUV). Sekwencja wywołań interfejsów:
// IMFSinkWriter.AddStream/SetInputMediaType/BeginWriting/WriteSample/Finalize
// — sygnatury ze SDK 10.0.26100, dowody w uMediaFoundation.pas.

interface

uses
  System.SysUtils, System.Math,
  Winapi.Windows,
  Vcl.Graphics,
  uMediaFoundation, uI18n;

type
  EVideoWriterError = class(Exception);

  TVideoWriter = class
  private
    FOutputPath: string;
    FWidth: Integer;
    FHeight: Integer;
    FFrameDuration: Int64;
    FSampleTime: Int64;
    FSink: IMFSinkWriter;
    FStreamIndex: DWORD;
    FActive: Boolean;
    FStartupRefs: Integer;
    FFrameRateNum: Integer;
    FFrameRateDen: Integer;
    procedure SetupWriter(const AOutputFile: string; const ASubtype: TGUID);
    procedure FillNV12(ABmp: TBitmap; Dst: PByte);
  public
    constructor Create(const AOutputPath: string; AWidth, AHeight: Integer;
      AFPS: Double);
    destructor Destroy; override;
    procedure AddFrame(ABmp: TBitmap);
    procedure Finalize;
    property OutputPath: string read FOutputPath;
  end;

implementation

const
  HNS_PER_SEC = 10000000;

constructor TVideoWriter.Create(const AOutputPath: string; AWidth, AHeight: Integer;
  AFPS: Double);
var
  Hr: HRESULT;
  FPS: Double;
begin
  inherited Create;
  if AFPS <= 0 then
    raise EVideoWriterError.Create(T('Invalid frame rate'));
  if AWidth <= 0 then
    AWidth := 1;
  if AHeight <= 0 then
    AHeight := 1;
  if (AWidth mod 2) <> 0 then
    Dec(AWidth);
  if (AHeight mod 2) <> 0 then
    Dec(AHeight);
  FWidth := AWidth;
  FHeight := AHeight;
  if FWidth < 2 then
    FWidth := 2;
  if FHeight < 2 then
    FHeight := 2;
  FPS := AFPS;
  if FPS > 1000 then
    FPS := 1000;
  FFrameDuration := Round(HNS_PER_SEC / FPS);
  FFrameRateNum := Round(FPS * 1000);
  FFrameRateDen := 1000;
  FSampleTime := 0;
  FOutputPath := AOutputPath;
  FStreamIndex := 0;
  FActive := False;
  FStartupRefs := 0;

  Hr := MFStartup(MF_VERSION, 0);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding'));
  Inc(FStartupRefs);

  try
    SetupWriter(FOutputPath, MFVideoFormat_H264);
    FActive := True;
  except
    on E: Exception do
    begin
      FOutputPath := ChangeFileExt(FOutputPath, '.wmv');
      FSink := nil;
      try
        SetupWriter(FOutputPath, MFVideoFormat_WMV3);
        FActive := True;
      except
        on E2: Exception do
        begin
          FActive := False;
          raise EVideoWriterError.Create(T('No video encoder available (H.264 or WMV)') +
            ' [' + E.Message + ']');
        end;
      end;
    end;
  end;
end;

destructor TVideoWriter.Destroy;
begin
  FSink := nil;
  while FStartupRefs > 0 do
  begin
    MFShutdown;
    Dec(FStartupRefs);
  end;
  inherited Destroy;
end;

procedure TVideoWriter.SetupWriter(const AOutputFile: string; const ASubtype: TGUID);
var
  Hr: HRESULT;
  OutType: IMFMediaType;
  InType: IMFMediaType;
  Attr: IMFAttributes;
  FrameSize: Int64;
  FrameRate: Int64;
begin
  FrameSize := (Int64(FWidth) shl 32) or FHeight;
  FrameRate := (Int64(FFrameRateNum) shl 32) or DWORD(FFrameRateDen);

  Hr := MFCreateSinkWriterFromURL(PWideChar(AOutputFile), nil, nil, FSink);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot create output file') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');

  Hr := MFCreateMediaType(OutType);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetGUID(MF_MT_SUBTYPE, ASubtype);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetUINT64(MF_MT_FRAME_SIZE, FrameSize);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetUINT64(MF_MT_FRAME_RATE, FrameRate);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetUINT64(MF_MT_PIXEL_ASPECT_RATIO, (Int64(1) shl 32) or 1);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetUINT32(MF_MT_AVG_BITRATE, 8000000);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := OutType.SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');

  Hr := FSink.AddStream(OutType, FStreamIndex);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot create video stream') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');

  Hr := MFCreateMediaType(InType);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetGUID(MF_MT_SUBTYPE, MFVideoFormat_NV12);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetUINT64(MF_MT_FRAME_SIZE, FrameSize);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetUINT64(MF_MT_FRAME_RATE, FrameRate);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetUINT64(MF_MT_PIXEL_ASPECT_RATIO, (Int64(1) shl 32) or 1);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');
  Hr := InType.SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
      IntToHex(Cardinal(Hr), 8) + ')');

  Attr := nil;
  try
    Hr := MFCreateAttributes(Attr, 3);
    if Failed(Hr) then
      raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
        IntToHex(Cardinal(Hr), 8) + ')');
    if IsEqualGUID(ASubtype, MFVideoFormat_H264) then
    begin
      Hr := Attr.SetUINT32(CODECAPI_AVEncMPVGOPSize, 1);
      if Failed(Hr) then
        raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
          IntToHex(Cardinal(Hr), 8) + ')');
      Hr := Attr.SetUINT32(CODECAPI_AVEncCommonRateControlMode,
        eAVEncCommonRateControlMode_Quality);
      if Failed(Hr) then
        raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
          IntToHex(Cardinal(Hr), 8) + ')');
      Hr := Attr.SetUINT32(CODECAPI_AVEncCommonMeanBitRate, 8000000);
      if Failed(Hr) then
        raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
          IntToHex(Cardinal(Hr), 8) + ')');
    end;
    Hr := FSink.SetInputMediaType(FStreamIndex, InType, Attr);
    if Failed(Hr) then
      raise EVideoWriterError.Create(T('Cannot initialize video encoder') + ' (0x' +
        IntToHex(Cardinal(Hr), 8) + ')');
    Hr := FSink.BeginWriting;
    if Failed(Hr) then
      raise EVideoWriterError.Create(T('Cannot start writing video') + ' (0x' +
        IntToHex(Cardinal(Hr), 8) + ')');
  finally
    Attr := nil;
  end;
end;

procedure TVideoWriter.FillNV12(ABmp: TBitmap; Dst: PByte);
var
  W, H, X, Y: Integer;
  RowE, RowO: PByte;
  pY, pC: PByte;
  B, G, R, B2, G2, R2: Integer;
  U, V: Integer;
  Bpp: Integer;
  Pf: TPixelFormat;
begin
  W := Min(ABmp.Width, FWidth);
  H := Min(ABmp.Height, FHeight);
  Pf := ABmp.PixelFormat;
  if Pf = pf32bit then
    Bpp := 4
  else
    Bpp := 3;

  pY := Dst;
  for Y := 0 to H - 1 do
  begin
    RowE := ABmp.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      B := RowE[X * Bpp];
      G := RowE[X * Bpp + 1];
      R := RowE[X * Bpp + 2];
      pY[X] := Byte((66 * R + 129 * G + 25 * B + 128) shr 8 + 16);
    end;
    Inc(pY, FWidth);
  end;

  pC := Dst + Int64(FWidth) * FHeight;
  Y := 0;
  while Y < H do
  begin
    RowE := ABmp.ScanLine[Y];
    if (Y + 1) < H then
    begin
      RowO := ABmp.ScanLine[Y + 1];
      for X := 0 to (W div 2) - 1 do
      begin
        B := RowE[X * 2 * Bpp];
        G := RowE[X * 2 * Bpp + 1];
        R := RowE[X * 2 * Bpp + 2];
        B2 := RowO[X * 2 * Bpp];
        G2 := RowO[X * 2 * Bpp + 1];
        R2 := RowO[X * 2 * Bpp + 2];
        U := (-38 * (R + R2) - 74 * (G + G2) + 112 * (B + B2) + 256) div 512 + 128;
        V := (112 * (R + R2) - 94 * (G + G2) - 18 * (B + B2) + 256) div 512 + 128;
        if U < 0 then
          U := 0
        else if U > 255 then
          U := 255;
        if V < 0 then
          V := 0
        else if V > 255 then
          V := 255;
        pC^ := Byte(U);
        Inc(pC);
        pC^ := Byte(V);
        Inc(pC);
      end;
      Inc(Y, 2);
    end
    else
    begin
      // Ostatni nieparzysty wiersz: chroma z pojedynczego wiersza.
      for X := 0 to (W div 2) - 1 do
      begin
        B := RowE[X * 2 * Bpp];
        G := RowE[X * 2 * Bpp + 1];
        R := RowE[X * 2 * Bpp + 2];
        U := (-38 * R - 74 * G + 112 * B + 128) shr 8 + 128;
        V := (112 * R - 94 * G - 18 * B + 128) shr 8 + 128;
        if U < 0 then
          U := 0
        else if U > 255 then
          U := 255;
        if V < 0 then
          V := 0
        else if V > 255 then
          V := 255;
        pC^ := Byte(U);
        Inc(pC);
        pC^ := Byte(V);
        Inc(pC);
      end;
      Inc(Y);
    end;
  end;
end;

procedure TVideoWriter.AddFrame(ABmp: TBitmap);
var
  Hr: HRESULT;
  Sample: IMFSample;
  Buffer: IMFMediaBuffer;
  Ptr: PByte;
  BufLen: Integer;
  MaxLen, CurLen: DWORD;
begin
  if not FActive then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  if ABmp = nil then
    raise EVideoWriterError.Create(T('Cannot write video frame'));

  BufLen := FWidth * FHeight * 3 div 2;
  if Failed(MFCreateSample(Sample)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  if Failed(MFCreateMemoryBuffer(DWORD(BufLen), Buffer)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));

  if Failed(Buffer.Lock(Ptr, MaxLen, CurLen)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  try
    FillChar(Ptr^, BufLen, 0);
    FillNV12(ABmp, Ptr);
  finally
    Buffer.Unlock;
  end;
  if Failed(Buffer.SetCurrentLength(DWORD(BufLen))) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));

  if Failed(Sample.SetSampleTime(FSampleTime)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  if Failed(Sample.SetSampleDuration(FFrameDuration)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  if Failed(Sample.AddBuffer(Buffer)) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));

  Hr := FSink.WriteSample(FStreamIndex, Sample);
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot write video frame'));
  Inc(FSampleTime, FFrameDuration);
end;

procedure TVideoWriter.Finalize;
var
  Hr: HRESULT;
begin
  if not FActive then
    exit;
  Hr := FSink.Finalize;
  if Failed(Hr) then
    raise EVideoWriterError.Create(T('Cannot save video file'));
  FActive := False;
end;

end.