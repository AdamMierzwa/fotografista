unit frmHistogramDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, uTitleBar;

type
  // Podglad wyrownania na obrazie w edytorze (bez Cofnij i makra); Mode '' =
  // oryginal. Zatwierdzenie/odrzucenie robi wolajacy po ShowModal.
  TEqualizePreviewEvent = procedure(const Mode: string) of object;

  THistogramDlg = class(TFotoForm)
    pboxHistogram: TPaintBox;
    btnAll: TButton;
    btnR: TButton;
    btnG: TButton;
    btnB: TButton;
    btnLum: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    lblInfo: TLabel;
    lblDist: TLabel;
    lblEqualize: TLabel;
    rbEqNone: TRadioButton;
    rbEqRGB: TRadioButton;
    rbEqLum: TRadioButton;
    procedure pboxHistogramPaint(Sender: TObject);
    procedure btnAllClick(Sender: TObject);
    procedure btnRClick(Sender: TObject);
    procedure btnGClick(Sender: TObject);
    procedure btnBClick(Sender: TObject);
    procedure btnLumClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rbEqClick(Sender: TObject);
  public
    procedure RefitButtons; override;
  private
    FDataR: array[0..255] of Integer;
    FDataG: array[0..255] of Integer;
    FDataB: array[0..255] of Integer;
    FDataLum: array[0..255] of Integer;
    FMode: string;
    FEqMode: string;   // '' = bez wyrownania, 'lum', 'rgb'
    FOnPreview: TEqualizePreviewEvent;
  public
    procedure CalcHistogram;
    procedure SetChannel(const Mode: string);
    // Wybrany tryb wyrownania. Wybor pokazuje podglad na obrazie (OnPreview);
    // OK zatwierdza, Anuluj przywraca - obie decyzje w fMain.mnuHistogramClick.
    property EqMode: string read FEqMode;
    property OnPreview: TEqualizePreviewEvent read FOnPreview write FOnPreview;
  end;

var
  HistogramSourceBmp: TBitmap = nil;

procedure EqualizeHistogram(Bitmap: TBitmap; const Mode: string);

implementation

uses
  uI18n;

{$R *.dfm}

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

{ THistogramDlg }

procedure THistogramDlg.FormCreate(Sender: TObject);
begin
  FMode := 'all';
  FEqMode := '';
  rbEqNone.Checked := True;
end;

// Uklad (2026-10-21):
//   Informacja
//     Rozklad barw   [Wszystkie] [R] [G] [B]     [Jasnosc]
//   Wyrownanie
//     (o) Bez wyrownania  ( ) Wyrownaj kanaly RGB  ( ) Wyrownaj jasnosc
//                                                  [OK] [Anuluj]
// Jasnosc ostatnia w obu rzedach. Pozycje z szerokosci tekstow (czcionka
// 8-12 pt, tlumaczenia), rozmiar okna z FitToContent.
procedure THistogramDlg.RefitButtons;
const
  Gap = 6;
var
  X0, Indent, Y, X, Check, W: Integer;
  S: string;

  procedure PlaceRadio(R: TRadioButton);
  begin
    R.Width := Canvas.TextWidth(R.Caption) + Check;
    R.Height := Canvas.TextHeight('Wg') + 4;
    R.Left := X;
    R.Top := Y;
    X := R.Left + R.Width + Gap * 3;
  end;

