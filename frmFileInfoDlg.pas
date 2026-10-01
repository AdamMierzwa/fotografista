unit frmFileInfoDlg;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  Winapi.ActiveX,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uI18n, uTitleBar;

type
  TfrmFileInfo = class(TFotoForm)
    Memo: TMemo;
    pnlBottom: TPanel;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    procedure ShowFileInfo(const AFilePath: string; const ABitmap: TBitmap);
  end;

implementation

{$R *.dfm}

type
  TExifRational = packed record Num, Den: Cardinal; end;
  PExifRational = ^TExifRational;
  TExifSRational = packed record Num, Den: Integer; end;
  PExifSRational = ^TExifSRational;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTriple = ^TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

function TagName(ATag: PROPID): string;
begin
  case ATag of
    $00FE: Result := 'Subfile type';
    $00FF: Result := 'Old subfile type';
    $0100: Result := 'Image width';
    $0101: Result := 'Image height';
    $0102: Result := 'Bits per sample';
    $0103: Result := 'Compression';
    $0106: Result := 'Photometric interpretation';
    $0107: Result := 'Thresholding';
    $0108: Result := 'Cell width';
    $0109: Result := 'Cell height';
    $010A: Result := 'Fill order';
    $010D: Result := 'Document name';
    $010E: Result := 'Image description';
    $010F: Result := 'Camera make';
    $0110: Result := 'Camera model';
    $0111: Result := 'Strip offsets';
    $0112: Result := 'Orientation';
    $0115: Result := 'Samples per pixel';
    $0116: Result := 'Rows per strip';
    $0117: Result := 'Strip byte counts';
    $0118: Result := 'Min sample value';
    $0119: Result := 'Max sample value';
    $011A: Result := 'X resolution';
    $011B: Result := 'Y resolution';
    $011C: Result := 'Planar configuration';
    $0128: Result := 'Resolution unit';
    $012D: Result := 'Transfer function';
    $0131: Result := 'Software';
    $0132: Result := 'File date/time';
    $013B: Result := 'Artist';
    $013E: Result := 'White point';
    $013F: Result := 'Primary chromaticities';
    $0183: Result := 'Transfer range';
    $0190: Result := 'Copyright';
    $0201: Result := 'JPEG lossless predictor';
    $0203: Result := 'JPEG process';
    $0211: Result := 'YCbCr coefficients';
    $0212: Result := 'YCbCr subsampling';
    $0213: Result := 'YCbCr positioning';
    $0214: Result := 'Reference black/white';
    $828E: Result := 'CFA pattern';
    $8298: Result := 'Copyright holder';
    $829A: Result := 'Exposure time';
    $829D: Result := 'F-number';
    $83BB: Result := 'IPTC/NAA';
    $8769: Result := 'Exif IFD';
    $8773: Result := 'ICC profile';
    $8822: Result := 'Exposure program';
    $8824: Result := 'Spectral sensitivity';
    $8825: Result := 'GPS IFD';
    $8827: Result := 'ISO speed';
    $8828: Result := 'OECF';
    $8829: Result := 'Interlace';
    $8830: Result := 'Time zone offset';
    $8831: Result := 'Self timer mode';
    $9000: Result := 'Exif version';
    $9003: Result := 'Date/time original';
    $9004: Result := 'Date/time digitized';
    $9101: Result := 'Components configuration';
    $9102: Result := 'Compressed bits per pixel';
    $9201: Result := 'Shutter speed value';
    $9202: Result := 'Aperture value';
    $9203: Result := 'Brightness value';
    $9204: Result := 'Exposure bias';
    $9205: Result := 'Max aperture';
    $9206: Result := 'Subject distance';
    $9207: Result := 'Metering mode';
    $9208: Result := 'Light source';
    $9209: Result := 'Flash';
    $920A: Result := 'Focal length';
    $920B: Result := 'Flash energy';
    $920C: Result := 'Spatial frequency response';
    $920D: Result := 'Noise';
    $9211: Result := 'Image number';
    $9212: Result := 'Security classification';
    $9213: Result := 'Image history';
    $9214: Result := 'Subject area';
    $927C: Result := 'Maker note';
    $9286: Result := 'User comment';
    $9290: Result := 'Subsec time';
    $9291: Result := 'Subsec time original';
    $9292: Result := 'Subsec time digitized';
    $A000: Result := 'FlashPix version';
    $A001: Result := 'Color space';
    $A002: Result := 'Exif image width';
    $A003: Result := 'Exif image height';
    $A004: Result := 'Related sound file';
    $A005: Result := 'Exif interoperability IFD';
    $A20B: Result := 'Flash energy';
    $A20C: Result := 'Spatial frequency response';
    $A20E: Result := 'Focal plane X resolution';
    $A20F: Result := 'Focal plane Y resolution';
    $A210: Result := 'Focal plane resolution unit';
    $A214: Result := 'Subject location';
    $A215: Result := 'Exposure index';
    $A217: Result := 'Sensing method';
    $A300: Result := 'File source';
    $A301: Result := 'Scene type';
    $A302: Result := 'CFA pattern';
    $A401: Result := 'Custom rendered';
    $A402: Result := 'Exposure mode';
    $A403: Result := 'White balance';
    $A404: Result := 'Digital zoom ratio';
    $A405: Result := 'Focal length in 35mm';
    $A406: Result := 'Scene capture type';
    $A407: Result := 'Gain control';
    $A408: Result := 'Contrast';
    $A409: Result := 'Saturation';
    $A40A: Result := 'Sharpness';
    $A40B: Result := 'Device settings description';
    $A40C: Result := 'Subject distance range';
    $A420: Result := 'Image unique ID';
    $C4A5: Result := 'Print image matching (PIM)';
    $EA1C: Result := 'Pixel format';
    $EA1D: Result := 'Transformation';
    $EA1E: Result := 'Uncompressed';
    $EA1F: Result := 'Image type';
  else
    Result := Format('Unknown (0x%.4x)', [ATag]);
  end;
