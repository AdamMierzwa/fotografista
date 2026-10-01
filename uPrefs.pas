unit uPrefs;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Menus, Vcl.Forms,
  Winapi.Windows, System.IniFiles, uI18n;

const
  MAX_RECENT = 20;

type
  TDuotonePreset = record
    Name: string;
    Colors: array[0..3] of TColor;
  end;

  TPrefs = record
    { Interface }
    CanvasBG: TColor;
    RememberWin: Boolean;
    UIFontSize: Integer;
    RecentFilesCount: Integer;
    ThemeName: string;
    Language: Integer; // -1 = auto (DetectLanguage), 0..8 = TLanguage
    RecentFiles: array[0..MAX_RECENT - 1] of string;
    { Window position }
    WinLeft: Integer;
    WinTop: Integer;
    WinWidth: Integer;
    WinHeight: Integer;
    WinMaximized: Boolean;
    { Quality }
    JPGQuality: Integer;
    WebPQuality: Integer;
    TIFFCompression: Integer; // 0=LZW, 1=Flate, 2=JPEG
    TIFFJPEGQuality: Integer;
    { Performance }
    MaxResolution: string;
    SmoothPreview: Boolean;
    { Effects }
    DuotonePresets: array of TDuotonePreset;
  end;

var
  Prefs: TPrefs;

function GetPrefsPath: string;
procedure LoadPrefs;
procedure SavePrefs;
procedure SaveWindowPos(AForm: TObject);
procedure RestoreWindowPos(AForm: TObject);
procedure AddRecentFile(const APath: string);
procedure RebuildRecentMenu(AFileMenu: TMenuItem;
  AInsertBefore: TMenuItem; AClickEvent: TNotifyEvent);

implementation

function GetPrefsPath: string;
var
  AppData: string;
begin
  AppData := GetEnvironmentVariable('APPDATA');
  Result := IncludeTrailingPathDelimiter(AppData) + 'Fotografista';
  ForceDirectories(Result);
  Result := IncludeTrailingPathDelimiter(Result) + 'fotografista.ini';
end;

procedure LoadPrefs;
var
  Ini: TIniFile;
  I: Integer;
