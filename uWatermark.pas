unit uWatermark;

// Znak wodny (2026-10-27): tekst albo logo PNG z przezroczystoscia, 9 kotwic
// albo powielony ukosnie na calym zdjeciu. Wielkosc i margines w % krotszego
// boku zdjecia - ten sam wyglad na zdjeciu 6000 px, Full HD i w podgladzie.
// Schemat: stempel TBitmap32 z przezroczystym tlem (tekst / przeskalowane logo)
// -> opcjonalny obrot -> DrawTo z MasterAlpha = krycie.

interface

uses
  Winapi.Windows, Vcl.Graphics, GR32;   // Windows przed Graphics: TBitmap = Vcl.Graphics.TBitmap

const
  cWmSizeMin = 1;
  cWmSizeMax = 30;
  cWmSizeDefault = 5;          // wysokosc znaku = 5% krotszego boku
  cWmMarginMin = 0;
  cWmMarginMax = 20;
  cWmMarginDefault = 3;
  cWmOpacityMin = 10;
  cWmOpacityMax = 100;
  cWmOpacityDefault = 60;
  cWmAnchorDefault = 8;        // prawy dolny rog
  cWmTileAngle = 30;           // kat powielonego znaku (stopnie)

type
  TWatermarkKind = (wkText, wkLogo);

  TWatermarkParams = record
    Kind: TWatermarkKind;
    Text: string;
    FontName: string;
    Bold: Boolean;
    Color: TColor;
    LogoPath: string;
    Anchor: Integer;           // 0..8: wiersz*3 + kolumna (0 = lewy gorny)
    Tiled: Boolean;
    SizePct: Integer;
    MarginPct: Integer;
    Opacity: Integer;          // 10..100
    Shadow: Boolean;           // tylko tekst
  end;

function DefaultWatermarkParams: TWatermarkParams;

// Parametry makra (separator '|'; '%' i '|' w tekscie/sciezce kodowane jako
// %25 / %7C, zeby Split w uMacros nie rozbijal tekstu znaku).
function WatermarkParamsToStr(const P: TWatermarkParams): string;
function StrToWatermarkParams(const S: string): TWatermarkParams;

// Wczytuje logo PNG (z kanalem alfa). False = brak pliku albo blad odczytu.
function LoadWatermarkLogo(const APath: string; Logo: TBitmap32): Boolean;

// Naklada znak na Bitmap. Logo: wczytane wczesniej (podglad nie czyta pliku
// przy kazdym ruchu suwaka); nil przy wkLogo = nic nie rysuje, wynik False.
function DoWatermark(Bitmap: TBitmap; const P: TWatermarkParams;
  Logo: TBitmap32): Boolean;

// Krok makra WATERMARK: parametry z napisu, logo czytane z pliku przy kazdym
// kroku (Przetwarzanie wsadowe - plik moze sie zmienic miedzy seriami).
function DoWatermarkFromStr(Bitmap: TBitmap; const S: string): Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.Types, System.Math, GR32_Png,
  GR32_PortableNetworkGraphic, GR32_Resamplers,   // Classes, PNG...: inline LoadBitmap32FromPNG (H2443)
  GR32_Transforms;

function DefaultWatermarkParams: TWatermarkParams;
begin
  Result.Kind := wkText;
  Result.Text := '© ' + FormatDateTime('yyyy', Now);
  Result.FontName := 'Segoe UI';
  Result.Bold := True;
  Result.Color := clWhite;
  Result.LogoPath := '';
  Result.Anchor := cWmAnchorDefault;
  Result.Tiled := False;
  Result.SizePct := cWmSizeDefault;
  Result.MarginPct := cWmMarginDefault;
  Result.Opacity := cWmOpacityDefault;
  Result.Shadow := True;
end;

function WmEsc(const S: string): string;
begin
  Result := StringReplace(S, '%', '%25', [rfReplaceAll]);
  Result := StringReplace(Result, '|', '%7C', [rfReplaceAll]);
end;

function WmUnesc(const S: string): string;
begin
  Result := StringReplace(S, '%7C', '|', [rfReplaceAll]);
  Result := StringReplace(Result, '%25', '%', [rfReplaceAll]);
end;

