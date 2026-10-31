unit uMediaFoundation;

// Zweryfikowane z Windows SDK 10.0.26100 (Windows 11):
//   MFStartup / MFShutdown / MFCreateMemoryBuffer / MFCreateSample /
//   MFCreateMediaType / MF_VERSION   - mfapi.h:70,96,457,897,3804,31-40
//   MFCreateSinkWriterFromURL        - mfreadwrite.h:1195
//   IMFAttributes (30 metod, order)  - mfobjects.h:441-643
//   IMFMediaBuffer (Lock..GetMaxLength) - mfobjects.h:828-879
//   IMFSample (dziedziczy IMFAttributes) - mfobjects.h:996-1275
//   IMFMediaType (dziedziczy IMFAttributes) - mfobjects.h:2151-2379
//   IMFSinkWriter (AddStream..GetStatistics) - mfreadwrite.h:1333-1435
//   MF_MT_* / MFMediaType_Video / MFVideoFormat_* / MFVideoInterlace_Progressive
//     - mfapi.h:2270,2297,2309,3705; mfobjects.h:2987
//   GUID-y: MF_MT_MAJOR_TYPE 2613, MF_MT_SUBTYPE 2617, MF_MT_FRAME_SIZE 3072,
//     MF_MT_FRAME_RATE 3076, MF_MT_PIXEL_ASPECT_RATIO 3080,
//     MF_MT_INTERLACE_MODE 3127, MF_SINK_WRITER_DISABLE_THROTTLING
//     mfreadwrite.h:1205.
// Wszystkie vtable = kolejność w nagłówkach SDK. TPropVariant z
// Winapi.ActiveX.pas:2841 (typ RTL Delphi 13).

interface

uses
  Winapi.Windows,
  Winapi.ActiveX;

const
  MF_SDK_VERSION = $0002;
  MF_API_VERSION = $0070;
  MF_VERSION = (MF_SDK_VERSION shl 16) or MF_API_VERSION;

  MFVideoInterlace_Unknown = 0;
  MFVideoInterlace_Progressive = 2;

