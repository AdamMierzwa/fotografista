unit uComicCzarnoBialy;

// Komiks - styl Pop-art - czern (Ben-Day mono, przebudowa dawnego
// Czarno-bialego 2026-10-20). Osobny efekt: laczy go z innymi stylami tylko okno
// frmComicDlg. Przepis: tools\tmp\comic_proto\BENDAY_MONO.md, prototyp
// benday_mono.py.
//   1. bilateral YCbCr (skala robocza 600 px, jak Komiks 1/2),
//   2. plaskie plamy wg samej jasnosci (6 poziomow, granice z rozkladu
//      jasnosci obrazu - ComicLevelKeys, od 2026-10-22), male doklejane do
//      najblizszej duzej, jasnosc plamy = srednia,
//   3. ton plamy z progow ADAPTACYJNYCH (udzial powierzchni od najjasniejszej):
//      papier 15%, rzadkie kropki 35%, geste kropki 30%, czern 20%,
//   4. Ben-Day: kropki rownej wielkosci w obrebie plamy, siatka 45 st.,
//      okres T = Sqrt(W*H)/120 na pelnej rozdzielczosci,
//   5. kreska jak v3 Komiksu 2 (XDoG, filtr ksztaltu, krotkie tylko na mocnej
//      granicy plam, laczenie przerw, wygladzenie konturu, pogrubienie).
// Colors nieuzywany; EdgePct -> tau XDoG; ThickPct -> grubosc kreski.

interface

uses
  Vcl.Graphics;

procedure DoComicCzarnoBialy(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);

implementation

uses
  System.Math, uQuantize, uTransform, uComicTools;

procedure DoComicCzarnoBialy(Bitmap: TBitmap; Colors, EdgePct, ThickPct: Integer);
const
  cRefSize = 600.0;
  cBilatIter = 4;
  cSigmaR = 14.0;
  cLevels = 6;         // poziomy jasnosci plam
  cMinRegion = 40;     // pole w px skali ref. - mniejsze plamy doklejane
  cSigmaE = 1.0;
  cEdgeEps = 1.0;
  cMinLine = 25;       // pole w px skali ref. - mniejsze grupy kreski odpadaja
  cElong = 3.0;        // max(wys, szer)^2 / pole - ponizej klex, nie kreska
  cBigRegion = 150;    // min. pole plamy po obu stronach mocnej granicy
  cRegContrast = 35.0; // min. roznica sredniej jasnosci plam po obu stronach
  cNear = 2;           // odleglosc (Manhattan) piksela kreski od mocnej granicy
  cOnBorder = 0.5;     // czesc krotkiej kreski, ktora musi lezec przy mocnej granicy
  cMinLen = 12;        // min. rozpietosc krotkiej kreski
  cLongLen = 30;       // kreska co najmniej tak dluga zostaje zawsze (pnie, galezie)
  cJoin = 1.5;         // zamkniecie kolem: laczy odcinki z przerwa do ~3 px
  cSmooth = 1.0;       // wygladzenie konturu kreski: Gauss sigma + prog 0.5
  cCells = 120.0;      // kropek na "sredni" bok obrazu: T = Sqrt(W*H)/cCells
  cMinCell = 3.0;
  // tony od najjasniejszego: udzial powierzchni i pokrycie kropka
  cToneShare: array[0..3] of Double = (0.15, 0.35, 0.30, 0.20);
  cToneCover: array[0..3] of Double = (0.0, 0.18, 0.45, 1.0);
  cHistBins = 25601;   // srednia jasnosc plamy z dokladnoscia 0.01 (0..255)
