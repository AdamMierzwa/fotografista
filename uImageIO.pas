unit uImageIO;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Winapi.Windows, Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.GDIPUTIL,
  Vcl.Graphics, Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, Vcl.Imaging.GIFImg,
  System.Skia,
  uPrefs, uI18n, uILBM;

const
  // Delphi GDI+ translation is missing this enum value
  EncoderValueCompressionJPEG = 7;

function LoadImageFile(const APath: string): TBitmap;
procedure SaveImageFile(ABitmap: TBitmap; const APath: string);
procedure ApplyMaxResolution(ABitmap: TBitmap);
function GetImageFilter: string;
function GetSaveImageFilter: string;
function GetFileFormatName(const APath: string): string;

implementation

procedure LoadSkiaImageToBitmap(const APath: string; ADst: TBitmap);
var
  Img: ISkImage;
  Bytes: TBytes;
  Stream: TMemoryStream;
  PNG: TPngImage;
begin
  Img := TSkImage.MakeFromEncodedFile(APath);
  if Img = nil then
    raise Exception.Create(T('No codec to read the file.') + #13#10 +
      T('Install the appropriate image extension from Microsoft Store.'));
  Bytes := Img.Encode(TSkEncodedImageFormat.Png, 100);
  if Length(Bytes) = 0 then
    raise Exception.Create(T('No codec to read the file.'));
  Stream := TMemoryStream.Create;
  try
    Stream.Write(Bytes[0], Length(Bytes));
    Stream.Position := 0;
    PNG := TPngImage.Create;
    try
      PNG.LoadFromStream(Stream);
      ADst.Assign(PNG);
    finally
      PNG.Free;
    end;
  finally
    Stream.Free;
  end;
  if ADst.PixelFormat <> pf24bit then
    ADst.PixelFormat := pf24bit;
end;

procedure SaveBitmapAsPNG(ABmp: TBitmap; const APath: string);
var
  PNG: TPngImage;
  Y, X: Integer;
  SrcRow: PByteArray;
  AlphaRow: PByteArray;
begin
  if ABmp.PixelFormat = pf32bit then
  begin
    PNG := TPngImage.CreateBlank(COLOR_RGBALPHA, 8, ABmp.Width, ABmp.Height);
    try
      for Y := 0 to ABmp.Height - 1 do
      begin
        SrcRow := ABmp.ScanLine[Y];
        Move(SrcRow^, PNG.Scanline[Y]^, ABmp.Width * 3);
        AlphaRow := PNG.AlphaScanline[Y];
        for X := 0 to ABmp.Width - 1 do
          AlphaRow[X] := SrcRow[X * 4 + 3];
      end;
      PNG.SaveToFile(APath);
    finally
      PNG.Free;
    end;
  end
  else
  begin
    PNG := TPngImage.Create;
    try
      PNG.Assign(ABmp);
      PNG.SaveToFile(APath);
    finally
      PNG.Free;
    end;
  end;
end;

procedure SaveBitmapAsWebP(ABmp: TBitmap; const APath: string; AQuality: Integer);
var
  Stream: TMemoryStream;
  Img: ISkImage;
begin
  Stream := TMemoryStream.Create;
  try
    ABmp.SaveToStream(Stream);
    Stream.Position := 0;
    Img := TSkImage.MakeFromEncodedStream(Stream);
  finally
    Stream.Free;
  end;
  Img.EncodeToFile(APath, TSkEncodedImageFormat.WebP, AQuality);
end;

function LoadImageFile(const APath: string): TBitmap;
var
  GPBmp: TGPBitmap;
  BufSize: Cardinal;
  Prop: PPropertyItem;
  Orient: Integer;
  W, H, Y: Integer;
  Data: TBitmapData;
  SrcRow, DstRow: PByte;
  Ext: string;
