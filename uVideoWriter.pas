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
  Winapi.Windows, Winapi.ActiveX,
  Winapi.DXGI, Winapi.D3D11, Winapi.D3DCommon,
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
    FHardware: Boolean;
    FEncoderInfo: string;
    FD3DDevice: IUnknown;                 // ID3D11Device wydajnej karty
    FD3DManager: IMFDXGIDeviceManager;    // daje to urzadzenie koderowi
    procedure QueryEncoderInfo;
    function CreatePerformanceD3DManager: Boolean;
    procedure SetupWriter(const AOutputFile: string; const ASubtype: TGUID;
      AHardware, AD3D: Boolean);
    procedure FillNV12(ABmp: TBitmap; Dst: PByte);
  public
    // AUseHardware: najpierw koder karty graficznej (Prefs.UseGPU); gdy go
    // nie ma albo odrzuci ustawienia - koder programowy jak dotad.
    constructor Create(const AOutputPath: string; AWidth, AHeight: Integer;
      AFPS: Double; AUseHardware: Boolean = False);
    destructor Destroy; override;
    procedure AddFrame(ABmp: TBitmap);
    procedure Finalize;
    property OutputPath: string read FOutputPath;
    // True = zapis z dopuszczonym koderem sprzetowym (Windows wybiera koder sam)
    property Hardware: Boolean read FHardware;
    // Czym faktycznie zakodowano film: T('graphics card') - koder sprzetowy,
    // T('processor') - programowy, '' = nie wiadomo
    property EncoderInfo: string read FEncoderInfo;
  end;

// Karty graficzne z listy Windows (DXGI), bez programowej, kazda nazwa raz.
// Chosen = indeks karty, ktora zapis wideo wskazuje koderowi (najwiecej
// wlasnej pamieci graficznej - ta sama regula co CreatePerformanceD3DManager),
// -1 = brak.
function GraphicsAdapterNames(out Chosen: Integer): TArray<string>;

implementation

const
  HNS_PER_SEC = 10000000;

constructor TVideoWriter.Create(const AOutputPath: string; AWidth, AHeight: Integer;
  AFPS: Double; AUseHardware: Boolean);
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

  FHardware := False;
  // Koder sprzetowy: proba, a przy bledzie konfiguracji (brak kodera, limit
  // rozmiaru, odrzucone ustawienia GOP/jakosci) - po cichu dalej programowo.
  // Najpierw koder sprzetowy wydajnej karty (wskazanej przez program, bez
  // ustawien grafiki w Windows), potem sprzetowy wybrany przez Windows.
  if AUseHardware then
  try
    SetupWriter(FOutputPath, MFVideoFormat_H264, True, True);
    FActive := True;
    FHardware := True;
  except
    FSink := nil;
    FD3DManager := nil;
    FD3DDevice := nil;
  end;
  if AUseHardware and not FActive then
  try
    SetupWriter(FOutputPath, MFVideoFormat_H264, True, False);
    FActive := True;
    FHardware := True;
  except
    FSink := nil;
  end;

  if not FActive then
  try
    SetupWriter(FOutputPath, MFVideoFormat_H264, False, False);
    FActive := True;
  except
    on E: Exception do
    begin
      FOutputPath := ChangeFileExt(FOutputPath, '.wmv');
      FSink := nil;
      try
        SetupWriter(FOutputPath, MFVideoFormat_WMV3, False, False);
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
  QueryEncoderInfo;
end;

// Ktory koder Media Foundation faktycznie dobral: GetServiceForStream dla
// strumienia z GUID_NULL pyta koder strumienia (MS Learn,
// IMFSinkWriter::GetServiceForStream, Remarks). Koder sprzetowy ma w
// GetAttributes atrybut MFT_ENUM_HARDWARE_URL_Attribute (MS Learn, "Hardware
// MFTs"). Uzytkownik dostaje tylko to, co pewne i zrozumiale: karta graficzna
// albo procesor (nazwy koderow - MFT, HMFT, Quick Sync - mylily, bo koder
// posredniczacy Windows nie wystepuje na liscie koderow). Blad = ''.
procedure TVideoWriter.QueryEncoderInfo;
var
  P: Pointer;
  Mft: IMFTransform;
  Attr: IMFAttributes;
  W: PWideChar;
  Len: DWORD;