type
  MF_ATTRIBUTE_TYPE = DWORD;
  MF_ATTRIBUTES_MATCH_TYPE = DWORD;

  // IID_IMFAttributes = {2CD2D921-C447-44A7-A13C-4ADABFC247E3}
  IMFAttributes = interface(IUnknown)
    ['{2CD2D921-C447-44A7-A13C-4ADABFC247E3}']
    function GetItem(const guidKey: TGUID; var pValue: TPropVariant): HRESULT; stdcall;
    function GetItemType(const guidKey: TGUID; out pType: MF_ATTRIBUTE_TYPE): HRESULT; stdcall;
    function CompareItem(const guidKey: TGUID; const Value: TPropVariant; out pbResult: BOOL): HRESULT; stdcall;
    function Compare(const pTheirs: IMFAttributes; MatchType: MF_ATTRIBUTES_MATCH_TYPE; out pbResult: BOOL): HRESULT; stdcall;
    function GetUINT32(const guidKey: TGUID; out punValue: DWORD): HRESULT; stdcall;
    function GetUINT64(const guidKey: TGUID; out punValue: Int64): HRESULT; stdcall;
    function GetDouble(const guidKey: TGUID; out pfValue: Double): HRESULT; stdcall;
    function GetGUID(const guidKey: TGUID; out pguidValue: TGUID): HRESULT; stdcall;
    function GetStringLength(const guidKey: TGUID; out pcchLength: DWORD): HRESULT; stdcall;
    function GetString(const guidKey: TGUID; pwszValue: PWideChar; cchBufSize: DWORD; var pcchLength: DWORD): HRESULT; stdcall;
    function GetAllocatedString(const guidKey: TGUID; out ppwszValue: PWideChar; out pcchLength: DWORD): HRESULT; stdcall;
    function GetBlobSize(const guidKey: TGUID; out pcbBlobSize: DWORD): HRESULT; stdcall;
    function GetBlob(const guidKey: TGUID; pBuf: PByte; cbBufSize: DWORD; var pcbBlobSize: DWORD): HRESULT; stdcall;
    function GetAllocatedBlob(const guidKey: TGUID; out ppBuf: PByte; out pcbSize: DWORD): HRESULT; stdcall;
    function GetUnknown(const guidKey: TGUID; const riid: TGUID; out ppv: Pointer): HRESULT; stdcall;
    function SetItem(const guidKey: TGUID; const Value: TPropVariant): HRESULT; stdcall;
    function DeleteItem(const guidKey: TGUID): HRESULT; stdcall;
    function DeleteAllItems: HRESULT; stdcall;
    function SetUINT32(const guidKey: TGUID; unValue: DWORD): HRESULT; stdcall;
    function SetUINT64(const guidKey: TGUID; unValue: Int64): HRESULT; stdcall;
    function SetDouble(const guidKey: TGUID; fValue: Double): HRESULT; stdcall;
    function SetGUID(const guidKey: TGUID; const guidValue: TGUID): HRESULT; stdcall;
    function SetString(const guidKey: TGUID; wszValue: PWideChar): HRESULT; stdcall;
    function SetBlob(const guidKey: TGUID; pBuf: PByte; cbBufSize: DWORD): HRESULT; stdcall;
    function SetUnknown(const guidKey: TGUID; pUnknown: IUnknown): HRESULT; stdcall;
    function LockStore: HRESULT; stdcall;
    function UnlockStore: HRESULT; stdcall;
    function GetCount(out pcItems: DWORD): HRESULT; stdcall;
    function GetItemByIndex(unIndex: DWORD; out pguidKey: TGUID; var pValue: TPropVariant): HRESULT; stdcall;
    function CopyAllItems(const pDest: IMFAttributes): HRESULT; stdcall;
  end;

  // IID_IMFMediaBuffer = {045FA593-8799-42B8-BC8D-8968C6453507}
  IMFMediaBuffer = interface(IUnknown)
    ['{045FA593-8799-42B8-BC8D-8968C6453507}']
    function Lock(out ppbBuffer: PByte; out pcbMaxLength: DWORD; out pcbCurrentLength: DWORD): HRESULT; stdcall;
    function Unlock: HRESULT; stdcall;
    function GetCurrentLength(out pcbCurrentLength: DWORD): HRESULT; stdcall;
    function SetCurrentLength(cbCurrentLength: DWORD): HRESULT; stdcall;
    function GetMaxLength(out pcbMaxLength: DWORD): HRESULT; stdcall;
  end;

  // mfobjects.h:5798-5810 IMFActivate (dziedziczy IMFAttributes)
  IMFActivate = interface(IMFAttributes)
    ['{7FEE9E9A-4A89-47A6-899C-B6A53A70FB67}']
    function ActivateObject(const riid: TGUID; out ppv): HRESULT; stdcall;
    function ShutdownObject: HRESULT; stdcall;
    function DetachObject: HRESULT; stdcall;
  end;

  // mftransform.h:256 IMFTransform - zadeklarowany tylko poczatek tablicy metod
  // (kolejnosc jak w naglowku, do GetAttributes wlacznie); dalszych metod nie
  // wolno wolac przez ten typ. Parametry struktur jako Pointer (nieuzywane).
  IMFTransform = interface(IUnknown)
    ['{BF94C121-5B05-4E6F-8000-BA598961414D}']
    function GetStreamLimits(out pdwInputMinimum, pdwInputMaximum,
      pdwOutputMinimum, pdwOutputMaximum: DWORD): HRESULT; stdcall;
    function GetStreamCount(out pcInputStreams, pcOutputStreams: DWORD): HRESULT; stdcall;
    function GetStreamIDs(dwInputIDArraySize: DWORD; pdwInputIDs: Pointer;
      dwOutputIDArraySize: DWORD; pdwOutputIDs: Pointer): HRESULT; stdcall;
    function GetInputStreamInfo(dwInputStreamID: DWORD; pStreamInfo: Pointer): HRESULT; stdcall;
    function GetOutputStreamInfo(dwOutputStreamID: DWORD; pStreamInfo: Pointer): HRESULT; stdcall;
    function GetAttributes(out pAttributes: IMFAttributes): HRESULT; stdcall;
  end;

  // mfobjects.h:6555 IMFDXGIDeviceManager (Windows 8+); kolejnosc metod jak w naglowku
  IMFDXGIDeviceManager = interface(IUnknown)
    ['{EB533D5D-2DB6-40F8-97A9-494692014F07}']
    function CloseDeviceHandle(hDevice: THandle): HRESULT; stdcall;
    function GetVideoService(hDevice: THandle; const riid: TGUID; out ppService): HRESULT; stdcall;
    function LockDevice(hDevice: THandle; const riid: TGUID; out ppUnkDevice; fBlock: BOOL): HRESULT; stdcall;
    function OpenDeviceHandle(out phDevice: THandle): HRESULT; stdcall;
    function ResetDevice(const pUnkDevice: IUnknown; resetToken: UINT): HRESULT; stdcall;
    function TestDevice(hDevice: THandle): HRESULT; stdcall;
    function UnlockDevice(hDevice: THandle; fSaveState: BOOL): HRESULT; stdcall;
  end;

  // mfapi.h:561 MFCreateDXGIDeviceManager - tylko Windows 8+, wiec wolana przez
  // GetProcAddress (statyczny import zablokowalby start programu na Windows 7)
  TMFCreateDXGIDeviceManager = function(out resetToken: UINT;
    out ppDeviceManager: IMFDXGIDeviceManager): HRESULT; stdcall;

  // mfobjects.h:2973-2975 MFT_REGISTER_TYPE_INFO
  TMFTRegisterTypeInfo = record
    guidMajorType: TGUID;
    guidSubtype: TGUID;
  end;
  PMFTRegisterTypeInfo = ^TMFTRegisterTypeInfo;

  // IID_IMFSample = {C40A00F2-B93A-4D80-AE8C-5A1C634F58E4}
  IMFSample = interface(IMFAttributes)
    ['{C40A00F2-B93A-4D80-AE8C-5A1C634F58E4}']
    function GetSampleFlags(out pdwSampleFlags: DWORD): HRESULT; stdcall;
    function SetSampleFlags(dwSampleFlags: DWORD): HRESULT; stdcall;
    function GetSampleTime(out phnsSampleTime: Int64): HRESULT; stdcall;
    function SetSampleTime(hnsSampleTime: Int64): HRESULT; stdcall;
    function GetSampleDuration(out phnsSampleDuration: Int64): HRESULT; stdcall;
    function SetSampleDuration(hnsSampleDuration: Int64): HRESULT; stdcall;
    function GetBufferCount(out pdwBufferCount: DWORD): HRESULT; stdcall;
    function GetBufferByIndex(dwIndex: DWORD; out ppBuffer: IMFMediaBuffer): HRESULT; stdcall;
    function ConvertToContiguousBuffer(out ppBuffer: IMFMediaBuffer): HRESULT; stdcall;
    function AddBuffer(const pBuffer: IMFMediaBuffer): HRESULT; stdcall;
    function RemoveBufferByIndex(dwIndex: DWORD): HRESULT; stdcall;
    function RemoveAllBuffers: HRESULT; stdcall;
    function GetTotalLength(out pcbTotalLength: DWORD): HRESULT; stdcall;
    function CopyToBuffer(const pBuffer: IMFMediaBuffer): HRESULT; stdcall;
  end;

  // IID_IMFMediaType = {44AE0FA8-EA31-4109-8D2E-4CAE4997C555}
  IMFMediaType = interface(IMFAttributes)
    ['{44AE0FA8-EA31-4109-8D2E-4CAE4997C555}']
    function GetMajorType(out pguidMajorType: TGUID): HRESULT; stdcall;
    function IsCompressedFormat(out pfCompressed: BOOL): HRESULT; stdcall;
    function IsEqual(const pIMediaType: IMFMediaType; out pdwFlags: DWORD): HRESULT; stdcall;
    function GetRepresentation(const guidRepresentation: TGUID; out ppvRepresentation: Pointer): HRESULT; stdcall;
    function FreeRepresentation(const guidRepresentation: TGUID; pvRepresentation: Pointer): HRESULT; stdcall;
  end;

  // IID_IMFSinkWriter = {3137F1CD-FE5E-4805-A5D8-FB477448CB3D}
  IMFSinkWriter = interface(IUnknown)
    ['{3137F1CD-FE5E-4805-A5D8-FB477448CB3D}']
    function AddStream(const pTargetMediaType: IMFMediaType; out pdwStreamIndex: DWORD): HRESULT; stdcall;
    function SetInputMediaType(dwStreamIndex: DWORD; const pInputMediaType: IMFMediaType;
      const pEncodingParameters: IMFAttributes): HRESULT; stdcall;
    function BeginWriting: HRESULT; stdcall;
    function WriteSample(dwStreamIndex: DWORD; const pSample: IMFSample): HRESULT; stdcall;
    function SendStreamTick(dwStreamIndex: DWORD; llTimestamp: Int64): HRESULT; stdcall;
    function PlaceMarker(dwStreamIndex: DWORD; pvContext: Pointer): HRESULT; stdcall;
    function NotifyEndOfSegment(dwStreamIndex: DWORD): HRESULT; stdcall;
    function Flush(dwStreamIndex: DWORD): HRESULT; stdcall;
    function Finalize: HRESULT; stdcall;
    function GetServiceForStream(dwStreamIndex: DWORD; const guidService: TGUID;
      const riid: TGUID; out ppvObject: Pointer): HRESULT; stdcall;
    function GetStatistics(dwStreamIndex: DWORD; pStats: Pointer): HRESULT; stdcall;
  end;