end;

function FormatFlash(Val: Cardinal): string;
begin
  case Val and $1F of
    0: Result := 'No flash';
    1: Result := 'Fired';
    5: Result := 'Fired, return not detected';
    7: Result := 'Fired, return detected';
  else
    Result := Format('0x%.4x', [Val]);
  end;
  if (Val shr 5) and 1 <> 0 then
    Result := Result + ', no strobe return';
  if (Val shr 6) and 1 <> 0 then
    Result := Result + ', compulsory flash mode';
end;

function FormatRational(Buf: PPropertyItem; var S: string): Boolean;
begin
  Result := False;
  if Buf.length < SizeOf(TExifRational) then Exit;
  S := Format('%d/%d', [PExifRational(Buf.value).Num, PExifRational(Buf.value).Den]);
  Result := True;
end;

function FormatSRational(Buf: PPropertyItem; var S: string): Boolean;
begin
  Result := False;
  if Buf.length < SizeOf(TExifSRational) then Exit;
  S := Format('%d/%d', [PExifSRational(Buf.value).Num, PExifSRational(Buf.value).Den]);
  Result := True;
end;

function FormatValue(Buf: PPropertyItem): string;
var
  I: Integer;
  W: PWord;
  L: PCardinal;
begin
  if Buf.value = nil then
    Exit('(nil)');

  case Buf.type_ of
    1: // Byte
      begin
        Result := '';
        for I := 0 to Buf.length - 1 do
        begin
          if I > 0 then Result := Result + ' ';
          Result := Result + IntToStr(PByte(Buf.value)[I]);
        end;
        if Length(Result) > 120 then
          Result := Copy(Result, 1, 120) + '... (' + IntToStr(Buf.length) + ' bytes)';
      end;

    2: // ASCII
      Result := string(PAnsiChar(Buf.value));

    3: // Short (WORD)
      begin
        W := PWord(Buf.value);
        for I := 0 to (Buf.length div SizeOf(Word)) - 1 do
        begin
          if I > 0 then Result := Result + ' ';
          Result := Result + IntToStr(W^);
          Inc(W);
        end;
      end;

    4: // Long (Cardinal)
      begin
        L := PCardinal(Buf.value);
        for I := 0 to (Buf.length div SizeOf(Cardinal)) - 1 do
        begin
          if I > 0 then Result := Result + ' ';
          Result := Result + IntToStr(L^);
          Inc(L);
        end;
      end;

    5: // Rational
      if not FormatRational(Buf, Result) then
        Result := '(invalid rational)';

    7: // Undefined
      begin
        Result := '';
        for I := 0 to Buf.length - 1 do
        begin
          if I > 0 then Result := Result + ' ';
          Result := Result + IntToHex(PByte(Buf.value)[I], 2);
        end;
        if Length(Result) > 120 then
          Result := Copy(Result, 1, 120) + '...';
      end;

    9: // SLONG
      begin
        Result := IntToStr(PInteger(Buf.value)^);
      end;

    10: // SRational
      if not FormatSRational(Buf, Result) then
        Result := '(invalid SRational)';

  else
    Result := Format('(type %d, %d bytes)', [Buf.type_, Buf.length]);
  end;
end;