begin
  inherited;
  FitButton(btnAll, 75);
  FitButton(btnLum, 85);

  // stały margines lewy (wykres jest pozniej centrowany, wiec nie z jego Left -
  // inaczej kolejne wywolania przesuwalyby uklad)
  X0 := CtrlGap * 3;
  pboxHistogram.Left := X0;
  Indent := X0 + Canvas.TextWidth('WW');
  Check := GetSystemMetrics(SM_CXMENUCHECK) + Gap * 2;

  // Informacja
  Y := pboxHistogram.Top + pboxHistogram.Height + SectionGap;
  lblInfo.Left := X0;
  lblInfo.Top := Y;
  Y := lblInfo.Top + lblInfo.Height + RowGap;
  // szerokosc = najdluzsze tlumaczenie ze wszystkich jezykow (TAllLanguages):
  // uklad nie zalezy od jezyka ani od tego, czy liczony przed tlumaczeniem
  lblDist.AutoSize := False;
  W := Canvas.TextWidth(lblDist.Caption);
  for S in TAllLanguages('Color distribution') do
    W := Max(W, Canvas.TextWidth(S));
  lblDist.Width := W;
  lblDist.Height := Canvas.TextHeight('Wg');
  lblDist.Left := Indent;
  lblDist.Top := Y + (btnAll.Height - lblDist.Height) div 2;
  btnAll.Left := lblDist.Left + lblDist.Width + Gap * 3;
  btnR.Left := btnAll.Left + btnAll.Width + Gap;
  btnG.Left := btnR.Left + btnR.Width + Gap;
  btnB.Left := btnG.Left + btnG.Width + Gap;
  btnLum.Left := btnB.Left + btnB.Width + Gap * 4;
  btnAll.Top := Y;
  btnR.Top := Y;
  btnG.Top := Y;
  btnB.Top := Y;
  btnLum.Top := Y;

  // Wyrownanie
  Y := btnAll.Top + btnAll.Height + SectionGap;
  lblEqualize.Left := X0;
  lblEqualize.Top := Y;
  Y := lblEqualize.Top + lblEqualize.Height + RowGap;
  X := Indent;
  PlaceRadio(rbEqNone);
  PlaceRadio(rbEqRGB);
  PlaceRadio(rbEqLum);

  // OK / Anuluj
  Y := rbEqNone.Top + rbEqNone.Height + SectionGap;
  btnOK.Top := Y;
  btnCancel.Top := Y;

  FitToContent(SectionGap, X0);
  // wykres na srodku, gdy rzad wyrownania jest szerszy niz wykres
  pboxHistogram.Left := Max(X0, (ClientWidth - pboxHistogram.Width) div 2);
  AlignButtonsRight([btnOK, btnCancel], X0);
end;

procedure THistogramDlg.CalcHistogram;
var
  W, H: Integer;
  Scale: Double;
  sw, sh: Integer;
  Temp: TBitmap;
  X, Y: Integer;
  Row: PRGBTripleArray;
  rv, gv, bv, lv: Byte;
  i: Integer;
begin
  for i := 0 to 255 do
  begin
    FDataR[i] := 0;
    FDataG[i] := 0;
    FDataB[i] := 0;
    FDataLum[i] := 0;
  end;

  if HistogramSourceBmp = nil then Exit;
  W := HistogramSourceBmp.Width;
  H := HistogramSourceBmp.Height;
  if (W = 0) or (H = 0) then Exit;

  Scale := Min(256.0 / W, 256.0 / H);
  if Scale > 1.0 then Scale := 1.0;
  sw := Max(1, Round(W * Scale));
  sh := Max(1, Round(H * Scale));

  Temp := TBitmap.Create;
  try
    Temp.PixelFormat := pf24bit;
    Temp.SetSize(sw, sh);
    Temp.Canvas.StretchDraw(Rect(0, 0, sw, sh), HistogramSourceBmp);

    for Y := 0 to sh - 1 do
    begin
      Row := Temp.ScanLine[Y];
      for X := 0 to sw - 1 do
      begin
        rv := Row[X].R;
        gv := Row[X].G;
        bv := Row[X].B;
        lv := Round(rv * 0.299 + gv * 0.587 + bv * 0.114);

        Inc(FDataR[rv]);
        Inc(FDataG[gv]);
        Inc(FDataB[bv]);
        Inc(FDataLum[lv]);
      end;
    end;
  finally
    Temp.Free;
  end;
end;

procedure THistogramDlg.SetChannel(const Mode: string);
begin
  FMode := Mode;
  pboxHistogram.Invalidate;
end;

procedure THistogramDlg.btnAllClick(Sender: TObject);
begin
  SetChannel('all');
end;

procedure THistogramDlg.btnRClick(Sender: TObject);
begin
  SetChannel('r');
end;

procedure THistogramDlg.btnGClick(Sender: TObject);
begin
  SetChannel('g');
end;

procedure THistogramDlg.btnBClick(Sender: TObject);
begin
  SetChannel('b');
end;

procedure THistogramDlg.btnLumClick(Sender: TObject);
begin
  SetChannel('lum');
end;

procedure THistogramDlg.rbEqClick(Sender: TObject);
begin
  if rbEqLum.Checked then
    FEqMode := 'lum'
  else if rbEqRGB.Checked then
    FEqMode := 'rgb'
  else
    FEqMode := '';
  // podglad na obrazie; histogram liczony z obrazu po podgladzie
  if Assigned(FOnPreview) then
    FOnPreview(FEqMode);
  CalcHistogram;
  pboxHistogram.Invalidate;