const
  MF_MT_MAJOR_TYPE: TGUID = '{48EBA18E-F8C9-4687-BF11-0A74C9F96A8F}';
  MF_MT_SUBTYPE: TGUID = '{F7E34C9A-42E8-4714-B74B-CB29D72C35E5}';
  MF_MT_FRAME_SIZE: TGUID = '{1652C33D-D6B2-4012-B834-72030849A37D}';
  MF_MT_FRAME_RATE: TGUID = '{C459A2E8-3D2C-4E44-B132-FEE5156C7BB0}';
  MF_MT_PIXEL_ASPECT_RATIO: TGUID = '{C6376A1E-8D0A-4027-BE45-6D9A0AD39BB6}';
  MF_MT_INTERLACE_MODE: TGUID = '{E2724BB8-E676-4806-B4B2-A8D6EFB44CCD}';
  MF_MT_AVG_BITRATE: TGUID = '{20332624-FB0D-4D9E-BD0D-CBF6786C102E}';

  // codecapi.h:97 CODECAPI_AVEncCommonRateControlMode
  CODECAPI_AVEncCommonRateControlMode: TGUID = '{1C0608E9-370C-4710-8A58-CB6181C42423}';
  // codecapi.h:106 CODECAPI_AVEncCommonMeanBitRate
  CODECAPI_AVEncCommonMeanBitRate: TGUID = '{F7222374-2144-4815-B550-A37F8E12EE52}';
  // mfreadwrite.h:2071 (SDK 10.0.26100) MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS:
  // UINT32, domyslnie Sink Writer NIE uzywa koderow sprzetowych (MS Learn,
  // "MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS attribute", Remarks); Windows 7+.
  MF_READWRITE_ENABLE_HARDWARE_TRANSFORMS: TGUID = '{A634A91C-822B-41B9-A494-4DE4643612B0}';
  // codecapi.h:232 CODECAPI_AVEncMPVGOPSize
  CODECAPI_AVEncMPVGOPSize: TGUID = '{95F31B26-95A4-41AA-9303-246A7FC6EEF1}';

  eAVEncCommonRateControlMode_CBR = 0;
  eAVEncCommonRateControlMode_PeakConstrainedVBR = 1;
  eAVEncCommonRateControlMode_UnconstrainedVBR = 2;
  eAVEncCommonRateControlMode_Quality = 3;

  MFMediaType_Video: TGUID = '{73646976-0000-0010-8000-00AA00389B71}';
  MFVideoFormat_NV12: TGUID = '{3231564E-0000-0010-8000-00AA00389B71}';
  MFVideoFormat_H264: TGUID = '{34363248-0000-0010-8000-00AA00389B71}';
  MFVideoFormat_WMV3: TGUID = '{33564D57-0000-0010-8000-00AA00389B71}';

  MF_SINK_WRITER_DISABLE_THROTTLING: TGUID =
    '{08B845D8-2B74-4AFE-9D53-BE16D2D5AE4F}';

  // mfapi.h:1877-1879 MFT_CATEGORY_VIDEO_ENCODER
  MFT_CATEGORY_VIDEO_ENCODER: TGUID = '{F79EAC7D-E545-4387-BDEE-D647D7BDE42A}';
  // mfapi.h:2020 MFT_ENUM_FLAG_HARDWARE, :2024 MFT_ENUM_FLAG_SORTANDFILTER
  MFT_ENUM_FLAG_HARDWARE = $00000004;
  MFT_ENUM_FLAG_SORTANDFILTER = $00000040;
  // mftransform.h:1648 MFT_FRIENDLY_NAME_Attribute
  MFT_FRIENDLY_NAME_Attribute: TGUID = '{314FFBAE-5B41-4C95-9C19-4E7D586FACE3}';
  // mftransform.h:1647 MFT_ENUM_HARDWARE_URL_Attribute - obecny w GetAttributes
  // kazdego kodera sprzetowego; po nim Windows rozpoznaje sprzet (MS Learn,
  // "Hardware MFTs", Hardware MFT Attributes)
  MFT_ENUM_HARDWARE_URL_Attribute: TGUID = '{2FB866AC-B078-4942-AB6C-003D05CDA674}';
  // mftransform.h:1633 MFT_ENUM_HARDWARE_VENDOR_ID_Attribute (np. "VEN_10DE")
  MFT_ENUM_HARDWARE_VENDOR_ID_Attribute: TGUID = '{3AECB0CC-035B-4BCC-8185-2B8D551EF3AF}';
  // mfreadwrite.h:1207 MF_SINK_WRITER_D3D_MANAGER - IMFDXGIDeviceManager jako
  // IUnknown; daje koderom Sink Writera urzadzenie Direct3D (MS Learn; Windows 8+)
  MF_SINK_WRITER_D3D_MANAGER: TGUID = '{EC822DA2-E1E9-4B29-A0D8-563C719F5269}';
  // IID_IMFTransform (mftransform.h:256)
  IID_IMFTransform: TGUID = '{BF94C121-5B05-4E6F-8000-BA598961414D}';
  GUID_NULL_MF: TGUID = '{00000000-0000-0000-0000-000000000000}';