begin
  if not FileExists(APath) then
    raise Exception.CreateFmt('File not found: %s', [APath]);

  Ext := LowerCase(ExtractFileExt(APath));

  if (Ext = '.webp') or (Ext = '.heic') or (Ext = '.heif') or (Ext = '.avif') then
  begin
    Result := TBitmap.Create;
    try
      LoadSkiaImageToBitmap(APath, Result);
    except
      Result.Free;
      raise;
    end;
    Exit;
  end;

  if (Ext = '.iff') or (Ext = '.ilbm') or (Ext = '.lbm') then
  begin
    Result := LoadILBM(APath);
    Exit;
  end;

  GPBmp := TGPBitmap.Create(WideString(APath));
  try
    if GPBmp.GetWidth = 0 then
      raise Exception.CreateFmt('Cannot load: %s', [APath]);

    W := Integer(GPBmp.GetWidth);
    H := Integer(GPBmp.GetHeight);

    Orient := 1;
    BufSize := GPBmp.GetPropertyItemSize(274);
    if BufSize <> 0 then
    begin
      GetMem(Prop, BufSize);
      try
        if GPBmp.GetPropertyItem(274, BufSize, Prop) = Ok then
          Orient := PByte(Prop^.value)^;
      finally
        FreeMem(Prop);
      end;
    end;

    case Orient of
      2: GPBmp.RotateFlip(RotateNoneFlipX);
      3: GPBmp.RotateFlip(Rotate180FlipNone);
      4: GPBmp.RotateFlip(RotateNoneFlipY);
      5: GPBmp.RotateFlip(Rotate90FlipX);
      6: GPBmp.RotateFlip(Rotate90FlipNone);
      7: GPBmp.RotateFlip(Rotate270FlipX);
      8: GPBmp.RotateFlip(Rotate270FlipNone);
    end;

    if (Orient >= 5) and (Orient <= 8) then
    begin
      W := Integer(GPBmp.GetWidth);
      H := Integer(GPBmp.GetHeight);
    end;

    GPBmp.LockBits(MakeRect(0, 0, W, H), ImageLockModeRead, PixelFormat24bppRGB, Data);
    try
      Result := TBitmap.Create;
      Result.PixelFormat := pf24bit;
      Result.Width := W;
      Result.Height := H;

      for Y := 0 to H - 1 do
      begin
        SrcRow := PByte(NativeUInt(Data.Scan0) + NativeUInt(Y) * NativeUInt(Data.Stride));
        DstRow := Result.ScanLine[Y];
        Move(SrcRow^, DstRow^, W * 3);
      end;
    finally
      GPBmp.UnlockBits(Data);
    end;
  finally
    GPBmp.Free;
  end;
end;

procedure ApplyMaxResolution(ABitmap: TBitmap);
var
  Limit, NW, NH: Integer;
  Scale: Double;
  Tmp: TBitmap;