begin
  Prefs.CanvasBG := RGB(80, 80, 80);
  Prefs.RememberWin := True;
  Prefs.UIFontSize := 0;
  Prefs.RecentFilesCount := 5;
  Prefs.WinLeft := -1;
  Prefs.WinTop := -1;
  Prefs.WinWidth := 900;
  Prefs.WinHeight := 600;
  Prefs.WinMaximized := True;
  for I := 0 to MAX_RECENT - 1 do
    Prefs.RecentFiles[I] := '';
  Prefs.JPGQuality := 90;
  Prefs.WebPQuality := 90;
  Prefs.TIFFCompression := 0;
  Prefs.TIFFJPEGQuality := 85;
  Prefs.MaxResolution := 'original';
  Prefs.SmoothPreview := False;
  Prefs.ThemeName := 'Windows';
  Prefs.Language := -1;
  SetLength(Prefs.DuotonePresets, 0);

  if not FileExists(GetPrefsPath) then
    Exit;

  Ini := TIniFile.Create(GetPrefsPath);
  try
    Prefs.CanvasBG := Ini.ReadInteger('Interface', 'CanvasBG', Prefs.CanvasBG);
    Prefs.RememberWin := Ini.ReadBool('Interface', 'RememberWin', Prefs.RememberWin);
    Prefs.UIFontSize := Ini.ReadInteger('Interface', 'UIFontSize', Prefs.UIFontSize);
    if (Prefs.UIFontSize < -1) or (Prefs.UIFontSize > 3) then
      Prefs.UIFontSize := 0;
    Prefs.RecentFilesCount := Ini.ReadInteger('Interface', 'RecentFilesCount', Prefs.RecentFilesCount);
    Prefs.RecentFilesCount := EnsureRange(Prefs.RecentFilesCount, 0, MAX_RECENT);
    for I := 0 to MAX_RECENT - 1 do
      Prefs.RecentFiles[I] := Ini.ReadString('Recent', IntToStr(I), '');
    Prefs.JPGQuality := Ini.ReadInteger('Quality', 'JPGQuality', Prefs.JPGQuality);
    Prefs.WebPQuality := Ini.ReadInteger('Quality', 'WebPQuality', Prefs.WebPQuality);
    Prefs.TIFFCompression := Ini.ReadInteger('Quality', 'TIFFCompression', Prefs.TIFFCompression);
    Prefs.TIFFJPEGQuality := Ini.ReadInteger('Quality', 'TIFFJPEGQuality', Prefs.TIFFJPEGQuality);
    Prefs.MaxResolution := Ini.ReadString('Performance', 'MaxResolution', Prefs.MaxResolution);
    Prefs.SmoothPreview := Ini.ReadBool('Performance', 'SmoothPreview', Prefs.SmoothPreview);
    Prefs.ThemeName := Ini.ReadString('Interface', 'ThemeName', Prefs.ThemeName);
    Prefs.Language := Ini.ReadInteger('Interface', 'Language', -1);
    if (Prefs.Language < -1) or (Prefs.Language > 8) then
      Prefs.Language := -1;
    Prefs.WinLeft := Ini.ReadInteger('Window', 'Left', Prefs.WinLeft);
    Prefs.WinTop := Ini.ReadInteger('Window', 'Top', Prefs.WinTop);
    Prefs.WinWidth := Ini.ReadInteger('Window', 'Width', Prefs.WinWidth);
    Prefs.WinHeight := Ini.ReadInteger('Window', 'Height', Prefs.WinHeight);
    Prefs.WinMaximized := Ini.ReadBool('Window', 'Maximized', Prefs.WinMaximized);

    SetLength(Prefs.DuotonePresets, Ini.ReadInteger('DuotonePresets', 'Count', 0));
    for I := 0 to Length(Prefs.DuotonePresets) - 1 do
    begin
      Prefs.DuotonePresets[I].Name := Ini.ReadString('DuotonePresets', 'Name' + IntToStr(I), '');
      Prefs.DuotonePresets[I].Colors[0] := Ini.ReadInteger('DuotonePresets', 'C0_' + IntToStr(I), 0);
      Prefs.DuotonePresets[I].Colors[1] := Ini.ReadInteger('DuotonePresets', 'C1_' + IntToStr(I), 0);
      Prefs.DuotonePresets[I].Colors[2] := Ini.ReadInteger('DuotonePresets', 'C2_' + IntToStr(I), 0);
      Prefs.DuotonePresets[I].Colors[3] := Ini.ReadInteger('DuotonePresets', 'C3_' + IntToStr(I), 0);
    end;
  finally
    Ini.Free;
  end;
end;
procedure SavePrefs;
var
  Ini: TIniFile;
  I: Integer;
begin
  Ini := TIniFile.Create(GetPrefsPath);
  try
    Ini.WriteInteger('Interface', 'CanvasBG', Prefs.CanvasBG);
    Ini.WriteBool('Interface', 'RememberWin', Prefs.RememberWin);
    Ini.WriteInteger('Interface', 'UIFontSize', Prefs.UIFontSize);
    Ini.WriteInteger('Interface', 'RecentFilesCount', Prefs.RecentFilesCount);
    Ini.WriteString('Interface', 'ThemeName', Prefs.ThemeName);
    Ini.WriteInteger('Interface', 'Language', Prefs.Language);
    for I := 0 to MAX_RECENT - 1 do
      Ini.WriteString('Recent', IntToStr(I), Prefs.RecentFiles[I]);
    Ini.WriteInteger('Quality', 'JPGQuality', Prefs.JPGQuality);
    Ini.WriteInteger('Quality', 'WebPQuality', Prefs.WebPQuality);
    Ini.WriteInteger('Quality', 'TIFFCompression', Prefs.TIFFCompression);
    Ini.WriteInteger('Quality', 'TIFFJPEGQuality', Prefs.TIFFJPEGQuality);
    Ini.WriteString('Performance', 'MaxResolution', Prefs.MaxResolution);
    Ini.WriteBool('Performance', 'SmoothPreview', Prefs.SmoothPreview);
    Ini.WriteInteger('Window', 'Left', Prefs.WinLeft);
    Ini.WriteInteger('Window', 'Top', Prefs.WinTop);
    Ini.WriteInteger('Window', 'Width', Prefs.WinWidth);
    Ini.WriteInteger('Window', 'Height', Prefs.WinHeight);
    Ini.WriteBool('Window', 'Maximized', Prefs.WinMaximized);

    Ini.WriteInteger('DuotonePresets', 'Count', Length(Prefs.DuotonePresets));
    for I := 0 to Length(Prefs.DuotonePresets) - 1 do
    begin
      Ini.WriteString('DuotonePresets', 'Name' + IntToStr(I), Prefs.DuotonePresets[I].Name);
      Ini.WriteInteger('DuotonePresets', 'C0_' + IntToStr(I), Prefs.DuotonePresets[I].Colors[0]);
      Ini.WriteInteger('DuotonePresets', 'C1_' + IntToStr(I), Prefs.DuotonePresets[I].Colors[1]);
      Ini.WriteInteger('DuotonePresets', 'C2_' + IntToStr(I), Prefs.DuotonePresets[I].Colors[2]);
      Ini.WriteInteger('DuotonePresets', 'C3_' + IntToStr(I), Prefs.DuotonePresets[I].Colors[3]);
    end;
  finally
    Ini.Free;
  end;