function MFStartup(Version: Cardinal; dwFlags: DWORD): HRESULT; stdcall;
  external 'mfplat.dll';
function MFShutdown: HRESULT; stdcall;
  external 'mfplat.dll';
function MFCreateMediaType(out ppMFType: IMFMediaType): HRESULT; stdcall;
  external 'mfplat.dll';
function MFCreateAttributes(out ppMFAttributes: IMFAttributes;
  cInitialSize: DWORD): HRESULT; stdcall; external 'mfplat.dll';
function MFCreateSample(out ppIMFSample: IMFSample): HRESULT; stdcall;
  external 'mfplat.dll';
function MFCreateMemoryBuffer(cbMaxLength: DWORD; out ppBuffer: IMFMediaBuffer):
  HRESULT; stdcall; external 'mfplat.dll';
function MFCreateSinkWriterFromURL(pwszOutputURL: LPCWSTR; pByteStream: Pointer;
  const pAttributes: IMFAttributes; out ppSinkWriter: IMFSinkWriter): HRESULT;
  stdcall; external 'mfreadwrite.dll';
// mfapi.h:2038 MFTEnumEx (mfplat.dll, Windows 7+). guidCategory przez wartosc:
// rekordy w stdcall ida na stos wprost (Program_Control_(Delphi).htm), jak GUID w C.
// Wynik: tablica IMFActivate przydzielona przez system - kazdy element zwolnic,
// tablice CoTaskMemFree (MS Learn, MFTEnumEx, pppMFTActivate).
function MFTEnumEx(guidCategory: TGUID; Flags: UINT32;
  pInputType, pOutputType: PMFTRegisterTypeInfo; out pppMFTActivate: Pointer;
  out pnumMFTActivate: UINT32): HRESULT; stdcall; external 'mfplat.dll';