function WatermarkParamsToStr(const P: TWatermarkParams): string;
begin
  Result := IntToStr(Ord(P.Kind)) + '|' + WmEsc(P.Text) + '|' + WmEsc(P.FontName) +
    '|' + IntToStr(Ord(P.Bold)) + '|' + IntToStr(Integer(P.Color)) +
    '|' + WmEsc(P.LogoPath) + '|' + IntToStr(P.Anchor) + '|' + IntToStr(Ord(P.Tiled)) +
    '|' + IntToStr(P.SizePct) + '|' + IntToStr(P.MarginPct) +
    '|' + IntToStr(P.Opacity) + '|' + IntToStr(Ord(P.Shadow));
end;

function StrToWatermarkParams(const S: string): TWatermarkParams;
var
  A: TArray<string>;
begin
  Result := DefaultWatermarkParams;
  A := S.Split(['|']);
  if Length(A) < 12 then Exit;
  if A[0] = '1' then Result.Kind := wkLogo else Result.Kind := wkText;
  Result.Text := WmUnesc(A[1]);
  Result.FontName := WmUnesc(A[2]);
  Result.Bold := A[3] = '1';
  Result.Color := TColor(StrToIntDef(A[4], Integer(clWhite)));
  Result.LogoPath := WmUnesc(A[5]);
  Result.Anchor := EnsureRange(StrToIntDef(A[6], cWmAnchorDefault), 0, 8);
  Result.Tiled := A[7] = '1';
  Result.SizePct := EnsureRange(StrToIntDef(A[8], cWmSizeDefault), cWmSizeMin, cWmSizeMax);
  Result.MarginPct := EnsureRange(StrToIntDef(A[9], cWmMarginDefault), cWmMarginMin, cWmMarginMax);
  Result.Opacity := EnsureRange(StrToIntDef(A[10], cWmOpacityDefault), cWmOpacityMin, cWmOpacityMax);
  Result.Shadow := A[11] = '1';
end;

function LoadWatermarkLogo(const APath: string; Logo: TBitmap32): Boolean;
begin
  Result := False;
  if (APath = '') or not FileExists(APath) then
    Exit;
  try
    LoadBitmap32FromPNG(Logo, APath);
    Result := not Logo.Empty;
  except
    Result := False;
  end;
end;

// Stempel tekstu: przezroczyste tlo, cien (opcjonalnie) i napis. cmMerge -
// RenderText laczy z przezroczystym tlem stempla (GR32.pas, TBitmap32.RenderText
// uzywa CombineMode celu).
procedure BuildTextStamp(Stamp: TBitmap32; const P: TWatermarkParams;
  HeightPx: Integer);
var
  Sz: TSize;
  D: Integer;
begin
  Stamp.SetSize(1, 1);
  Stamp.Font.Name := P.FontName;
  Stamp.Font.Height := -Max(4, HeightPx);
  if P.Bold then
    Stamp.Font.Style := [fsBold]
  else
    Stamp.Font.Style := [];
  Sz := Stamp.TextExtent(P.Text);
  if P.Shadow then
    D := Max(1, HeightPx div 16)
  else
    D := 0;
  Stamp.SetSize(Sz.cx + D + 2, Sz.cy + D + 2);
  Stamp.Clear(0);
  Stamp.CombineMode := cmMerge;
  if P.Shadow then
    Stamp.RenderText(1 + D, 1 + D, P.Text, SetAlpha(clBlack32, 160), True);
  Stamp.RenderText(1, 1, P.Text, Color32(P.Color), True);
end;

// Stempel logo: wysokosc = HeightPx, szerokosc z proporcji. Przy duzym
// zmniejszaniu TDraftResampler (usrednianie), inaczej liniowo.
procedure BuildLogoStamp(Stamp, Logo: TBitmap32; HeightPx: Integer);
var
  W, H: Integer;
begin
  H := Max(1, HeightPx);
  W := Max(1, Round(Logo.Width * H / Logo.Height));
  Stamp.SetSize(W, H);
  Stamp.Clear(0);
  if Logo.Height > H * 2 then
    TDraftResampler.Create(Logo)
  else
    TLinearResampler.Create(Logo);
  Logo.DrawMode := dmOpaque;     // kopiuje tez kanal alfa logo
  Logo.DrawTo(Stamp, Stamp.BoundsRect, Logo.BoundsRect);
end;

// Obrot stempla o cWmTileAngle; tlo poza stemplem przezroczyste.
procedure RotateStamp(Stamp, Rot: TBitmap32);
var
  T: TAffineTransformation;
  B: TFloatRect;