end;

procedure THistogramDlg.pboxHistogramPaint(Sender: TObject);
const
  W = 512;
  H = 256;
  BW = 2;
  PAD = 6;
  BG = $001A1A1A;
  GRID = $00333333;
  COLOR_R = $003333FF;
  COLOR_G = $0044BB33;
  COLOR_B = $00FF5533;
  COLOR_LUM = $00888888;
var
  Canvas: TCanvas;
  maxv: Integer;
  i, x, barh: Integer;
  logmax: Double;
  Hs: array[0..3] of Integer;
  prev, t, k: Integer;
  cr, cg, cb: Byte;
begin
  Canvas := pboxHistogram.Canvas;

  maxv := 1;
  if (FMode = 'all') or (FMode = 'r') then
    for i := 0 to 255 do
      if FDataR[i] > maxv then maxv := FDataR[i];
  if (FMode = 'all') or (FMode = 'g') then
    for i := 0 to 255 do
      if FDataG[i] > maxv then maxv := FDataG[i];
  if (FMode = 'all') or (FMode = 'b') then
    for i := 0 to 255 do
      if FDataB[i] > maxv then maxv := FDataB[i];
  if (FMode = 'all') or (FMode = 'lum') then
    for i := 0 to 255 do
      if FDataLum[i] > maxv then maxv := FDataLum[i];

  logmax := Ln(1.0 + maxv);

  Canvas.Brush.Color := BG;
  Canvas.FillRect(Rect(0, 0, W, H));

  Canvas.Pen.Color := GRID;
  for i := 1 to 3 do
  begin
    x := i * 64 * BW;
    Canvas.MoveTo(x, 0);
    Canvas.LineTo(x, H);
  end;

  // Wszystkie: kanaly nakladane jak swiatlo (addytywnie) - R+G zolty, R+B
  // magenta, G+B cyjan; czesc wspolna wszystkich trzech jasnoszara (nie biala -
  // nie przytlacza kolorowych wierzcholkow), sama jasnosc ciemnoszara.
  // Wczesniej pelne slupki rysowane po kolei i czerwony zaslanial reszte.
  if FMode = 'all' then
  begin
    for i := 0 to 255 do
    begin
      x := i * BW;
      Hs[0] := Round(Ln(1.0 + FDataR[i]) / logmax * (H - PAD));
      Hs[1] := Round(Ln(1.0 + FDataG[i]) / logmax * (H - PAD));
      Hs[2] := Round(Ln(1.0 + FDataB[i]) / logmax * (H - PAD));
      Hs[3] := Round(Ln(1.0 + FDataLum[i]) / logmax * (H - PAD));
      prev := 0;
      // kolejne progi wysokosci od dolu; odcinek [prev, t) pokrywaja kanaly
      // o wysokosci >= t
      repeat
        t := MaxInt;
        for k := 0 to 3 do
          if (Hs[k] > prev) and (Hs[k] < t) then
            t := Hs[k];
        if t = MaxInt then Break;
        cr := IfThen(Hs[0] >= t, 230, 40);
        cg := IfThen(Hs[1] >= t, 230, 40);
        cb := IfThen(Hs[2] >= t, 230, 40);
        if (Hs[0] >= t) and (Hs[1] >= t) and (Hs[2] >= t) then
        begin
          cr := 150; cg := 150; cb := 150;   // wspolna czesc R+G+B
        end
        else if (Hs[0] < t) and (Hs[1] < t) and (Hs[2] < t) then
        begin
          cr := 90; cg := 90; cb := 90;      // tylko jasnosc
        end;
        Canvas.Brush.Color := RGB(cr, cg, cb);
        Canvas.FillRect(Rect(x, H - t, x + BW, H - prev));
        prev := t;
      until False;
    end;
    Exit;
  end;

  for i := 0 to 255 do
  begin
    x := i * BW;

    if (FMode = 'lum') or (FMode = 'all') then
    begin
      barh := Round(Ln(1.0 + FDataLum[i]) / logmax * (H - PAD));
      if barh > 0 then
      begin
        Canvas.Brush.Color := COLOR_LUM;
        Canvas.FillRect(Rect(x, H - barh, x + BW, H));
      end;
    end;

    if (FMode = 'b') or (FMode = 'all') then
    begin
      barh := Round(Ln(1.0 + FDataB[i]) / logmax * (H - PAD));
      if barh > 0 then
      begin
        Canvas.Brush.Color := COLOR_B;
        Canvas.FillRect(Rect(x, H - barh, x + BW, H));
      end;
    end;

    if (FMode = 'g') or (FMode = 'all') then
    begin
      barh := Round(Ln(1.0 + FDataG[i]) / logmax * (H - PAD));
      if barh > 0 then
      begin
        Canvas.Brush.Color := COLOR_G;
        Canvas.FillRect(Rect(x, H - barh, x + BW, H));
      end;
    end;

    if (FMode = 'r') or (FMode = 'all') then
    begin
      barh := Round(Ln(1.0 + FDataR[i]) / logmax * (H - PAD));
      if barh > 0 then
      begin
        Canvas.Brush.Color := COLOR_R;
        Canvas.FillRect(Rect(x, H - barh, x + BW, H));
      end;
    end;
  end;