var
  W, H, Ww, Hw, X, Y, K, N, I, P, Q, Qh, Qt, NLab, A: Integer;
  Rv, Gv, Bv: Double;
  Kx, Ky, Nx, Ny, Cn, MinX, MaxX, MinY, MaxY, Ext, MinReg, MinLn, Ix, Iy: Integer;
  X0, Y0, X1, Y1, Best, J: Integer;
  Scale, WS, SigmaE, Tau, Rt, Fx, Fy, Ax, Ay, Yv: Double;
  Work, Mask: TBitmap;
  Lines, MLines: array of PRGBTripleArray;
  PY, PCb, PCr, G1, G2: TArray<Single>;
  Key, Lab, Stack, Comp, Cnt, QY: TArray<Integer>;
  Big, LineB, Vis: TArray<Boolean>;
  Ink: TArray<Byte>;
  SumY, RegCov, Hist: TArray<Double>;
  Lb: array[0..3] of Integer;
  Wt: array[0..3] of Double;
  Tot, BestTot: Double;
  BigReg, Rn, MinLen, LongLen, NearCnt, Rji, Dl, Ri, Tn, B: Integer;
  Rj, SigmaS, Cell, Cum, Total, Bound, U, V, Du, Dv, Cv: Double;
  Strong, NearB: TArray<Boolean>;
  Keep: Boolean;
  Thr: array[0..2] of Integer;

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

    // RGB -> YCbCr
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
        Yv := 0.299 * Rv + 0.587 * Gv + 0.114 * Bv;
        PY[K] := Yv;
        PCb[K] := (Bv - Yv) * 0.564;
        PCr[K] := (Rv - Yv) * 0.713;
      end;
    end;

    // 1. bilateral
    ComicBilateral(PY, PCb, PCr, Ww, Hw, Max(0.75, 3.0 * WS), cSigmaR, cBilatIter);

    // 2a. klucz plamy: sam poziom jasnosci, granice z rozkladu jasnosci obrazu
    //     (ComicLevelKeys, wspolne z Pop-art - dwie farby)
    ComicLevelKeys(PY, cLevels, Key);
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

    // 2c. jasnosc plamy = srednia Y obszaru
    SetLength(SumY, NLab);
    SetLength(Cnt, NLab);
    for I := 0 to NLab - 1 do
    begin
      SumY[I] := 0;
      Cnt[I] := 0;
    end;
    for K := 0 to N - 1 do
    begin
      I := Lab[K];
      SumY[I] := SumY[I] + PY[K];
      Inc(Cnt[I]);
    end;

    // 3. ton plamy: progi z udzialu powierzchni (histogram pola wg sredniej
    //    jasnosci z dokladnoscia 0.01, od najjasniejszej); plama jasniejsza
    //    lub rowna progowi trafia do jasniejszego tonu
    SetLength(QY, NLab);
    SetLength(Hist, cHistBins);
    for I := 0 to cHistBins - 1 do
      Hist[I] := 0;
    for I := 0 to NLab - 1 do
    begin
      QY[I] := EnsureRange(Round(SumY[I] / Cnt[I] * 100), 0, cHistBins - 1);
      Hist[QY[I]] := Hist[QY[I]] + Cnt[I];
    end;
    Total := N;
    Cum := 0;
    Bound := 0;
    Tn := 0;
    for I := 0 to 2 do
      Thr[I] := -1;
    for B := cHistBins - 1 downto 0 do
    begin
      if Hist[B] = 0 then Continue;
      Cum := Cum + Hist[B];
      while (Tn <= 2) and (Cum / Total >= Bound + cToneShare[Tn]) do
      begin
        Bound := Bound + cToneShare[Tn];
        Thr[Tn] := B;
        Inc(Tn);
      end;
    end;
    SetLength(RegCov, NLab);
    for I := 0 to NLab - 1 do
    begin
      RegCov[I] := cToneCover[3];
      for J := 0 to 2 do
        if QY[I] >= Thr[J] then
        begin
          RegCov[I] := cToneCover[J];
          Break;
        end;
    end;

    // 4a. kreska XDoG z mala sigma na wygladzonej jasnosci
    SigmaE := Max(0.5, cSigmaE * WS);
    Tau := 0.95 + 0.04 * (EdgePct / 100.0);   // 50 -> 0.97
    SetLength(G1, N);
    SetLength(G2, N);
    ComicGauss(PY, G1, Ww, Hw, SigmaE);
    ComicGauss(PY, G2, Ww, Hw, SigmaE * 1.6);
    SetLength(LineB, N);
    for K := 0 to N - 1 do
      LineB[K] := G1[K] - Tau * G2[K] < -cEdgeEps;

    // 4b. mocne granice plam: sasiednie piksele w roznych plamach, obie plamy
    //     duze, srednia jasnosc rozna o >= cRegContrast; NearB = piksele w
    //     odleglosci (Manhattan) <= cNear od takiej granicy
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

    // 4c. filtr ksztaltu (8-sasiedztwo): zostaja duze i wydluzone grupy;
    //     krotsze niz cLongLen tylko przy mocnej granicy plam
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

    // 4d. laczenie przerw: zamkniecie kolem cJoin (dylatacja do Strong jako
    //     bufora, potem erozja; poza obrazem nie erodujemy)
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

    // 4e. wygladzenie konturu kreski: Gauss na masce i prog 0.5
    SigmaS := cSmooth * WS;
    if SigmaS >= 0.3 then
    begin
      for K := 0 to N - 1 do
        G1[K] := Ord(LineB[K]);
      ComicGauss(G1, G2, Ww, Hw, SigmaS);
      for K := 0 to N - 1 do
        LineB[K] := G2[K] >= 0.5;
    end;

    // 4f. pogrubienie kolem (suwak Grubosc: 50 -> 1.5 px w skali ref.)
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

    // 5. pelna rozdzielczosc: plama o najwiekszej sumie wag 4 sasiadow (jak
    //    Komiks 1/2), jej pokrycie -> kropki Ben-Day rownej wielkosci na siatce
    //    45 st. (pole kropki = pokrycie * T^2), papier bialy, tusz czarny
    Cell := Max(cMinCell, Sqrt(Int64(W) * H) / cCells);
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
        Cv := RegCov[Best];
        if Cv >= 0.999 then
          A := 0
        else if Cv <= 0 then
          A := 255
        else
        begin
          U := (X + Y) * Sqrt(0.5);
          V := (Y - X) * Sqrt(0.5);
          Du := U - Cell * Floor(U / Cell + 0.5);
          Dv := V - Cell * Floor(V / Cell + 0.5);
          if Sqr(Du) + Sqr(Dv) <= Cv * Cell * Cell / Pi then
            A := 0
          else
            A := 255;
        end;
        Lines[Y][X].R := A;
        Lines[Y][X].G := A;
        Lines[Y][X].B := A;
      end;
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