end;

procedure SaveWindowPos(AForm: TObject);
var
  F: TForm;
begin
  F := TForm(AForm);
  Prefs.WinMaximized := (F.WindowState = wsMaximized);
  if F.WindowState = wsMaximized then
  begin
    Prefs.WinLeft := F.Left;
    Prefs.WinTop := F.Top;
    Prefs.WinWidth := F.Width;
    Prefs.WinHeight := F.Height;
  end
  else
  begin
    Prefs.WinLeft := F.Left;
    Prefs.WinTop := F.Top;
    Prefs.WinWidth := F.Width;
    Prefs.WinHeight := F.Height;
  end;
  SavePrefs;
end;

procedure RestoreWindowPos(AForm: TObject);
var
  F: TForm;
begin
  if not Prefs.RememberWin then
    Exit;
  F := TForm(AForm);
  if Prefs.WinLeft >= 0 then
  begin
    F.Left := Prefs.WinLeft;
    F.Top := Prefs.WinTop;
    F.Width := Prefs.WinWidth;
    F.Height := Prefs.WinHeight;
  end;
  if Prefs.WinMaximized then
    F.WindowState := wsMaximized
  else
    F.WindowState := wsNormal;
end;

procedure AddRecentFile(const APath: string);
var
  I, J: Integer;
begin
  if Prefs.RecentFilesCount = 0 then
    Exit;

  for I := 0 to Prefs.RecentFilesCount - 1 do
    if SameText(Prefs.RecentFiles[I], APath) then
    begin
      for J := I to Prefs.RecentFilesCount - 2 do
        Prefs.RecentFiles[J] := Prefs.RecentFiles[J + 1];
      Prefs.RecentFiles[Prefs.RecentFilesCount - 1] := '';
      Break;
    end;

  for I := Prefs.RecentFilesCount - 1 downto 1 do
    Prefs.RecentFiles[I] := Prefs.RecentFiles[I - 1];
  Prefs.RecentFiles[0] := APath;

  SavePrefs;
end;

var
  RecentItems: array of TMenuItem;

procedure RebuildRecentMenu(AFileMenu: TMenuItem;
  AInsertBefore: TMenuItem; AClickEvent: TNotifyEvent);
var
  I, Idx: Integer;
  Item: TMenuItem;
begin
  for I := High(RecentItems) downto 0 do
  begin
    if Assigned(RecentItems[I]) then
    begin
      AFileMenu.Remove(RecentItems[I]);
      RecentItems[I].Free;
    end;
  end;
  SetLength(RecentItems, 0);

  if Prefs.RecentFilesCount = 0 then
    Exit;

  SetLength(RecentItems, Prefs.RecentFilesCount);
  Idx := AFileMenu.IndexOf(AInsertBefore);

  for I := 0 to Prefs.RecentFilesCount - 1 do
  begin
    Item := TMenuItem.Create(AFileMenu.Owner);
    if Prefs.RecentFiles[I] <> '' then
    begin
      Item.Caption := ExtractFileName(Prefs.RecentFiles[I]);
      Item.Hint := Prefs.RecentFiles[I];
      Item.Tag := I;
      Item.OnClick := AClickEvent;
    end
    else
    begin
      Item.Caption := '(none)';
      Item.Enabled := False;
      Item.Tag := -1;
    end;
    RecentItems[I] := Item;
    AFileMenu.Insert(Idx + 1, Item);
    TranslateMenuItem(Item);
    Inc(Idx);
  end;
end;

end.