begin
  T := TAffineTransformation.Create;
  try
    T.SrcRect := FloatRect(0, 0, Stamp.Width, Stamp.Height);
    T.Translate(-Stamp.Width / 2, -Stamp.Height / 2);
    T.Rotate(cWmTileAngle);
    B := T.GetTransformedBounds;
    T.Translate(-B.Left, -B.Top);
    Rot.SetSize(Ceil(B.Right - B.Left), Ceil(B.Bottom - B.Top));
    Rot.Clear(0);
    Stamp.OuterColor := 0;
    Stamp.DrawMode := dmOpaque;
    TLinearResampler.Create(Stamp);
    Transform(Rot, Stamp, T);
  finally
    T.Free;
  end;
end;

function DoWatermark(Bitmap: TBitmap; const P: TWatermarkParams;
  Logo: TBitmap32): Boolean;
var
  Dst, Stamp, Rot, Mark: TBitmap32;
  Short, HeightPx, MarginPx, X, Y, Col, Row, StepX, StepY, Gap, Shift: Integer;
begin
  Result := False;
  if (Bitmap.Width < 1) or (Bitmap.Height < 1) then Exit;
  if (P.Kind = wkLogo) and ((Logo = nil) or Logo.Empty) then Exit;
  if (P.Kind = wkText) and (Trim(P.Text) = '') then Exit;

  Short := Min(Bitmap.Width, Bitmap.Height);
  HeightPx := Max(1, Round(Short * EnsureRange(P.SizePct, cWmSizeMin, cWmSizeMax) / 100));
  MarginPx := Round(Short * EnsureRange(P.MarginPct, cWmMarginMin, cWmMarginMax) / 100);

  Dst := TBitmap32.Create;
  Stamp := TBitmap32.Create;
  Rot := TBitmap32.Create;
  try
    Dst.Assign(Bitmap);
    Dst.ResetAlpha;
    if P.Kind = wkText then
      BuildTextStamp(Stamp, P, HeightPx)
    else
      BuildLogoStamp(Stamp, Logo, HeightPx);

    if P.Tiled then
    begin
      RotateStamp(Stamp, Rot);
      Mark := Rot;
    end
    else
      Mark := Stamp;

    Mark.DrawMode := dmBlend;
    Mark.CombineMode := cmBlend;   // cel (zdjecie) nieprzezroczysty
    Mark.MasterAlpha := Round(255 * EnsureRange(P.Opacity, cWmOpacityMin, cWmOpacityMax) / 100);

    if P.Tiled then
    begin
      // siatka "cegielek": co drugi wiersz przesuniety o pol kroku; start
      // przed krawedzia, zeby znak wchodzil tez na brzegi
      Gap := Max(MarginPx, Mark.Height div 2);
      StepX := Mark.Width + Gap;
      StepY := Mark.Height + Gap;
      Row := 0;
      Y := -StepY div 2;
      while Y < Dst.Height do
      begin
        if Odd(Row) then Shift := StepX div 2 else Shift := 0;
        X := -StepX + Shift;
        while X < Dst.Width do
        begin
          Mark.DrawTo(Dst, X, Y);
          Inc(X, StepX);
        end;
        Inc(Y, StepY);
        Inc(Row);
      end;
    end
    else
    begin
      Col := EnsureRange(P.Anchor, 0, 8) mod 3;
      Row := EnsureRange(P.Anchor, 0, 8) div 3;
      case Col of
        0: X := MarginPx;
        1: X := (Dst.Width - Mark.Width) div 2;
      else
        X := Dst.Width - Mark.Width - MarginPx;
      end;
      case Row of
        0: Y := MarginPx;
        1: Y := (Dst.Height - Mark.Height) div 2;
      else
        Y := Dst.Height - Mark.Height - MarginPx;
      end;
      Mark.DrawTo(Dst, X, Y);
    end;

    Bitmap.Assign(Dst);
    Bitmap.PixelFormat := pf24bit;
    Result := True;
  finally
    Rot.Free;
    Stamp.Free;
    Dst.Free;
  end;
end;

function DoWatermarkFromStr(Bitmap: TBitmap; const S: string): Boolean;
var
  P: TWatermarkParams;
  Logo: TBitmap32;
begin
  P := StrToWatermarkParams(S);
  Logo := TBitmap32.Create;
  try
    if (P.Kind = wkLogo) and not LoadWatermarkLogo(P.LogoPath, Logo) then
      Exit(False);
    Result := DoWatermark(Bitmap, P, Logo);
  finally
    Logo.Free;
  end;
end;

end.