begin
  FEncoderInfo := '';
  if (FSink = nil) or not FActive then Exit;
  P := nil;
  if Failed(FSink.GetServiceForStream(FStreamIndex, GUID_NULL_MF, IID_IMFTransform, P))
    or (P = nil) then Exit;
  Pointer(Mft) := P;    // przejecie referencji zwroconej przez metode (bez AddRef)
  if Failed(Mft.GetAttributes(Attr)) or (Attr = nil) then Exit;
  if Succeeded(Attr.GetAllocatedString(MFT_ENUM_HARDWARE_URL_Attribute, W, Len)) then
  begin
    CoTaskMemFree(W);
    FEncoderInfo := T('graphics card');
  end
  else
    FEncoderInfo := T('processor');
end;

type
  // Winapi.D3D10.pas:2612 ID3D10Multithread - lokalnie, bez calego Winapi.D3D10
  ID3D10MultithreadLocal = interface(IUnknown)
    ['{9B7E4E00-342C-4106-A19F-4F2704F689F0}']
    procedure Enter; stdcall;
    procedure Leave; stdcall;
    function SetMultithreadProtected(bMTProtect: BOOL): BOOL; stdcall;
    function GetMultithreadProtected: BOOL; stdcall;
  end;

const
  cD3D11CreateDeviceVideoSupport = $800;   // d3d11.h:15011 (brak w Winapi.D3D11)
  cDXGIAdapterFlagSoftware = 2;            // Winapi.DXGI.pas:527

// Karty z listy Windows (DXGI), bez programowej; Best = najwiecej wlasnej
// pamieci graficznej (IDXGIFactory6 z wyborem wg wydajnosci nie ma
// w Winapi.DXGI). Jedna regula dla wyboru karty i dla okna Wydajnosc.
function EnumPerformanceAdapters(out Adapters: TArray<IDXGIAdapter1>;
  out Names: TArray<string>; out Best: Integer): Boolean;
var
  Factory: IDXGIFactory1;
  Adapter: IDXGIAdapter1;
  Desc: TDXGIAdapterDesc1;
  BestMem: UInt64;
  I: UINT;
begin
  Adapters := nil;
  Names := nil;
  Best := -1;
  Result := False;
  try
    if Failed(CreateDXGIFactory1(IDXGIFactory1, Factory)) then Exit;
    BestMem := 0;
    I := 0;
    while Succeeded(Factory.EnumAdapters1(I, Adapter)) do
    begin
      if Succeeded(Adapter.GetDesc1(Desc)) and
         ((Desc.Flags and cDXGIAdapterFlagSoftware) = 0) then
      begin
        Adapters := Adapters + [Adapter];
        Names := Names + [string(PWideChar(@Desc.Description[0]))];
        if (Best < 0) or (UInt64(Desc.DedicatedVideoMemory) > BestMem) then
        begin
          Best := High(Adapters);
          BestMem := UInt64(Desc.DedicatedVideoMemory);
        end;
      end;
      Adapter := nil;
      Inc(I);
    end;
    Result := Best >= 0;
  except
    // np. brak dxgi.dll (import opozniony)
    Result := False;
  end;
end;

function GraphicsAdapterNames(out Chosen: Integer): TArray<string>;
var
  Adapters: TArray<IDXGIAdapter1>;
  Names: TArray<string>;
  Best, I, K: Integer;
  Dup: Boolean;
begin
  Result := nil;
  Chosen := -1;
  if not EnumPerformanceAdapters(Adapters, Names, Best) then Exit;
  // wybrana karta pierwsza, reszta po kolei, kazda nazwa raz
  Result := [Names[Best]];
  Chosen := 0;
  for I := 0 to High(Names) do
  begin
    Dup := False;
    for K := 0 to High(Result) do
      if CompareText(Result[K], Names[I]) = 0 then Dup := True;
    if not Dup then
      Result := Result + [Names[I]];
  end;