end;

{ Equalize }

procedure EqualizeHistogram(Bitmap: TBitmap; const Mode: string);
var
  HR, HG, HB, HLum: array[0..255] of Integer;
  W, H, Total, X, Y, i: Integer;
  Row: PRGBTripleArray;
  rv, gv, bv, lv, nlv: Byte;
  cdf, cdfmin: Integer;
  found: Boolean;
  denom: Double;
  MR, MG, MB, ML: array[0..255] of Integer;
  scale: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Total := W * H;

  for i := 0 to 255 do
  begin
    HR[i] := 0; HG[i] := 0; HB[i] := 0; HLum[i] := 0;
  end;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      rv := Row[X].R;
      gv := Row[X].G;
      bv := Row[X].B;
      lv := Round(rv * 0.299 + gv * 0.587 + bv * 0.114);
      Inc(HR[rv]); Inc(HG[gv]); Inc(HB[bv]); Inc(HLum[lv]);
    end;
  end;

  if Mode = 'rgb' then
  begin
    cdfmin := 0; found := False; cdf := 0;
    for i := 0 to 255 do
    begin
      cdf := cdf + HR[i];
      if not found and (cdf > 0) then begin cdfmin := cdf; found := True; end;
      denom := Total - cdfmin;
      if denom > 0 then MR[i] := Max(0, Min(255, Round((cdf - cdfmin) / denom * 255.0)))
      else MR[i] := i;
    end;

    cdfmin := 0; found := False; cdf := 0;
    for i := 0 to 255 do
    begin
      cdf := cdf + HG[i];
      if not found and (cdf > 0) then begin cdfmin := cdf; found := True; end;
      denom := Total - cdfmin;
      if denom > 0 then MG[i] := Max(0, Min(255, Round((cdf - cdfmin) / denom * 255.0)))
      else MG[i] := i;
    end;

    cdfmin := 0; found := False; cdf := 0;
    for i := 0 to 255 do
    begin
      cdf := cdf + HB[i];
      if not found and (cdf > 0) then begin cdfmin := cdf; found := True; end;
      denom := Total - cdfmin;
      if denom > 0 then MB[i] := Max(0, Min(255, Round((cdf - cdfmin) / denom * 255.0)))
      else MB[i] := i;
    end;

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].R := Byte(MR[Row[X].R]);
        Row[X].G := Byte(MG[Row[X].G]);
        Row[X].B := Byte(MB[Row[X].B]);
      end;
    end;
  end
  else
  begin
    cdfmin := 0; found := False; cdf := 0;
    for i := 0 to 255 do
    begin
      cdf := cdf + HLum[i];
      if not found and (cdf > 0) then begin cdfmin := cdf; found := True; end;
      denom := Total - cdfmin;
      if denom > 0 then ML[i] := Max(0, Min(255, Round((cdf - cdfmin) / denom * 255.0)))
      else ML[i] := i;
    end;

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        rv := Row[X].R;
        gv := Row[X].G;
        bv := Row[X].B;
        lv := Round(rv * 0.299 + gv * 0.587 + bv * 0.114);
        nlv := Byte(ML[lv]);
        if lv > 0 then
        begin
          scale := nlv / lv;
          Row[X].R := Byte(Max(0, Min(255, Round(rv * scale))));
          Row[X].G := Byte(Max(0, Min(255, Round(gv * scale))));
          Row[X].B := Byte(Max(0, Min(255, Round(bv * scale))));
        end
        else
        begin
          Row[X].R := nlv;
          Row[X].G := nlv;
          Row[X].B := nlv;
        end;
      end;
    end;
  end;
end;

end.
