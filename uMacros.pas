unit uMacros;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  uI18n;

type
  TMacroStep = record
    Code: string;      // identyfikator efektu, np. 'BLUR'
    Params: string;    // wartosci parametrow, separator '|'
  end;

  TMacro = record
    Name: string;
    Steps: array of TMacroStep;
  end;

  TMacroRecorder = class
  private
    FActive: Boolean;
    FSteps: array of TMacroStep;
  public
    procedure Start;
    procedure Stop(out M: TMacro);
    procedure Cancel;
    procedure Capture(const Code, Params: string);
    function IsActive: Boolean;
    function StepCount: Integer;
  end;

var
  // Dialog efektu ustawia ten rekord w bloku mrOk; FinishEffect (fMain) go
  // konsumuje i rejestruje krok w aktywnym rejestratorze.
  gMacroPending: TMacroStep;

function MacroRecorder: TMacroRecorder;
function MacroStepLabel(const Code: string): string;
function MacroStepDescription(const Step: TMacroStep): string;
function MacroCodeForOpName(const OpName: string): string;
function MacroFilePath: string;
procedure MacrosLoadFromFile;
procedure MacrosSaveToFile;
procedure MacrosAdd(const M: TMacro);
procedure MacrosDelete(Index: Integer);
procedure MacroDeleteStep(MacroIndex, StepIndex: Integer);
procedure MacrosRename(Index: Integer; const NewName: string);
function MacrosCount: Integer;
function MacrosGet(Index: Integer): TMacro;

implementation

type
  TLabelRec = record
    Code: string;
    LabelEN: string;
  end;

const
  cMacroLabels: array[0..60] of TLabelRec = (
    (Code: 'BLUR';          LabelEN: 'Blur'),
    (Code: 'BRIGHTNESS';    LabelEN: 'Brightness'),
    (Code: 'GAMMA';         LabelEN: 'Gamma correction'),
    (Code: 'LEVELS';        LabelEN: 'Levels'),
    (Code: 'SEPIA';         LabelEN: 'Sepia'),
    (Code: 'SOLARIZE';      LabelEN: 'Solarize'),
    (Code: 'CONTRAST';      LabelEN: 'Contrast'),
    (Code: 'SHARPEN';       LabelEN: 'Sharpen'),
    (Code: 'EMBOSS';        LabelEN: 'Bas-relief'),
    (Code: 'PIXELATE';      LabelEN: 'Pixelation'),
    (Code: 'VIGNETTE';      LabelEN: 'Vignette'),
    (Code: 'EDGE';          LabelEN: 'Edge detection'),
    (Code: 'FILMGRAIN';     LabelEN: 'Film grain'),
    (Code: 'RELIEF';        LabelEN: 'Bas-relief'),
    (Code: 'GLOW';          LabelEN: 'Glow'),
    (Code: 'OILPAINT';      LabelEN: 'Oil painting'),
    (Code: 'CROSSPROCESS';  LabelEN: 'Cross process'),
    (Code: 'BW';            LabelEN: 'Black & white'),
    (Code: 'GRAY';          LabelEN: 'Grayscale'),
    (Code: 'INVERT';        LabelEN: 'Negative'),
    (Code: 'FALSEIR';       LabelEN: 'False-color IR'),
    (Code: 'NIGHTVISION';   LabelEN: 'Night vision'),
    (Code: 'THERMAL';       LabelEN: 'Thermal'),
    (Code: 'ORTON';         LabelEN: 'Orton'),
    (Code: 'XRAY';          LabelEN: 'X-Ray'),
    (Code: 'CYANOTYPE';     LabelEN: 'Cyanotype'),
    (Code: 'SALTPRINT';     LabelEN: 'Salt print'),
    (Code: 'EQUALIZE';      LabelEN: 'Histogram equalization'),
    (Code: 'WB1';           LabelEN: 'WB 1.x palette'),
    (Code: 'WB2';           LabelEN: 'WB 2.x/3.x palette'),
    (Code: 'OCS32';         LabelEN: 'OCS 32 palette'),
    (Code: 'EHB64';         LabelEN: 'EHB 64 palette'),
    (Code: 'AGA256';        LabelEN: 'AGA 256 palette'),
    (Code: 'WB256';         LabelEN: 'Workbench 256 palette'),
    (Code: 'MAGICWB';       LabelEN: 'MagicWB palette'),
    (Code: 'HAM6';          LabelEN: 'HAM6'),
    (Code: 'HAM8';          LabelEN: 'HAM8'),
    (Code: 'FLIPH';         LabelEN: 'Mirror horizontally'),
    (Code: 'FLIPV';         LabelEN: 'Mirror vertically'),
    (Code: 'ROTL';          LabelEN: 'Rotate left'),
    (Code: 'ROTR';          LabelEN: 'Rotate right'),
    (Code: 'ROT180';        LabelEN: 'Rotate 180'),
    (Code: 'STRAIGHTEN';    LabelEN: 'Straighten'),
    (Code: 'STEREOGRAM';    LabelEN: 'Stereogram'),
    (Code: 'CHARCOAL';      LabelEN: 'Charcoal'),
    (Code: 'QUANTIZE';      LabelEN: 'Posterize'),
    (Code: 'BOKEH';         LabelEN: 'Artificial bokeh'),
    (Code: 'ENGRAVING';     LabelEN: 'Engraving'),
    (Code: 'CROSSHATCH';    LabelEN: 'Crosshatch'),
    (Code: 'HALFTONE';      LabelEN: 'Halftone'),
    (Code: 'STIPPLE';       LabelEN: 'Stipple'),
    (Code: 'DICE';          LabelEN: 'Dice'),
    (Code: 'RASTRCMYK';     LabelEN: 'Raster CMYK...'),
    (Code: 'COLORIZE';      LabelEN: 'Colorize'),
    (Code: 'SCREENPRINT';   LabelEN: 'Screen print'),
    (Code: 'MAKIETA';       LabelEN: 'Mockup'),
    (Code: 'LINOCUT';       LabelEN: 'Linocut'),
    (Code: 'AGONY';         LabelEN: 'Amiga gradient (Agony)'),
    (Code: 'AMIGAGRADIENT'; LabelEN: 'Amiga gradient'),
    (Code: 'AMIGABG';       LabelEN: 'Amiga background'),
    (Code: 'AMIGABGS';      LabelEN: 'Amiga background (stretched, MagicWB)')
  );