end;

// Urzadzenie Direct3D 11 na wydajnej karcie i menedzer DXGI dla Sink Writera
// (MF_SINK_WRITER_D3D_MANAGER). MFCreateDXGIDeviceManager przez GetProcAddress
// (Windows 8+). Kazdy blad = False i dalej bez wskazania karty.
function TVideoWriter.CreatePerformanceD3DManager: Boolean;
var
  CreateMgr: TMFCreateDXGIDeviceManager;
  Adapters: TArray<IDXGIAdapter1>;
  Names: TArray<string>;
  Best: Integer;
  Dev: ID3D11Device;
  Ctx: ID3D11DeviceContext;
  FL: D3D_FEATURE_LEVEL;
  MT: ID3D10MultithreadLocal;
  Token: UINT;
  Mgr: IMFDXGIDeviceManager;
begin
  Result := False;
  FD3DManager := nil;
  FD3DDevice := nil;
  @CreateMgr := GetProcAddress(GetModuleHandle('mfplat.dll'), 'MFCreateDXGIDeviceManager');
  if not Assigned(CreateMgr) then Exit;
  try
    if not EnumPerformanceAdapters(Adapters, Names, Best) then Exit;
    if Failed(D3D11CreateDevice(Adapters[Best], D3D_DRIVER_TYPE_UNKNOWN, 0,
        cD3D11CreateDeviceVideoSupport, nil, 0, D3D11_SDK_VERSION, Dev, FL, Ctx)) then Exit;
    // Media Foundation uzywa urzadzenia z wielu watkow
    if Supports(Dev, ID3D10MultithreadLocal, MT) then
      MT.SetMultithreadProtected(True);
    if Failed(CreateMgr(Token, Mgr)) then Exit;
    if Failed(Mgr.ResetDevice(Dev, Token)) then Exit;
    FD3DDevice := Dev;
    FD3DManager := Mgr;
    Result := True;
  except
    // np. brak d3d11.dll / dxgi.dll (import opozniony) - bez wskazania karty
    Result := False;
  end;
end;

destructor TVideoWriter.Destroy;
begin
  FSink := nil;
  FD3DManager := nil;
  FD3DDevice := nil;
  while FStartupRefs > 0 do
  begin
    MFShutdown;
    Dec(FStartupRefs);
  end;
  inherited Destroy;
end;

procedure TVideoWriter.SetupWriter(const AOutputFile: string; const ASubtype: TGUID;
  AHardware, AD3D: Boolean);
var
  Hr: HRESULT;
  OutType: IMFMediaType;
  InType: IMFMediaType;
  Attr: IMFAttributes;
  WriterAttr: IMFAttributes;
  FrameSize: Int64;
  FrameRate: Int64;
begin
  FrameSize := (Int64(FWidth) shl 32) or FHeight;
  FrameRate := (Int64(FFrameRateNum) shl 32) or DWORD(FFrameRateDen);

  WriterAttr := nil;
  if AHardware then
  begin
    Hr := MFCreateAttributes(WriterAttr, 2);
    if Succeeded(Hr) then
      Hr := WriterAttr.SetUINT32(MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS, 1);
    if Failed(Hr) then
      raise EVideoWriterError.Create(T('Cannot initialize video encoding') + ' (0x' +
        IntToHex(Cardinal(Hr), 8) + ')');
    // wskazanie wydajnej karty; bez niej (Windows 7, blad) koder wybiera Windows
    if AD3D and CreatePerformanceD3DManager then
      if Failed(WriterAttr.SetUnknown(MF_SINK_WRITER_D3D_MANAGER, FD3DManager)) then
      begin
        FD3DManager := nil;
        FD3DDevice := nil;
      end;
  end;
  Hr := MFCreateSinkWriterFromURL(PWideChar(AOutputFile), nil, WriterAttr, FSink);
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