// Nazwy sprzetowych koderow H.264 zarejestrowanych w Windows (te, ktorych moze
// uzyc zapis Timelapse przy wlaczonej karcie graficznej). Nazwy podaje
// sterownik (np. "NVIDIA H.264 Encoder MFT"). Pusta tablica = brak kodera albo
// blad - zapis idzie wtedy programowo (uVideoWriter).
function HardwareH264EncoderNames: TArray<string>;

implementation

uses
  System.SysUtils;

type
  TMFActivateArray = array[0..1023] of IMFActivate;
  PMFActivateArray = ^TMFActivateArray;

function HardwareH264EncoderNames: TArray<string>;
var
  OutInfo: TMFTRegisterTypeInfo;
  Arr: PMFActivateArray;
  Count: UINT32;
  N, I, K: Integer;
  P: Pointer;
  Name: PWideChar;
  Len: DWORD;
  S: string;
  Dup: Boolean;
begin
  Result := nil;
  if Failed(MFStartup(MF_VERSION, 0)) then Exit;
  try
    OutInfo.guidMajorType := MFMediaType_Video;
    OutInfo.guidSubtype := MFVideoFormat_H264;
    P := nil;
    Count := 0;
    if Failed(MFTEnumEx(MFT_CATEGORY_VIDEO_ENCODER,
        MFT_ENUM_FLAG_HARDWARE or MFT_ENUM_FLAG_SORTANDFILTER,
        nil, @OutInfo, P, Count)) or (P = nil) then Exit;
    Arr := PMFActivateArray(P);
    // licznik bez znaku: przy 0 "Count - 1" przekrecilby sie - petla na Integer
    N := Integer(Count);
    if N > Length(Arr^) then N := Length(Arr^);
    try
      for I := 0 to N - 1 do
        if (Arr^[I] <> nil) and
           Succeeded(Arr^[I].GetAllocatedString(MFT_FRIENDLY_NAME_Attribute, Name, Len)) then
        begin
          // ten sam koder bywa zarejestrowany kilka razy (np. Intel przy dwoch
          // kartach w laptopie) - kazda nazwa raz
          S := string(Name);
          CoTaskMemFree(Name);
          Dup := False;
          for K := 0 to High(Result) do
            if CompareText(Result[K], S) = 0 then Dup := True;
          if not Dup then
            Result := Result + [S];
        end;
    finally
      for I := 0 to N - 1 do
        Arr^[I] := nil;       // Release kazdego elementu
      CoTaskMemFree(P);
    end;
  finally
    MFShutdown;
  end;
end;

end.