begin
  if ABitmap = nil then Exit;
  if (ABitmap.Width = 0) or (ABitmap.Height = 0) then Exit;
  if Prefs.MaxResolution = 'original' then Exit;
  if Prefs.MaxResolution = 'fhd' then Limit := 1920
  else if Prefs.MaxResolution = '4k' then Limit := 3840
  else if Prefs.MaxResolution = 'svga' then Limit := 800
  else Exit;
  if (ABitmap.Width <= Limit) and (ABitmap.Height <= Limit) then Exit;
  if ABitmap.Width >= ABitmap.Height then
    Scale := Limit / ABitmap.Width
  else
    Scale := Limit / ABitmap.Height;
  NW := Max(1, Round(ABitmap.Width * Scale));
  NH := Max(1, Round(ABitmap.Height * Scale));
  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.Width := NW;
    Tmp.Height := NH;
    SetStretchBltMode(Tmp.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(Tmp.Canvas.Handle, 0, 0, nil);
    Tmp.Canvas.StretchDraw(Rect(0, 0, NW, NH), ABitmap);
    ABitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure SaveImageFile(ABitmap: TBitmap; const APath: string);
var
  Ext: string;
  JPEGImg: TJPEGImage;
  GIFImg: TGIFImage;
  GPBmp: TGPBitmap;
  EncoderClsid: TGUID;
  MemStream: TMemoryStream;
  P: Pointer;
  Params: PEncoderParameters;
  P2: PEncoderParameter;
  CompVal: Cardinal;
  QualityVal: Cardinal;
begin
  Ext := LowerCase(ExtractFileExt(APath));

  if (Ext = '.jpg') or (Ext = '.jpeg') then
  begin
    JPEGImg := TJPEGImage.Create;
    try
      JPEGImg.Assign(ABitmap);
      JPEGImg.CompressionQuality := Prefs.JPGQuality;
      JPEGImg.SaveToFile(APath);
    finally
      JPEGImg.Free;
    end;
  end
  else if Ext = '.png' then
    SaveBitmapAsPNG(ABitmap, APath)
  else if Ext = '.gif' then
  begin
    GIFImg := TGIFImage.Create;
    try
      GIFImg.Assign(ABitmap);
      GIFImg.SaveToFile(APath);
    finally
      GIFImg.Free;
    end;
  end
  else if Ext = '.bmp' then
  begin
    ABitmap.SaveToFile(APath);
  end
  else if (Ext = '.tif') or (Ext = '.tiff') then
  begin
    if GetEncoderClsid('image/tiff', EncoderClsid) < 0 then
      raise Exception.Create(T('No TIFF encoder in the system.'));
    MemStream := TMemoryStream.Create;
    try
      ABitmap.SaveToStream(MemStream);
      MemStream.Position := 0;
      GPBmp := TGPBitmap.Create(TStreamAdapter.Create(MemStream, soReference));
      try
        // Allocate space for TEncoderParameters (aligned, 1 slot) + 1 extra slot
        P := AllocMem(SizeOf(TEncoderParameters) + SizeOf(TEncoderParameter));
        try
          Params := PEncoderParameters(P);
          Params.Count := 1;
          Params.Parameter[0].Guid := EncoderCompression;
          Params.Parameter[0].NumberOfValues := 1;
          Params.Parameter[0].Type_ := EncoderParameterValueTypeLong;
          case Prefs.TIFFCompression of
            0: CompVal := Ord(EncoderValueCompressionLZW);
            1: CompVal := Ord(EncoderValueCompressionNone);
            2: CompVal := EncoderValueCompressionJPEG;
          else
            CompVal := Ord(EncoderValueCompressionLZW);
          end;
          Params.Parameter[0].Value := @CompVal;

          if Prefs.TIFFCompression = 2 then
          begin
            Params.Count := 2;
            P2 := @Params.Parameter[0];
            Inc(P2);
            P2.Guid := EncoderQuality;
            P2.NumberOfValues := 1;
            P2.Type_ := EncoderParameterValueTypeLong;
            QualityVal := Prefs.TIFFJPEGQuality;
            P2.Value := @QualityVal;
          end;

          if GPBmp.Save(PChar(APath), EncoderClsid, Params) <> Ok then
            raise Exception.Create(T('TIFF save error'));
        finally
          FreeMem(P);
        end;
      finally
        GPBmp.Free;
      end;
    finally
      MemStream.Free;
    end;
  end
  else if Ext = '.webp' then
    SaveBitmapAsWebP(ABitmap, APath, Prefs.WebPQuality)
  else
    raise Exception.CreateFmt(T('Unsupported save format: %s'), [Ext]);
end;

function GetImageFilter: string;
begin
  Result :=
    'All supported|*.bmp;*.jpg;*.jpeg;*.png;*.gif;*.tif;*.tiff;*.webp;*.heic;*.heif;*.avif;*.iff;*.ilbm;*.lbm|' +
    'PNG|*.png|' +
    'JPEG|*.jpg;*.jpeg|' +
    'BMP|*.bmp|' +
    'GIF|*.gif|' +
    'TIFF|*.tif;*.tiff|' +
    'WebP|*.webp|' +
    'HEIC/HEIF|*.heic;*.heif|' +
    'AVIF|*.avif|' +
    'IFF ILBM|*.iff;*.ilbm;*.lbm';
end;

function GetSaveImageFilter: string;
begin
  Result :=
    'PNG|*.png|' +
    'JPEG|*.jpg;*.jpeg|' +
    'BMP|*.bmp|' +
    'GIF|*.gif|' +
    'TIFF|*.tif;*.tiff|' +
    'WebP|*.webp';
end;

function GetFileFormatName(const APath: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(APath));
  if (Ext = '.jpg') or (Ext = '.jpeg') then Result := 'JPEG'
  else if Ext = '.png' then Result := 'PNG'
  else if Ext = '.gif' then Result := 'GIF'
  else if (Ext = '.tif') or (Ext = '.tiff') then Result := 'TIFF'
  else if Ext = '.bmp' then Result := 'BMP'
  else if Ext = '.webp' then Result := 'WebP'
  else if (Ext = '.heic') or (Ext = '.heif') then Result := 'HEIC/HEIF'
  else if Ext = '.avif' then Result := 'AVIF'
  else if (Ext = '.iff') or (Ext = '.ilbm') or (Ext = '.lbm') then Result := 'IFF ILBM'
  else Result := 'Unknown';
end;

initialization

finalization

end.
