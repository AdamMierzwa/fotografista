unit uComicKomiks2;

// Komiks - styl PRL - raster (robocza nazwa w prototypie: Komiks 2). Osobny efekt: laczy go z innymi
// stylami tylko okno frmComicDlg.

interface

uses
  Vcl.Graphics;

procedure DoComic2(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);

implementation

uses
  System.Math, uQuantize, uTransform, uRastrCMYK, uComicTools;

// PRL - raster (styl 3 w cComicStyles) - WLASNA KOPIA potoku Komiksu 1 (zmiana
// Komiksu 1 tego stylu nie rusza). Przepis bazy zatwierdzony 2026-10-20
// (tools\tmp\comic_proto\KOMIKS1.md, prototyp cartoon2.py):
//   1. bilateral YCbCr (jak Kreskowka),
//   2. plaskie plamy: klucz = poziom jasnosci x sektor odcienia (10 + "szary"),
//      spojne obszary (4-sasiedztwo), male doklejane do najblizszego duzego,
//      kolor plamy = srednia obszaru,
//   3. kreska XDoG z mala sigma + filtr ksztaltu (zostaja wydluzone grupy,
//      odpadaja klexy) + pogrubienie kolem,
//   4. powrot do pelnej rozdzielczosci: plama wg najwiekszej sumy wag 4
//      sasiadow (gladkie granice bez rozmycia kolorow), maska kreski HALFTONE.
// Skala robocza 600 px (Sqrt(W*H)) - podglad i pelny obraz w tych samych proporcjach.
// Colors -> liczba poziomow jasnosci, EdgePct -> tau XDoG, ThickPct -> grubosc kreski.
// Dodatki Komiksu 2 (styl 5): kontrast x1.3 na wejsciu, plamy ciemniejsze
// niz cSpotBlack zalane czernia (tusz w cieniach), baza przepuszczona przez
// DoRastrCmyk (te same ustawienia domyslne co okno Druk - Raster CMYK), kreska
// na wierzchu. Kreska (2026-10-20, prototyp komiks2_kreska.py v3): krotkie
// kreski tylko na mocnej granicy duzych plam, laczenie przerw i wygladzenie
// konturu - bez "przecinkow" z faktury lisci.
procedure DoComic2(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);
const
  cRefSize = 600.0;
  cBilatIter = 4;
  cSigmaR = 14.0;
  cHueSectors = 10;
  cGrayChroma = 8.0;   // chroma ponizej: plama "szara", bez sektora odcienia
  cMinRegion = 40;     // pole w px skali ref. - mniejsze plamy doklejane
  cSat = 1.25;
  cSigmaE = 1.0;
  cEdgeEps = 1.0;
  cMinLine = 25;       // pole w px skali ref. - mniejsze grupy kreski odpadaja
  cElong = 3.0;        // max(wys, szer)^2 / pole - ponizej klex, nie kreska
  cRasterContrast = 1.3;
  cSpotBlack = 55;     // srednia jasnosc plamy ponizej: czysty tusz (Komiks 2)
  Raster = True;      // Komiks 2 zawsze: kontrast, czarne cienie, raster CMYK
  // Kreska bez "przecinkow" w lisciach (prototyp komiks2_kreska.py v3, 2026-10-20);
  // dlugosci i pola w px skali ref.
  cBigRegion = 150;    // min. pole plamy po obu stronach mocnej granicy
  cRegContrast = 35.0; // min. roznica sredniej jasnosci plam po obu stronach
  cNear = 2;           // odleglosc (Manhattan) piksela kreski od mocnej granicy
  cOnBorder = 0.5;     // czesc krotkiej kreski, ktora musi lezec przy mocnej granicy
  cMinLen = 12;        // min. rozpietosc krotkiej kreski
  cLongLen = 30;       // kreska co najmniej tak dluga zostaje zawsze (pnie, galezie)
  cJoin = 1.5;         // zamkniecie kolem: laczy odcinki z przerwa do ~3 px
  cSmooth = 1.0;       // wygladzenie konturu kreski: Gauss sigma + prog 0.5