function CountUniqueColors(const ABitmap: TBitmap): Int64;
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Key: Cardinal;
  Hist: TDictionary<Cardinal, Byte>;
begin
  Result := 0;
  if ABitmap = nil then Exit;
  W := ABitmap.Width;
  H := ABitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if ABitmap.PixelFormat <> pf24bit then
    ABitmap.PixelFormat := pf24bit;

  Hist := TDictionary<Cardinal, Byte>.Create;
  try
    for Y := 0 to H - 1 do
    begin
      Row := ABitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Key := (Cardinal(Row[X].R) shl 16) or (Cardinal(Row[X].G) shl 8) or Cardinal(Row[X].B);
        Hist.AddOrSetValue(Key, 1);
      end;
    end;
    Result := Hist.Count;
  finally
    Hist.Free;
  end;
end;

procedure TfrmFileInfo.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmFileInfo.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;

procedure TfrmFileInfo.ShowFileInfo(const AFilePath: string; const ABitmap: TBitmap);
var
  GPImg: TGPImage;
  Count: UINT;
  I: Integer;
  IdList: array of PROPID;
  Sz: UINT;
  Buf: PPropertyItem;
  Line: string;
  CameraModel: string;
  FileSizeMB: Double;
  Colors: Int64;
  FS: TFormatSettings;

  procedure AddLine(const S: string);
  begin
    Memo.Lines.Add(S);
  end;

  procedure AddVal(const ALabel: string; const AValue: string);
  begin
    AddLine('  ' + ALabel + ': ' + AValue);
  end;

begin
  Caption := T('Image info') + ' - ' + ExtractFileName(AFilePath);
  Memo.Clear;

  AddLine('========================================');
  AddLine('  ' + T('Image info'));
  AddLine('========================================');
  AddLine('');
  AddLine(T('File'));
  AddLine('');
  AddVal(T('Name'), ExtractFileName(AFilePath));
  AddVal(T('Format'), LowerCase(ExtractFileExt(AFilePath)));

  try
    FileSizeMB := TFile.GetSize(AFilePath) / (1024 * 1024);
  except
    FileSizeMB := 0;
  end;

  GPImg := TGPImage.Create(AFilePath);
  try
    if GPImg.GetLastStatus = Ok then
    begin
      AddLine('');
      AddLine(T('Image'));
      AddLine('');
      AddVal(T('Width'), Format('%d px', [GPImg.GetWidth]));
      AddVal(T('Height'), Format('%d px', [GPImg.GetHeight]));
      AddVal(T('Resolution X'), Format('%.0f dpi', [GPImg.GetHorizontalResolution]));
      AddVal(T('Resolution Y'), Format('%.0f dpi', [GPImg.GetVerticalResolution]));

      AddLine('');
      AddLine(Format(T('EXIF (%d properties)'), [GPImg.GetPropertyCount]));
      AddLine('');

      Count := GPImg.GetPropertyCount;
      if Count > 0 then
      begin
        SetLength(IdList, Count);
        GPImg.GetPropertyIdList(Count, @IdList[0]);

        for I := 0 to Count - 1 do
        begin
          Sz := GPImg.GetPropertyItemSize(IdList[I]);
          if Sz = 0 then Continue;

          GetMem(Buf, Sz);
          try
            if GPImg.GetPropertyItem(IdList[I], Sz, Buf) = Ok then
            begin
              Line := TagName(Buf.id);
              if Line = '' then
                Line := Format('0x%.4x', [Buf.id])
              else
                Line := Format('0x%.4x (%s)', [Buf.id, Line]);

              if (Buf.id = $9209) and (Buf.type_ = 3) then
                Line := Line + ': ' + FormatFlash(PWord(Buf.value)^)
              else
                Line := Line + ': ' + FormatValue(Buf);

              if Buf.id = $0110 then
                CameraModel := FormatValue(Buf);

              AddLine(Line);
            end;
          finally
            FreeMem(Buf);
          end;
        end;
      end;
    end
    else
      AddLine(T('Could not open the file to read metadata.'));
  finally
    GPImg.Free;
  end;

  Colors := CountUniqueColors(ABitmap);
  if CameraModel = '' then
    CameraModel := '-';

  FS := TFormatSettings.Create;
  FS.ThousandSeparator := '.';
  FS.DecimalSeparator := '.';

  AddLine('');
  AddLine(Format('%s, %s MB, %s, %s',
    [ExtractFileName(AFilePath),
     FormatFloat('0.00', FileSizeMB, FS),
     FormatFloat('#,##0', Colors, FS),
     CameraModel]));
  AddLine('========================================');
end;

end.
