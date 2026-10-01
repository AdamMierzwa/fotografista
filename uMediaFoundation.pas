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

implementation

end.