var
  gRecorder: TMacroRecorder;
  gMacros: array of TMacro;

function MacroRecorder: TMacroRecorder;
begin
  if gRecorder = nil then
    gRecorder := TMacroRecorder.Create;
  Result := gRecorder;
end;

function MacroStepLabel(const Code: string): string;
var
  i: Integer;
begin
  for i := 0 to High(cMacroLabels) do
    if SameText(cMacroLabels[i].Code, Code) then
      Exit(T(cMacroLabels[i].LabelEN));
  Result := Code;
end;

function MacroStepDescription(const Step: TMacroStep): string;
var
  P: TArray<string>;
  i: Integer;
begin
  Result := MacroStepLabel(Step.Code);
  if Step.Params <> '' then
  begin
    P := Step.Params.Split(['|']);
    Result := Result + ' (';
    for i := 0 to High(P) do
    begin
      if i > 0 then Result := Result + ', ';
      Result := Result + P[i];
    end;
    Result := Result + ')';
  end;
end;

function MacroCodeForOpName(const OpName: string): string;
const
  cOpMap: array[0..15] of TLabelRec = (
    (Code: 'CYANOTYPE';   LabelEN: 'Cyanotype'),
    (Code: 'SALTPRINT';   LabelEN: 'Salt print'),
    (Code: 'XRAY';        LabelEN: 'X-Ray'),
    (Code: 'FALSEIR';     LabelEN: 'False-color IR'),
    (Code: 'NIGHTVISION'; LabelEN: 'Night vision'),
    (Code: 'THERMAL';     LabelEN: 'Thermal'),
    (Code: 'ORTON';       LabelEN: 'Orton'),
    (Code: 'WB1';         LabelEN: 'WB 1.x palette'),
    (Code: 'WB2';         LabelEN: 'WB 2.x/3.x palette'),
    (Code: 'HAM6';        LabelEN: 'HAM6'),
    (Code: 'HAM8';        LabelEN: 'HAM8'),
    (Code: 'FLIPH';       LabelEN: 'Mirror horizontally'),
    (Code: 'FLIPV';       LabelEN: 'Mirror vertically'),
    (Code: 'ROTL';        LabelEN: 'Rotate left'),
    (Code: 'ROTR';        LabelEN: 'Rotate right'),
    (Code: 'ROT180';      LabelEN: 'Rotate 180')
  );
var
  i: Integer;
begin
  for i := 0 to High(cOpMap) do
    if SameText(T(cOpMap[i].LabelEN), OpName) then
      Exit(cOpMap[i].Code);
  Result := '';
end;

function MacroFilePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA'))
    + 'Fotografista\macros.json';
end;

procedure MacrosLoadFromFile;
var
  S: TStringList;
  Root, StepsArr: TJSONArray;
  Obj, StepObj: TJSONObject;
  i, k: Integer;
