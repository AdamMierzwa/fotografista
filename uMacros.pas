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
function MacroStepDetails(const Step: TMacroStep): TArray<string>;
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

uses
  System.IOUtils, frmComicDlg, frmReliefDlg;

type
  TLabelRec = record
    Code: string;
    LabelEN: string;
  end;

const
  cMacroLabels: array[0..86] of TLabelRec = (
    (Code: 'BLUR';          LabelEN: 'Blur'),
    (Code: 'BRIGHTNESS';    LabelEN: 'Brightness'),
    (Code: 'GAMMA';         LabelEN: 'Gamma correction'),
    (Code: 'LEVELS';        LabelEN: 'Levels'),
    (Code: 'SEPIA';         LabelEN: 'Sepia'),
    (Code: 'SOLARIZE';      LabelEN: 'Solarize'),
    (Code: 'CONTRAST';      LabelEN: 'Contrast'),
    (Code: 'SHARPEN';       LabelEN: 'Sharpen'),
    (Code: 'EMBOSS';        LabelEN: 'Emboss'),
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
    (Code: 'LINERASTER';    LabelEN: 'Line raster'),
    (Code: 'CROSSHATCH';    LabelEN: 'Crosshatch'),
    (Code: 'RASTERKRZ';     LabelEN: 'Cross raster'),
    (Code: 'RASTERPUNKT';   LabelEN: 'Dot raster'),
    (Code: 'HALFTONE';      LabelEN: 'Halftone'),
    (Code: 'STIPPLE';       LabelEN: 'Stipple'),
    (Code: 'DICE';          LabelEN: 'Dice'),
    (Code: 'DICEIMG';       LabelEN: 'Image from dice'),
    (Code: 'RASTRCMYK';     LabelEN: 'Raster CMYK...'),
    (Code: 'COLORIZE';      LabelEN: 'Colorize'),
    (Code: 'EMERGO';        LabelEN: 'Emergo'),
    (Code: 'WHITEBAL';      LabelEN: 'White balance'),
    (Code: 'HSB';           LabelEN: 'HSB balance'),
    (Code: 'VIVID';         LabelEN: 'Vividness'),
    (Code: 'ENHANCE';       LabelEN: 'Photo enhancement'),
    (Code: 'OUTLINE';       LabelEN: 'Outline'),
    (Code: 'GLITCH';        LabelEN: 'Glitch'),
    (Code: 'CMYKMISREG';    LabelEN: 'CMYK error'),
    (Code: 'MIMEOGRAPH';    LabelEN: 'Mimeograph'),
    (Code: 'C64';           LabelEN: 'Commodore 64'),
    (Code: 'ZXSPECTRUM';    LabelEN: 'ZX Spectrum'),
    (Code: 'GAMEBOY';       LabelEN: 'Game Boy'),
    (Code: 'NES';           LabelEN: 'NES - Nestopia'),
    (Code: 'BARREL';        LabelEN: 'Barrel distortion'),
    (Code: 'ARC';           LabelEN: 'Arc distortion'),
    (Code: 'SWIRL';         LabelEN: 'Swirl'),
    (Code: 'POLAR';         LabelEN: 'Polar distortion'),
    (Code: 'WATERRIPPLE';   LabelEN: 'Water ripple'),
    (Code: 'DUOTONE';       LabelEN: 'Duotone'),
    (Code: 'TRITONE';       LabelEN: 'Tritone'),
    (Code: 'QUADTONE';      LabelEN: 'Quad-tone'),
    (Code: 'SCREENPRINT';   LabelEN: 'Screen print'),
    (Code: 'MAKIETA';       LabelEN: 'Mockup'),
    (Code: 'LINOCUT';       LabelEN: 'Linocut'),
    (Code: 'AGONY';         LabelEN: 'Amiga gradient (Agony)'),
    (Code: 'AMIGAGRADIENT'; LabelEN: 'Amiga gradient'),
    (Code: 'AMIGABG';       LabelEN: 'Amiga background'),
    (Code: 'AMIGABGS';      LabelEN: 'Amiga background (stretched, MagicWB)'),
    (Code: 'COMIC';         LabelEN: 'Comic')
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

// Nazwa kroku na liscie krokow Zarzadzania makrami - bez parametrow, te
// pokazuje panel szczegolow (MacroStepDetails). Komiks z nazwa stylu.
function MacroStepDescription(const Step: TMacroStep): string;
begin
  if SameText(Step.Code, 'COMIC') then
    Exit(ComicMacroName(Step.Params));
  Result := MacroStepLabel(Step.Code);
  if Result = '' then
    Result := '?';   // krok bez kodu (stare makra)
end;

// Efekty z jednym suwakiem: etykieta suwaka z .dfm okna efektu (klucz EN,
// tlumaczony przez T()), sprawdzone 2026-10-22 skryptem
// tools\tmp\makra_jeden_param2.py - kazdy klucz jest w i18n/english.tsv.
const
  cMacroParamLabels: array[0..21] of TLabelRec = (
    (Code: 'AMIGAGRADIENT'; LabelEN: 'Intensity (1-100):'),
    (Code: 'BLUR';          LabelEN: 'Intensity (1-100):'),
    (Code: 'BRIGHTNESS';    LabelEN: 'Brightness (0-200, default 100):'),
    (Code: 'CHARCOAL';      LabelEN: 'Intensity (1-100):'),
    (Code: 'DICE';          LabelEN: 'Cell size (4-64 px):'),
    (Code: 'DICEIMG';       LabelEN: 'Cell size (24-64 px):'),
    (Code: 'EDGE';          LabelEN: 'Detection sensitivity (1-100):'),
    (Code: 'EMBOSS';        LabelEN: 'Intensity (1-100):'),
    (Code: 'EMERGO';        LabelEN: 'Intensity (0-100):'),
    (Code: 'FILMGRAIN';     LabelEN: 'Intensity (1-50):'),
    (Code: 'GAMMA';         LabelEN: 'Gamma (100 = no change):'),
    (Code: 'GLOW';          LabelEN: 'Glow radius (1-20):'),
    (Code: 'HALFTONE';      LabelEN: 'Cell size (4-16 px):'),
    (Code: 'LINOCUT';       LabelEN: 'Threshold (1-100):'),
    (Code: 'OILPAINT';      LabelEN: 'Brush radius (1-10):'),
    (Code: 'OUTLINE';       LabelEN: 'Intensity (1-100):'),
    (Code: 'PIXELATE';      LabelEN: 'Cell size (1-100):'),
    (Code: 'SEPIA';         LabelEN: 'Intensity (0-100):'),
    (Code: 'SHARPEN';       LabelEN: 'Intensity (1-100):'),
    (Code: 'SOLARIZE';      LabelEN: 'Intensity (0-100):'),
    (Code: 'STIPPLE';       LabelEN: 'Dot sub-cell size (3-8 px):'),
    (Code: 'VIGNETTE';      LabelEN: 'Intensity (1-100):')
  );

// Tekst bez koncowego dwukropka (etykiety z .dfm, „Okres (px):”).
function StripColon(const S: string): string;
begin
  Result := Trim(S);
  if Result.EndsWith(':') then
    SetLength(Result, Length(Result) - 1);
end;

// Etykieta suwaka bez zakresu i dwukropka: „Intensywnosc (0-100):” ->
// „Intensywnosc”.
function MacroParamLabel(const LabelEN: string): string;
var
  P: Integer;
begin
  Result := Trim(T(LabelEN));
  if Result.EndsWith(':') then
    SetLength(Result, Length(Result) - 1);
  if Result.EndsWith(')') then
  begin
    P := Result.LastIndexOf(' (');
    if P > 0 then
      SetLength(Result, P);
  end;
end;

// TColor zapisany w makrze jako liczba -> „R=.. G=.. B=..” (jak w oknie
// Risografii v3, bez tekstu do tlumaczenia).
function MacroColorStr(const S: string): string;
var
  C: Integer;
begin
  C := StrToIntDef(S, 0);
  Result := Format('R=%d G=%d B=%d', [C and $FF, (C shr 8) and $FF, (C shr 16) and $FF]);
end;

// Kroki z kilkoma parametrami (2026-10-22): kolejnosc parametrow jak przy
// zapisie (gMacroPending.Params w oknach efektow, spis:
// tools\tmp\makra_wiele_param.txt), etykiety z kluczy .dfm tych okien
// (sprawdzone w i18n/english.tsv: tools\tmp\makra_klucze.py). False = kod
// nieobslugiwany tutaj.
function MultiParamDetails(const Code: string; P: TArray<string>;
  out Lines: TArray<string>): Boolean;

  procedure Add(const S: string);
  begin
    Lines := Lines + [S];
  end;

  // kolejne parametry od Start z etykietami suwakow
  procedure Nums(const Keys: array of string; Start: Integer = 0);
  var
    k: Integer;
  begin
    for k := 0 to High(Keys) do
      Add(MacroParamLabel(Keys[k]) + ': ' + P[Start + k]);
  end;

  function YesNo(const S: string): string;
  begin
    if S = '1' then Result := T('Yes') else Result := T('No');
  end;

const
  cCrossPresets: array[0..4] of string = ('E-6 in C-41', 'C-41 in E-6',
    'Kodak in Fuji developer', 'Fuji in Kodak developer', 'ECN-2 in C-41');
  // Warianty okna zniekształceń - kolejnosc i klucze jak w fMain
  // (mnuBarrelClick, mnuArcClick, mnuSwirlClick, mnuPolarClick,
  // mnuWaterRippleClick); zmiana tam = zmiana tutaj.
  cBarrelPresets: array[0..5] of string = ('Weak barrel', 'Medium barrel',
    'Strong barrel', 'Weak pincushion', 'Medium pincushion', 'Strong pincushion');
  cArcPresets: array[0..5] of string = ('45°', '90°', '180°', '360°',
    '90° + rotate', '180° + rotate');
  cSwirlPresets: array[0..5] of string = ('Weak (45°)', 'Medium (90°)',
    'Strong (180°)', 'Very strong (270°)', 'Full (360°)', 'Reverse');
  cPolarPresets: array[0..11] of string = ('Full', 'Half angle', 'Quarter angle',
    'Ring', 'Small radius', 'Smooth', 'Tunnel', 'Swirl', 'Fisheye',
    'Outer stretch', 'Inverted tunnel', '30° slice');
  cRipplePresets: array[0..5] of string = ('Light', 'Medium', 'Strong',
    'Concentric', 'From corner', 'Dense');
  // Pozycje list wyboru okien C64 / Game Boy (frmC64Dlg.dfm, frmGameBoyDlg.dfm)
  cC64Palettes: array[0..1] of string = ('Pepto', 'Colodore');
  cC64Dither: array[0..2] of string = ('Floyd–Steinberg (smooth)',
    'Without dither', 'Pattern (retro)');
  cGameBoyPalettes: array[0..1] of string = ('DMG (green)', 'Pocket (gray)');
var
  N: Integer;

  // pozycja listy z parametru Idx: „Etykieta: nazwa”; poza zakresem - liczba
  procedure Pick(const LabelEN: string; const List: array of string; Idx: Integer);
  begin
    N := StrToIntDef(P[Idx], -1);
    if (N >= Low(List)) and (N <= High(List)) then
      Add(StripColon(T(LabelEN)) + ': ' + T(List[N]))
    else
      Add(StripColon(T(LabelEN)) + ': ' + P[Idx]);
  end;

  // roztrzasanie zapisane jako 1/0 (ZX Spectrum, Game Boy, NES)
  procedure DitherOnOff(Idx: Integer);
  begin
    if P[Idx] = '0' then
      Add(T('Dithering') + ': ' + T('Disabled'))
    else
      Add(T('Dithering') + ': ' + T('Enabled'));
  end;

  procedure Colors(const Keys: array of string);
  var
    k: Integer;
  begin
    for k := 0 to High(Keys) do
      Add(StripColon(T(Keys[k])) + ': ' + MacroColorStr(P[k]));
  end;

begin
  Lines := nil;
  Result := True;
  if Length(P) < 6 then SetLength(P, 6);   // brakujace pola = puste (GLITCH ma 6)
  if SameText(Code, 'AGONY') then
    Nums(['Hue top (0-360):', 'Hue bottom (0-360):', 'Number of bands (32-256):'])
  else if SameText(Code, 'AMIGABG') then
  begin
    Add(StripColon(T('Target resolution:')) + ': ' + P[0] + ' × ' + P[1]);
    Add(MacroParamLabel('Background color (MagicWB palette):') + ': ' + MacroColorStr(P[2]));
  end
  else if SameText(Code, 'AMIGABGS') then
    Add(StripColon(T('Target resolution:')) + ': ' + P[0] + ' × ' + P[1])
  else if SameText(Code, 'BW') then
  begin
    Nums(['Brightness before conversion (0-200):', 'Contrast before conversion (0-10):']);
    Add(T('Dithering') + ': ' + YesNo(P[2]));
  end
  else if SameText(Code, 'BOKEH') then
    Nums(['Strength (1-100):', 'Center X (0-100):', 'Center Y (0-100):',
      'Radius (1-100):', 'Fade (0-100):'])
  else if SameText(Code, 'WHITEBAL') then
    Nums(['Red (100 = no change):', 'Green (100 = no change):', 'Blue (100 = no change):'])
  else if SameText(Code, 'HSB') then
    Nums(['Hue (0-200, default 100):', 'Saturation (0-200, default 100):',
      'Brightness (0-200, default 100):'])
  else if SameText(Code, 'VIVID') then
    Nums(['Strength (0 = none, 100 = max):', 'Saturation (0-100):',
      'Contrast (0 = none, 100):', 'Shadow curve (1 = gentle, 5):'])
  else if SameText(Code, 'ENHANCE') then
    Nums(['Effect strength (0-100):', 'Smart Curves (0-100):'])
  else if SameText(Code, 'GLITCH') then
    Nums(['RGB channel shift (0-30):', 'Line jitter (0-100):', 'Noise (0-100):',
      'CRT effect (0-100):', 'Block loss (0-100):', 'Horizontal band shifts (0-100):'])
  else if SameText(Code, 'CMYKMISREG') then
    Nums(['C:', 'M:', 'Y (px):'])
  else if SameText(Code, 'MIMEOGRAPH') then
  begin
    // zapis: ziarnistosc|krawedzie|toner|farba|zuzycie (frmStencilDlg)
    Nums(['Graininess:', 'Edge sensitivity:', 'Toner:']);
    Add(StripColon(T('Ink color')) + ': ' + MacroColorStr(P[3]));
    Add(MacroParamLabel('Ink wear:') + ': ' + P[4]);
  end
  else if SameText(Code, 'C64') then
  begin
    Pick('Palette:', cC64Palettes, 0);
    Pick('Dithering', cC64Dither, 1);
  end
  else if SameText(Code, 'ZXSPECTRUM') or SameText(Code, 'NES') then
    DitherOnOff(0)
  else if SameText(Code, 'GAMEBOY') then
  begin
    Pick('Palette:', cGameBoyPalettes, 0);
    DitherOnOff(1);
  end
  else if SameText(Code, 'BARREL') then
    Pick('Preset:', cBarrelPresets, 0)
  else if SameText(Code, 'ARC') then
    Pick('Preset:', cArcPresets, 0)
  else if SameText(Code, 'SWIRL') then
    Pick('Preset:', cSwirlPresets, 0)
  else if SameText(Code, 'POLAR') then
    Pick('Preset:', cPolarPresets, 0)
  else if SameText(Code, 'WATERRIPPLE') then
  begin
    Pick('Preset:', cRipplePresets, 0);
    Nums(['Strength', 'Wave density'], 1);
  end
  else if SameText(Code, 'DUOTONE') then
    Colors(['Color 1 (shadows)', 'Color 2 (highlights)'])
  else if SameText(Code, 'TRITONE') then
    Colors(['Color 1 (shadows)', 'Color 2 (midtones)', 'Color 3 (highlights)'])
  else if SameText(Code, 'QUADTONE') then
    Colors(['Color 1 (shadows)', 'Color 2 (midtones)', 'Color 3 (highlights)',
      'Color 4 (extreme highlights)'])
  else if SameText(Code, 'CONTRAST') then
  begin
    if P[0] = '1' then
      Add(StripColon(T('Mode:')) + ': ' + T('Increase'))
    else
      Add(StripColon(T('Mode:')) + ': ' + T('Decrease'));
    Nums(['Intensity (1-10):'], 1);
  end
  else if SameText(Code, 'CROSSPROCESS') then
  begin
    N := StrToIntDef(P[0], -1);
    if (N >= Low(cCrossPresets)) and (N <= High(cCrossPresets)) then
      Add(StripColon(T('Preset:')) + ': ' + T(cCrossPresets[N]))
    else
      Result := False;
  end
  else if SameText(Code, 'CROSSHATCH') then
    Nums(['Cell size (4-16 px):', 'Maximum line thickness (1-8):'])
  else if SameText(Code, 'ENGRAVING') then
    Nums(['Line angle (0-179):', 'Cell size (4-16 px):', 'Maximum line thickness (1-8):'])
  else if SameText(Code, 'LINERASTER') then
    Nums(['Line angle (0-179):', 'Cell size (4-16 px):', 'Maximum line thickness (1-8):',
      'Follow shape (0-100):'])
  else if SameText(Code, 'COLORIZE') then
  begin
    Add(MacroColorStr(P[0]));
    Nums(['Intensity (0-100):'], 1);
  end
  else if SameText(Code, 'LEVELS') then
    // zapis: czern|biel|gamma (frmLevelsDlg) - inna kolejnosc niz w oknie
    Nums(['Black point (0-255):', 'White point (0-255):', 'Gamma (10-500, 100=1.0):'])
  else if SameText(Code, 'MAKIETA') then
    Nums(['Strength (1-100):', 'Band position (0-100):', 'Band height (1-100):', 'Fade (0-100):'])
  else if SameText(Code, 'QUANTIZE') then
  begin
    Nums(['Number of colors (2-64):']);
    Add(T('Dithering') + ': ' + YesNo(P[1]));
  end
  else if SameText(Code, 'RASTERKRZ') then
    Nums(['Cell size (4-64 px):', 'Maximum line thickness (1-64):',
      'Line angle 1 (0-179°):', 'Line angle 2 (0-179°):'])
  else if SameText(Code, 'RASTERPUNKT') then
  begin
    Nums(['Cell size (4-64 px):', 'Dot screen angle (0-45°):',
      'Maximum dot size (10-100%):', 'Tone curve (30-300, 100 = linear):']);
    // zapis w dziesiatych czesciach px, okno pokazuje 0.0-2.0
    Add(MacroParamLabel('Edge smoothing (0.0-2.0 px):') + ': ' +
      FormatFloat('0.0', StrToIntDef(P[4], 0) / 10.0));
  end
  else if SameText(Code, 'RASTRCMYK') then
    Nums(['Cell size (1-32 px):', 'Dot scale [%]:'])
  else if SameText(Code, 'RELIEF') then
  begin
    Nums(['Depth (1-100):']);
    Add(StripColon(T('Material:')) + ': ' + ReliefMaterialName(StrToIntDef(P[1], -1)));
  end
  else if SameText(Code, 'SCREENPRINT') then
  begin
    Add(T('Ink color') + ': ' + MacroColorStr(P[0]));
    Add(T('Paper color') + ': ' + MacroColorStr(P[1]));
    Nums(['Ink amount (lighter = less):'], 2);
  end
  else if SameText(Code, 'STRAIGHTEN') then
    Add(MacroParamLabel('Straightening angle (-10 to +10 degrees):') + ': ' + P[0] + '°')
  else if SameText(Code, 'EQUALIZE') then
  begin
    if SameText(P[0], 'lum') then
      Add(StripColon(T('Equalization')) + ': ' + T('Equalize brightness'))
    else if SameText(P[0], 'rgb') then
      Add(StripColon(T('Equalization')) + ': ' + T('Equalize RGB channels'))
    else
      Result := False;
  end
  else
    Result := False;
end;

// Wiersze panelu szczegolow wybranego kroku: Komiks z etykietami
// (frmComicDlg), efekty z jednym suwakiem z etykieta suwaka, kroki z kilkoma
// parametrami (MultiParamDetails); nieznane - parametry numerowane.
function MacroStepDetails(const Step: TMacroStep): TArray<string>;
var
  P, Lines: TArray<string>;
  i: Integer;
begin
  if SameText(Step.Code, 'COMIC') then
    Exit(ComicMacroDetails(Step.Params));
  Result := nil;
  if Step.Params = '' then Exit;
  P := Step.Params.Split(['|']);
  if MultiParamDetails(Step.Code, P, Lines) then
  begin
    Result := Lines;
    Exit;
  end;
  // Stereogram: tryb|okres|glebokosc|zasiew (frmStereogramDlg.pas:98-100);
  // etykiety z kluczy okna (bez dwukropka, z jednostka), zasiew -1 = losowy
  if SameText(Step.Code, 'STEREOGRAM') then
  begin
    if Length(P) < 4 then SetLength(P, 4);
    if P[0] = '1' then
      Result := [StripColon(T('Output mode:')) + ': ' + T('Anaglyph (red-cyan glasses)')]
    else
      Result := [StripColon(T('Output mode:')) + ': ' + T('Autostereogram (SIRDS)')];
    Result := Result + [StripColon(T('Period (px):')) + ': ' + P[1],
      StripColon(T('Depth (px):')) + ': ' + P[2]];
    if P[3] = '-1' then
      Result := Result + [T('Random seed') + ': ' + T('Yes')]
    else
      Result := Result + [T('Random seed') + ': ' + T('No') + ' (' + P[3] + ')'];
    Exit;
  end;
  // palety Amigi (fMain: Params := IntToStr(Ord(UseDither))) - nie maja
  // suwaka, jedyny parametr to pole wyboru Dithering z okna palety
  if (Length(P) = 1) and (SameText(Step.Code, 'OCS32') or SameText(Step.Code, 'EHB64')
    or SameText(Step.Code, 'AGA256') or SameText(Step.Code, 'WB256')
    or SameText(Step.Code, 'MAGICWB')) then
  begin
    if P[0] = '1' then
      Result := [T('Dithering') + ': ' + T('Yes')]
    else
      Result := [T('Dithering') + ': ' + T('No')];
    Exit;
  end;
  if Length(P) = 1 then
    for i := 0 to High(cMacroParamLabels) do
      if SameText(cMacroParamLabels[i].Code, Step.Code) then
      begin
        Result := [MacroParamLabel(cMacroParamLabels[i].LabelEN) + ': ' + P[0]];
        Exit;
      end;
  for i := 0 to High(P) do
    Result := Result + [IntToStr(i + 1) + '. ' + P[i]];
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
  V: TJSONValue;
  Root, StepsArr: TJSONArray;
  Obj, StepObj: TJSONObject;
  i, k: Integer;
begin
  SetLength(gMacros, 0);
  if not FileExists(MacroFilePath) then Exit;
  S := TStringList.Create;
  try
    { Wolane z initialization: wyjatek z uszkodzonego macros.json
      (zly JSON, inny typ korzenia, brak pola) blokowalby start programu.
      Przy bledzie lista makr zostaje pusta, a plik idzie do macros.json.bad,
      bo pierwszy MacrosSaveToFile nadpisalby go pusta lista. }
    try
      S.LoadFromFile(MacroFilePath, TEncoding.UTF8);
      V := TJSONObject.ParseJSONValue(S.Text);
      if V = nil then Abort;  // zly JSON: Abort, nie Exit - ma trafic do except
      try
        if not (V is TJSONArray) then Abort;
        Root := TJSONArray(V);
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
        V.Free;
      end;
    except
      SetLength(gMacros, 0);
      try
        TFile.Copy(MacroFilePath, MacroFilePath + '.bad', True);
      except
      end;
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