var
  W, H, Ww, Hw, X, Y, K, N, I, P, Q, Qh, Qt, NLab, Lv, Sec, Ri, A, Grid: Integer;
  Rv, Gv, Bv: Double;
  Kx, Ky, Nx, Ny, Cn, MinX, MaxX, MinY, MaxY, Ext, MinReg, MinLn, Ix, Iy: Integer;
  X0, Y0, X1, Y1, Best, J: Integer;
  Scale, WS, SigmaE, Tau, Dq, Hue, Chroma, Rt, Fx, Fy, Ax, Ay, Yv, Cb, Cr: Double;
  Work, Mask: TBitmap;
  Lines, MLines: array of PRGBTripleArray;
  PY, PCb, PCr, G1, G2: TArray<Single>;
  Key, Lab, Stack, Comp, Cnt: TArray<Integer>;
  Big, LineB, Vis: TArray<Boolean>;
  Ink, RegR, RegG, RegB: TArray<Byte>;
  SumY, SumCb, SumCr: TArray<Double>;
  Lb: array[0..3] of Integer;
  Wt: array[0..3] of Double;
  Tot, BestTot: Double;
  BigReg, Rn, MinLen, LongLen, NearCnt, Rji, Dl: Integer;
  Rj, SigmaS: Double;
  Strong, NearB: TArray<Boolean>;
  Keep: Boolean;

  // Spojne obszary (4-sasiedztwo) o rownym kluczu; zwraca liczbe obszarow.
  function LabelEqual(const KeyA: TArray<Integer>; var LabA: TArray<Integer>): Integer;
  var
    Ii, Pp, Qq, Sp, Px2, Py2, Dd: Integer;
  begin
    SetLength(LabA, N);
    for Ii := 0 to N - 1 do
      LabA[Ii] := -1;
    Result := 0;
    for Ii := 0 to N - 1 do
      if LabA[Ii] < 0 then
      begin
        LabA[Ii] := Result;
        Stack[0] := Ii;
        Sp := 1;
        while Sp > 0 do
        begin
          Dec(Sp);
          Pp := Stack[Sp];
          Px2 := Pp mod Ww;
          Py2 := Pp div Ww;
          for Dd := 0 to 3 do
          begin
            case Dd of
              0: if Px2 > 0 then Qq := Pp - 1 else Continue;
              1: if Px2 < Ww - 1 then Qq := Pp + 1 else Continue;
              2: if Py2 > 0 then Qq := Pp - Ww else Continue;
            else
              if Py2 < Hw - 1 then Qq := Pp + Ww else Continue;
            end;
            if (LabA[Qq] < 0) and (KeyA[Qq] = KeyA[Pp]) then
            begin
              LabA[Qq] := Result;
              Stack[Sp] := Qq;
              Inc(Sp);
            end;
          end;
        end;
        Inc(Result);
      end;
  end;

begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  Colors := Max(2, Min(16, Colors));
  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Work := TBitmap.Create;
  Mask := TBitmap.Create;
  try
    Scale := Sqrt(Int64(W) * H) / cRefSize;
    Work.Assign(Bitmap);
    Work.PixelFormat := pf24bit;
    if Scale > 1.0 then
    begin
      ImageResize(Work, Max(1, Round(W / Scale)), Max(1, Round(H / Scale)));
      WS := 1.0;
    end
    else
      WS := Scale;
    Ww := Work.Width;
    Hw := Work.Height;
    N := Ww * Hw;

    // RGB -> YCbCr (Komiks 2: z kontrastem)
    SetLength(PY, N);
    SetLength(PCb, N);
    SetLength(PCr, N);
    SetLength(Lines, Hw);
    for Y := 0 to Hw - 1 do
    begin
      Lines[Y] := Work.ScanLine[Y];
      for X := 0 to Ww - 1 do
      begin
        K := Y * Ww + X;
        Rv := Lines[Y][X].R;
        Gv := Lines[Y][X].G;
        Bv := Lines[Y][X].B;
        if Raster then
        begin
          Rv := EnsureRange((Rv - 128) * cRasterContrast + 128, 0.0, 255.0);
          Gv := EnsureRange((Gv - 128) * cRasterContrast + 128, 0.0, 255.0);
          Bv := EnsureRange((Bv - 128) * cRasterContrast + 128, 0.0, 255.0);
        end;
        Yv := 0.299 * Rv + 0.587 * Gv + 0.114 * Bv;
        PY[K] := Yv;
        PCb[K] := (Bv - Yv) * 0.564;
        PCr[K] := (Rv - Yv) * 0.713;
      end;
    end;

    // 1. bilateral
    ComicBilateral(PY, PCb, PCr, Ww, Hw, Max(0.75, 3.0 * WS), cSigmaR, cBilatIter);

    // 2a. klucz plamy: poziom jasnosci x sektor odcienia (kat w plaszczyznie CbCr)
    Dq := 255.0 / Colors;
    SetLength(Key, N);
    for K := 0 to N - 1 do
    begin
      Lv := EnsureRange(Floor(PY[K] / Dq), 0, Colors - 1);
      Chroma := Sqrt(Sqr(PCb[K]) + Sqr(PCr[K]));
      if Chroma < cGrayChroma then
        Sec := cHueSectors
      else
      begin
        Hue := ArcTan2(PCr[K], PCb[K]);
        Sec := Floor((Hue + Pi) / (2 * Pi) * cHueSectors) mod cHueSectors;
      end;
      Key[K] := Lv * (cHueSectors + 1) + Sec;
    end;
    SetLength(Stack, N);
    NLab := LabelEqual(Key, Lab);

    // 2b. male plamy dostaja klucz najblizszej duzej (BFS od duzych plam)
    SetLength(Cnt, NLab);
    for I := 0 to NLab - 1 do
      Cnt[I] := 0;
    for K := 0 to N - 1 do
      Inc(Cnt[Lab[K]]);
    MinReg := Max(2, Round(cMinRegion * WS * WS));
    SetLength(Big, N);
    Qh := 0;
    Qt := 0;
    for K := 0 to N - 1 do
    begin
      Big[K] := Cnt[Lab[K]] >= MinReg;
      if Big[K] then
      begin
        Stack[Qt] := K;
        Inc(Qt);
      end;
    end;
    while Qh < Qt do
    begin
      P := Stack[Qh];
      Inc(Qh);
      Kx := P mod Ww;
      Ky := P div Ww;
      for I := 0 to 3 do
      begin
        case I of
          0: begin Nx := Kx - 1; Ny := Ky; end;
          1: begin Nx := Kx + 1; Ny := Ky; end;
          2: begin Nx := Kx; Ny := Ky - 1; end;
        else
          begin Nx := Kx; Ny := Ky + 1; end;
        end;
        if (Nx < 0) or (Ny < 0) or (Nx >= Ww) or (Ny >= Hw) then Continue;
        Q := Ny * Ww + Nx;
        if Big[Q] then Continue;
        Big[Q] := True;
        Key[Q] := Key[P];
        Stack[Qt] := Q;
        Inc(Qt);
      end;
    end;
    NLab := LabelEqual(Key, Lab);

    // 2c. kolor plamy = srednia Y/Cb/Cr obszaru, nasycenie x cSat
    SetLength(SumY, NLab);
    SetLength(SumCb, NLab);
    SetLength(SumCr, NLab);
    SetLength(Cnt, NLab);
    for I := 0 to NLab - 1 do
    begin
      SumY[I] := 0;
      SumCb[I] := 0;
      SumCr[I] := 0;
      Cnt[I] := 0;
    end;
    for K := 0 to N - 1 do
    begin
      I := Lab[K];
      SumY[I] := SumY[I] + PY[K];
      SumCb[I] := SumCb[I] + PCb[K];
      SumCr[I] := SumCr[I] + PCr[K];
      Inc(Cnt[I]);
    end;
    SetLength(RegR, NLab);
    SetLength(RegG, NLab);
    SetLength(RegB, NLab);
    for I := 0 to NLab - 1 do
    begin
      Yv := SumY[I] / Cnt[I];
      Cb := SumCb[I] / Cnt[I] * cSat;
      Cr := SumCr[I] / Cnt[I] * cSat;
      RegR[I] := Byte(EnsureRange(Round(Yv + 1.403 * Cr), 0, 255));
      RegG[I] := Byte(EnsureRange(Round(Yv - 0.344 * Cb - 0.714 * Cr), 0, 255));
      RegB[I] := Byte(EnsureRange(Round(Yv + 1.773 * Cb), 0, 255));
      if Raster and (Yv < cSpotBlack) then
      begin
        RegR[I] := 0;
        RegG[I] := 0;
        RegB[I] := 0;
      end;
    end;

    // 3a. kreska XDoG z mala sigma na wygladzonej jasnosci
    SigmaE := Max(0.5, cSigmaE * WS);
    Tau := 0.95 + 0.04 * (EdgePct / 100.0);   // 50 -> 0.97
    SetLength(G1, N);
    SetLength(G2, N);
    ComicGauss(PY, G1, Ww, Hw, SigmaE);
    ComicGauss(PY, G2, Ww, Hw, SigmaE * 1.6);
    SetLength(LineB, N);
    for K := 0 to N - 1 do
      LineB[K] := G1[K] - Tau * G2[K] < -cEdgeEps;

    // 3a'. mocne granice plam: sasiednie piksele w roznych plamach, obie plamy
    //      duze, srednia jasnosc rozna o >= cRegContrast; NearB = piksele w
    //      odleglosci (Manhattan) <= cNear od takiej granicy
    BigReg := Max(2, Round(cBigRegion * WS * WS));
    SetLength(Strong, N);
    SetLength(NearB, N);
    for K := 0 to N - 1 do
    begin
      Strong[K] := False;
      NearB[K] := False;
    end;
    for Y := 0 to Hw - 1 do
      for X := 0 to Ww - 1 do
      begin
        K := Y * Ww + X;
        for I := 0 to 1 do
        begin
          if I = 0 then
          begin
            if X = Ww - 1 then Continue;
            Q := K + 1;
          end
          else
          begin
            if Y = Hw - 1 then Continue;
            Q := K + Ww;
          end;
          P := Lab[K];
          J := Lab[Q];
          if (P <> J) and (Cnt[P] >= BigReg) and (Cnt[J] >= BigReg) and
             (Abs(SumY[P] / Cnt[P] - SumY[J] / Cnt[J]) >= cRegContrast) then
          begin
            Strong[K] := True;
            Strong[Q] := True;
          end;
        end;
      end;
    Rn := Max(1, Round(cNear * WS));
    for Y := 0 to Hw - 1 do
      for X := 0 to Ww - 1 do
        if Strong[Y * Ww + X] then
          for Iy := -Rn to Rn do
          begin
            if (Y + Iy < 0) or (Y + Iy > Hw - 1) then Continue;
            Dl := Rn - Abs(Iy);
            for Ix := -Dl to Dl do
            begin
              if (X + Ix < 0) or (X + Ix > Ww - 1) then Continue;
              NearB[(Y + Iy) * Ww + X + Ix] := True;
            end;
          end;

    // 3b. filtr ksztaltu (8-sasiedztwo): zostaja duze i wydluzone grupy;
    //     krotsze niz cLongLen tylko przy mocnej granicy plam (bez "przecinkow"
    //     z faktury lisci)
    MinLn := Max(2, Round(cMinLine * WS * WS));
    MinLen := Max(2, Round(cMinLen * WS));
    LongLen := Max(2, Round(cLongLen * WS));
    SetLength(Vis, N);
    SetLength(Comp, N);
    for K := 0 to N - 1 do
      Vis[K] := False;
    for K := 0 to N - 1 do
      if LineB[K] and not Vis[K] then
      begin
        Cn := 0;
        MinX := K mod Ww; MaxX := MinX;
        MinY := K div Ww; MaxY := MinY;
        Stack[0] := K;
        Qt := 1;
        Vis[K] := True;
        while Qt > 0 do
        begin
          Dec(Qt);
          P := Stack[Qt];
          Comp[Cn] := P;
          Inc(Cn);
          Kx := P mod Ww;
          Ky := P div Ww;
          if Kx < MinX then MinX := Kx;
          if Kx > MaxX then MaxX := Kx;
          if Ky < MinY then MinY := Ky;
          if Ky > MaxY then MaxY := Ky;
          for Iy := -1 to 1 do
            for Ix := -1 to 1 do
            begin
              Nx := Kx + Ix;
              Ny := Ky + Iy;
              if (Nx < 0) or (Ny < 0) or (Nx >= Ww) or (Ny >= Hw) then Continue;
              Q := Ny * Ww + Nx;
              if LineB[Q] and not Vis[Q] then
              begin
                Vis[Q] := True;
                Stack[Qt] := Q;
                Inc(Qt);
              end;
            end;
        end;
        Ext := Max(MaxX - MinX + 1, MaxY - MinY + 1);
        Keep := (Cn >= MinLn) and (Sqr(Ext) / Cn >= cElong);
        if Keep and (Ext < LongLen) then
        begin
          NearCnt := 0;
          for I := 0 to Cn - 1 do
            if NearB[Comp[I]] then
              Inc(NearCnt);
          Keep := (Ext >= MinLen) and (NearCnt >= cOnBorder * Cn);
        end;
        if not Keep then
          for I := 0 to Cn - 1 do
            LineB[Comp[I]] := False;
      end;

    // 3b'. laczenie przerw: zamkniecie kolem cJoin (dylatacja do Strong jako
    //      bufora, potem erozja; poza obrazem nie erodujemy)
    Rj := cJoin * WS;
    Rji := Floor(Rj);
    if Rji >= 1 then
    begin
      for K := 0 to N - 1 do
        Strong[K] := False;
      for Y := 0 to Hw - 1 do
        for X := 0 to Ww - 1 do
          if LineB[Y * Ww + X] then
            for Iy := -Rji to Rji do
            begin
              if (Y + Iy < 0) or (Y + Iy > Hw - 1) then Continue;
              for Ix := -Rji to Rji do
              begin
                if (X + Ix < 0) or (X + Ix > Ww - 1) then Continue;
                if Sqr(Ix) + Sqr(Iy) > Rj * Rj then Continue;
                Strong[(Y + Iy) * Ww + X + Ix] := True;
              end;
            end;
      for Y := 0 to Hw - 1 do
        for X := 0 to Ww - 1 do
        begin
          K := Y * Ww + X;
          Keep := Strong[K];
          if Keep then
            for Iy := -Rji to Rji do
            begin
              if (Y + Iy < 0) or (Y + Iy > Hw - 1) then Continue;
              for Ix := -Rji to Rji do
              begin
                if (X + Ix < 0) or (X + Ix > Ww - 1) then Continue;
                if Sqr(Ix) + Sqr(Iy) > Rj * Rj then Continue;
                if not Strong[(Y + Iy) * Ww + X + Ix] then
                  Keep := False;
              end;
            end;
          LineB[K] := Keep;
        end;
    end;

    // 3b''. wygladzenie konturu kreski: Gauss na masce i prog 0.5 (bez drzenia)
    SigmaS := cSmooth * WS;
    if SigmaS >= 0.3 then
    begin
      for K := 0 to N - 1 do
        G1[K] := Ord(LineB[K]);
      ComicGauss(G1, G2, Ww, Hw, SigmaS);
      for K := 0 to N - 1 do
        LineB[K] := G2[K] >= 0.5;
    end;

    // 3c. pogrubienie kolem (suwak Grubosc: 50 -> 1.5 px w skali ref.)
    Rt := Max(0.5, (0.5 + ThickPct / 50.0) * WS);
    Ri := Ceil(Rt);
    SetLength(Ink, N);
    for K := 0 to N - 1 do
      Ink[K] := 0;
    for Y := 0 to Hw - 1 do
      for X := 0 to Ww - 1 do
        if LineB[Y * Ww + X] then
          for Iy := -Ri to Ri do
          begin
            if (Y + Iy < 0) or (Y + Iy > Hw - 1) then Continue;
            for Ix := -Ri to Ri do
            begin
              if (X + Ix < 0) or (X + Ix > Ww - 1) then Continue;
              if Sqr(Ix) + Sqr(Iy) > Rt * Rt then Continue;
              Ink[(Y + Iy) * Ww + X + Ix] := 255;
            end;
          end;
    Mask.PixelFormat := pf24bit;
    Mask.SetSize(Ww, Hw);
    for Y := 0 to Hw - 1 do
    begin
      MLines := nil;
      SetLength(MLines, 1);
      MLines[0] := Mask.ScanLine[Y];
      for X := 0 to Ww - 1 do
      begin
        MLines[0][X].R := Ink[Y * Ww + X];
        MLines[0][X].G := Ink[Y * Ww + X];
        MLines[0][X].B := Ink[Y * Ww + X];
      end;
    end;

    // 4. pelna rozdzielczosc: plama o najwiekszej sumie wag 4 sasiadow
    //    (jak bilinear, ale bez mieszania kolorow - granice gladkie i ostre)
    Bitmap.SetSize(W, H);
    SetLength(Lines, H);
    for Y := 0 to H - 1 do
      Lines[Y] := Bitmap.ScanLine[Y];
    for Y := 0 to H - 1 do
    begin
      Fy := (Y + 0.5) * Hw / H - 0.5;
      Y0 := EnsureRange(Floor(Fy), 0, Hw - 1);
      Y1 := Min(Y0 + 1, Hw - 1);
      Ay := EnsureRange(Fy - Floor(Fy), 0.0, 1.0);
      for X := 0 to W - 1 do
      begin
        Fx := (X + 0.5) * Ww / W - 0.5;
        X0 := EnsureRange(Floor(Fx), 0, Ww - 1);
        X1 := Min(X0 + 1, Ww - 1);
        Ax := EnsureRange(Fx - Floor(Fx), 0.0, 1.0);
        Lb[0] := Lab[Y0 * Ww + X0]; Wt[0] := (1 - Ax) * (1 - Ay);
        Lb[1] := Lab[Y0 * Ww + X1]; Wt[1] := Ax * (1 - Ay);
        Lb[2] := Lab[Y1 * Ww + X0]; Wt[2] := (1 - Ax) * Ay;
        Lb[3] := Lab[Y1 * Ww + X1]; Wt[3] := Ax * Ay;
        Best := Lb[0];
        BestTot := -1;
        for I := 0 to 3 do
        begin
          Tot := 0;
          for J := 0 to 3 do
            if Lb[J] = Lb[I] then
              Tot := Tot + Wt[J];
          if Tot > BestTot then
          begin
            BestTot := Tot;
            Best := Lb[I];
          end;
        end;
        Lines[Y][X].R := RegR[Best];
        Lines[Y][X].G := RegG[Best];
        Lines[Y][X].B := RegB[Best];
      end;
    end;

    // Komiks 2: raster CMYK na bazie (przed kreska, zeby jej nie poszarpal).
    // Siatka proporcjonalna do rozmiaru (~4/700 jak w oknie Druk - Raster CMYK),
    // ale bez zaokraglania przed *4 (frmRastrCmykDlg.pas:79 skacze co 4 px i na
    // podgladzie ~400 px dawal siatke 1 px = inne kolory). Min. 2 px.
    if Raster then
    begin
      Grid := Min(32, Max(2, Round(Sqrt(Int64(W) * H) / 175.0)));
      DoRastrCmyk(Bitmap, Grid, 100);
      if Bitmap.PixelFormat <> pf24bit then
        Bitmap.PixelFormat := pf24bit;
      for Y := 0 to H - 1 do
        Lines[Y] := Bitmap.ScanLine[Y];
    end;

    // tusz wg maski (HALFTONE przy skalowaniu daje miekkie brzegi kreski)
    if Scale > 1.0 then
      ImageResize(Mask, W, H);
    SetLength(MLines, H);
    for Y := 0 to H - 1 do
      MLines[Y] := Mask.ScanLine[Y];
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        A := MLines[Y][X].R;
        if A = 0 then Continue;
        Lines[Y][X].R := Lines[Y][X].R * (255 - A) div 255;
        Lines[Y][X].G := Lines[Y][X].G * (255 - A) div 255;
        Lines[Y][X].B := Lines[Y][X].B * (255 - A) div 255;
      end;
  finally
    Work.Free;
    Mask.Free;
  end;
end;

end.