begin
  SetLength(gMacros, 0);
  if not FileExists(MacroFilePath) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(MacroFilePath, TEncoding.UTF8);
    Root := TJSONObject.ParseJSONValue(S.Text) as TJSONArray;
    if Root = nil then Exit;
    try
      for i := 0 to Root.Count - 1 do
      begin
        Obj := Root.Items[i] as TJSONObject;
        SetLength(gMacros, Length(gMacros) + 1);
        gMacros[High(gMacros)].Name := Obj.GetValue('name').Value;
        StepsArr := Obj.GetValue('steps') as TJSONArray;
        SetLength(gMacros[High(gMacros)].Steps, StepsArr.Count);
        for k := 0 to StepsArr.Count - 1 do
        begin
          StepObj := StepsArr.Items[k] as TJSONObject;
          gMacros[High(gMacros)].Steps[k].Code := StepObj.GetValue('code').Value;
          gMacros[High(gMacros)].Steps[k].Params := StepObj.GetValue('params').Value;
        end;
      end;
    finally
      Root.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure MacrosSaveToFile;
var
  Root, StepsArr: TJSONArray;
  Obj, StepObj: TJSONObject;
  S: TStringList;
  i, k: Integer;
begin
  Root := TJSONArray.Create;
  try
    for i := 0 to High(gMacros) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('name', gMacros[i].Name);
      StepsArr := TJSONArray.Create;
      for k := 0 to High(gMacros[i].Steps) do
      begin
        StepObj := TJSONObject.Create;
        StepObj.AddPair('code', gMacros[i].Steps[k].Code);
        StepObj.AddPair('params', gMacros[i].Steps[k].Params);
        StepsArr.Add(StepObj);
      end;
      Obj.AddPair('steps', StepsArr);
      Root.Add(Obj);
    end;
    ForceDirectories(ExtractFilePath(MacroFilePath));
    S := TStringList.Create;
    try
      S.Text := Root.ToJSON;
      S.SaveToFile(MacroFilePath, TEncoding.UTF8);
    finally
      S.Free;
    end;
  finally
    Root.Free;
  end;
end;

procedure MacrosAdd(const M: TMacro);
begin
  SetLength(gMacros, Length(gMacros) + 1);
  gMacros[High(gMacros)] := M;
end;

procedure MacrosDelete(Index: Integer);
var
  i: Integer;
begin
  if (Index < 0) or (Index > High(gMacros)) then Exit;
  for i := Index to High(gMacros) - 1 do
    gMacros[i] := gMacros[i + 1];
  SetLength(gMacros, Length(gMacros) - 1);
end;

procedure MacroDeleteStep(MacroIndex, StepIndex: Integer);
var
  i: Integer;
begin
  if (MacroIndex < 0) or (MacroIndex > High(gMacros)) then Exit;
  if (StepIndex < 0) or (StepIndex > High(gMacros[MacroIndex].Steps)) then Exit;
  for i := StepIndex to High(gMacros[MacroIndex].Steps) - 1 do
    gMacros[MacroIndex].Steps[i] := gMacros[MacroIndex].Steps[i + 1];
  SetLength(gMacros[MacroIndex].Steps, Length(gMacros[MacroIndex].Steps) - 1);
end;

procedure MacrosRename(Index: Integer; const NewName: string);
begin
  if (Index < 0) or (Index > High(gMacros)) then Exit;
  gMacros[Index].Name := NewName;
end;

function MacrosCount: Integer;
begin
  Result := Length(gMacros);
end;

function MacrosGet(Index: Integer): TMacro;
begin
  Result := gMacros[Index];
end;

{ TMacroRecorder }

procedure TMacroRecorder.Start;
begin
  FActive := True;
  SetLength(FSteps, 0);
end;

procedure TMacroRecorder.Stop(out M: TMacro);
var
  i: Integer;
begin
  FActive := False;
  SetLength(M.Steps, Length(FSteps));
  M.Name := '';
  for i := 0 to High(FSteps) do
  begin
    M.Steps[i].Code := FSteps[i].Code;
    M.Steps[i].Params := FSteps[i].Params;
  end;
  SetLength(FSteps, 0);
end;

procedure TMacroRecorder.Cancel;
begin
  FActive := False;
  SetLength(FSteps, 0);
end;

procedure TMacroRecorder.Capture(const Code, Params: string);
begin
  if not FActive then Exit;
  if Code = '' then Exit;
  SetLength(FSteps, Length(FSteps) + 1);
  FSteps[High(FSteps)].Code := Code;
  FSteps[High(FSteps)].Params := Params;
end;

function TMacroRecorder.IsActive: Boolean;
begin
  Result := FActive;
end;

function TMacroRecorder.StepCount: Integer;
begin
  Result := Length(FSteps);
end;

initialization
  MacrosLoadFromFile;

finalization
  gRecorder.Free;

end.
