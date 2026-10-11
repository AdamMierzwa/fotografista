unit frmPoissonDlg;

// EKSPERYMENT: Poisson o zmiennym promieniu (uPoissonStipple).
// Wersja 1: podglad i okno 100% liczone w watku roboczym (TPoissonWorker). Interfejs nie czeka na wynik.
// Podglad: nawigator 400 px (srednica kropki w podgladzie minimum 3 px, tylko wyswietlanie).
// Okno 100%: fragment obrazu 1:1 z pelna srednica kropki.
// Wynik na pelnym obrazie przy OK liczony w watku TPoissonFullWorker (anulowanie przez Terminated).

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  // Watek roboczy: liczy podglad (Nav) i fragment 100% (Zoom). Wejscie i wyjscie to te same bitmapy.
  TPoissonWorker = class(TThread)
  private
    FNavDiamPx: Double;
    FZoomDiamPx: Double;
    FGamma: Integer;
  public
    Nav: TBitmap;
    Zoom: TBitmap;
    constructor Create(ANav, AZoom: TBitmap; ANavDiamPx, AZoomDiamPx: Double; AGamma: Integer);
    destructor Destroy; override;
    procedure Execute; override;
  end;

  // Watek roboczy pelnego przebiegu (OK). Pracuje na wlasnej kopii obrazu;
  // przerwanie przez Terminated sprawdzane w petlach algorytmu.
  TPoissonFullWorker = class(TThread)
  private
    FSize, FGamma: Integer;
  public
    Bmp: TBitmap;             // kopia robocza (pf24bit); po zakonczeniu wynik
    Cancelled: Boolean;       // True gdy przerwano (wynik niepelny)
    constructor Create(ASource: TBitmap; ASize, AGamma: Integer);
    destructor Destroy; override;
    procedure Execute; override;
  end;

  TPoissonDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblSize: TLabel;
    tbSize: TTrackBar;
    lblSizeVal: TLabel;
    lblGamma: TLabel;
    tbGamma: TTrackBar;
    lblGammaVal: TLabel;
    lblStatus: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbParamChange(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;  // nawigator: caly obraz 400 px (wejscie)
    FWorkingPreview: TBitmap;   // nawigator: wynik
    FZoomBmp: TBitmap;          // okno 100%: fragment wyniku
    FSrcCopy: TBitmap;          // pelny obraz (pf24bit) do fragmentu 100%
    FSourceBmp: TBitmap;
    FSize: Integer;             // dziesiate % krotszego boku (1..100)
    FGamma: Integer;            // 10..500
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    FWorker: TPoissonWorker;    // nil = brak zadania w toku (podglad)
    FFullWorker: TPoissonFullWorker;  // nil = brak pelnego przebiegu w toku
    FFullSW: TStopwatch;        // czas pelnego przebiegu
    FFullElapsed: Double;
    FTimer: TTimer;             // sprawdza koniec zadania (co 30 ms)
    FPending: Boolean;          // parametry zmienily sie w trakcie zadania
    procedure StartWork;
    procedure WorkerTick(Sender: TObject);
    procedure RebuildZoom(X, Y: Integer);
    function CursorRect: TRect;
  end;

function ShowPoissonDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  uPoissonStipple, uI18n;

{$R *.dfm}

const
  NavMinDiamPx = 3.0;  // minimalna srednica kropki w nawigatorze (px)

{ TPoissonWorker }

constructor TPoissonWorker.Create(ANav, AZoom: TBitmap; ANavDiamPx, AZoomDiamPx: Double; AGamma: Integer);
begin
  inherited Create(True);   // watek wstrzymany; Start wywoluje StartWork po przypisaniu do FWorker
  Nav := ANav;
  Zoom := AZoom;
  FNavDiamPx := ANavDiamPx;
  FZoomDiamPx := AZoomDiamPx;
  FGamma := AGamma;
end;

destructor TPoissonWorker.Destroy;
begin
  Nav.Free;
  Zoom.Free;
  inherited;
end;

// Watek nie wywoluje metod VCL (Canvas, Invalidate). Tylko DoPoissonStipplePx na wlasnych bitmapach.
procedure TPoissonWorker.Execute;
begin
  DoPoissonStipplePx(Nav, FNavDiamPx, FGamma, NavMinDiamPx);
  DoPoissonStipplePx(Zoom, FZoomDiamPx, FGamma, 0);
end;

{ TPoissonFullWorker }

constructor TPoissonFullWorker.Create(ASource: TBitmap; ASize, AGamma: Integer);
begin
  inherited Create(True);
  Bmp := TBitmap.Create;
  Bmp.PixelFormat := pf24bit;
  Bmp.Assign(ASource);
  FSize := ASize;
  FGamma := AGamma;
end;

destructor TPoissonFullWorker.Destroy;
begin
  Bmp.Free;
  inherited;
end;

// Pelny przebieg na kopii obrazu; anulowanie przez Terminated sprawdzane w petlach.
procedure TPoissonFullWorker.Execute;
begin
  DoPoissonStipple(Bmp, FSize, FGamma,
    function: Boolean
    begin
      Result := Terminated;
    end);
  Cancelled := Terminated;
end;

{ Okno dialogu }

function ShowPoissonDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TPoissonDlg;
  Scale: Double;
  pw, ph, Bottom, Total: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TPoissonDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    Dlg.FSrcCopy := TBitmap.Create;
    Dlg.FSrcCopy.PixelFormat := pf24bit;
    Dlg.FSrcCopy.Assign(Bitmap);

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);
    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;

    Dlg.pboxPreview.SetBounds(Dlg.CtrlGap, Dlg.TitleBarGap + Dlg.CtrlGap, pw, ph);
    Dlg.pboxZoom.SetBounds(Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2, Dlg.pboxPreview.Top, pw, ph);

    Bottom := Dlg.pboxPreview.Top + ph;
    Dlg.lblSize.Top := Bottom + Dlg.RowGap * 2;
    Dlg.tbSize.Top := Dlg.lblSize.Top + Dlg.lblSize.Height + Dlg.RowGap;
    Dlg.lblSizeVal.Top := Dlg.tbSize.Top + Dlg.tbSize.Height + Dlg.RowGap;
    Dlg.lblGamma.Top := Dlg.lblSizeVal.Top + Dlg.lblSizeVal.Height + Dlg.RowGap * 2;
    Dlg.tbGamma.Top := Dlg.lblGamma.Top + Dlg.lblGamma.Height + Dlg.RowGap;
    Dlg.lblGammaVal.Top := Dlg.tbGamma.Top + Dlg.tbGamma.Height + Dlg.RowGap;
    Dlg.lblStatus.Top := Dlg.lblGammaVal.Top + Dlg.lblGammaVal.Height + Dlg.RowGap;
    Dlg.btnOK.Top := Dlg.lblStatus.Top + Dlg.lblStatus.Height + Dlg.RowGap * 2;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;

    Dlg.FSize := Dlg.tbSize.Position;
    Dlg.FGamma := Dlg.tbGamma.Position;
    Dlg.FWorkingPreview.Assign(Dlg.FOriginalPreview);  // widok startowy do czasu wyniku watku
    Dlg.StartWork;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wycentrowanie pary podgladow i kontrolek pod nimi.
    Total := pw + Dlg.CtrlGap * 2 + pw;
    Dlg.pboxPreview.Left := Max(Dlg.CtrlGap, (Dlg.ClientWidth - Total) div 2);
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.lblSize.Left := Dlg.pboxPreview.Left;
    Dlg.tbSize.Left := Dlg.pboxPreview.Left;
    Dlg.tbSize.Width := Total;
    Dlg.lblSizeVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblSizeVal.Width := Total;
    Dlg.lblGamma.Left := Dlg.pboxPreview.Left;
    Dlg.tbGamma.Left := Dlg.pboxPreview.Left;
    Dlg.tbGamma.Width := Total;
    Dlg.lblGammaVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblGammaVal.Width := Total;
    Dlg.lblStatus.Left := Dlg.pboxPreview.Left;
    Dlg.lblStatus.Width := Total;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      ElapsedSec := Dlg.FFullElapsed;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TPoissonDlg }

procedure TPoissonDlg.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  lblStatus.Caption := '';
  btnOK.ModalResult := mrNone;
  btnOK.OnClick := btnOKClick;
  btnCancel.ModalResult := mrNone;
  btnCancel.OnClick := btnCancelClick;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 30;
  FTimer.OnTimer := WorkerTick;
  tbSize.Position := 4;
  tbGamma.Position := 100;
  tbParamChange(Sender);
end;

procedure TPoissonDlg.FormDestroy(Sender: TObject);
begin
  // Podglad konczy sie sam (krotki); pelny przebieg przerywamy (Terminated sprawdzane w petlach).
  if FWorker <> nil then
  begin
    FWorker.WaitFor;
    FWorker.Free;
    FWorker := nil;
  end;
  if FFullWorker <> nil then
  begin
    FFullWorker.Terminate;
    FFullWorker.WaitFor;
    FFullWorker.Free;
    FFullWorker := nil;
  end;
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FSrcCopy.Free;
end;

procedure TPoissonDlg.tbParamChange(Sender: TObject);
begin
  lblSizeVal.Caption := FormatFloat('0.0', tbSize.Position / 10.0) + '%';
  lblGammaVal.Caption := IntToStr(tbGamma.Position);
  FSize := tbSize.Position;
  FGamma := tbGamma.Position;
  if FSourceBmp = nil then Exit;
  StartWork;
end;

// Uruchamia zadanie w tle z aktualnymi parametrami. Gdy zadanie trwa, zapamietuje potrzebe ponownego liczenia.
procedure TPoissonDlg.StartWork;
var
  Nav, Crop: TBitmap;
begin
  if (FSourceBmp = nil) or (FWorkingPreview = nil) then Exit;
  if FWorker <> nil then
  begin
    FPending := True;
    Exit;
  end;
  FPending := False;

  // Bitmapy tworzone i kopiowane wylacznie w watku glownym (VCL nie jest bezpieczny w watku).
  Nav := TBitmap.Create;
  Nav.PixelFormat := pf24bit;
  Nav.Assign(FOriginalPreview);

  Crop := TBitmap.Create;
  Crop.PixelFormat := pf24bit;
  Crop.SetSize(FZoomW, FZoomH);
  Crop.Canvas.CopyRect(Rect(0, 0, FZoomW, FZoomH), FSrcCopy.Canvas,
    Rect(FZoomX, FZoomY, FZoomX + FZoomW, FZoomY + FZoomH));

  FWorker := TPoissonWorker.Create(Nav, Crop,
    FSize / 1000.0 * Min(FNavW, FNavH),
    FSize / 1000.0 * Min(FSrcCopy.Width, FSrcCopy.Height),
    FGamma);
  FWorker.Start;
  FTimer.Enabled := True;
end;

// Start pelnego przebiegu w tle (przycisk OK).
procedure TPoissonDlg.btnOKClick(Sender: TObject);
begin
  if FFullWorker <> nil then Exit;
  FSize := tbSize.Position;
  FGamma := tbGamma.Position;
  FFullWorker := TPoissonFullWorker.Create(FSourceBmp, FSize, FGamma);
  btnOK.Enabled := False;
  btnCancel.Enabled := True;
  lblStatus.Caption := T('Processing...');
  FFullSW := TStopwatch.StartNew;
  FFullWorker.Start;
  FTimer.Enabled := True;
end;

// Anuluj: w trakcie pelnego przebiegu przerwij i zamknij; inaczej zamknij dialog.
procedure TPoissonDlg.btnCancelClick(Sender: TObject);
begin
  if FFullWorker <> nil then
    FFullWorker.Terminate;
  ModalResult := mrCancel;
end;

// Odbior wyniku w watku glownym, po zakonczeniu zadania.
procedure TPoissonDlg.WorkerTick(Sender: TObject);
var
  W: TPoissonWorker;
  F: TPoissonFullWorker;
  Failed: Boolean;
begin
  // Po ustawieniu ModalResult (anulowanie lub zamkniecie) nie zmieniamy juz wyniku.
  if ModalResult <> mrNone then Exit;

  // Pelny przebieg dominuje: po zakonczeniu zamyka dialog.
  if FFullWorker <> nil then
  begin
    if FFullWorker.Finished then
    begin
      F := FFullWorker;
      FFullWorker := nil;
      F.WaitFor;
      FFullElapsed := FFullSW.Elapsed.TotalSeconds;
      Failed := F.Cancelled;
      if not Failed then
        FSourceBmp.Assign(F.Bmp);
      F.Free;
      if Failed then
        ModalResult := mrCancel
      else
        ModalResult := mrOk;
      Exit;
    end;
  end;

  // Podglad.
  if FWorker <> nil then
  begin
    if FWorker.Finished then
    begin
      W := FWorker;
      FWorker := nil;
      W.WaitFor;
      FWorkingPreview.Assign(W.Nav);
      FZoomBmp.Assign(W.Zoom);
      W.Free;
      pboxPreview.Invalidate;
      pboxZoom.Invalidate;
      if FPending and (FFullWorker = nil) then StartWork;
    end;
  end;

  if (FWorker = nil) and (FFullWorker = nil) then
    FTimer.Enabled := False;
end;

// Okno 100%: ustawia pozycje fragmentu i zleca przeliczenie w tle.
procedure TPoissonDlg.RebuildZoom(X, Y: Integer);
var
  MaxX, MaxY: Integer;
begin
  if (FZoomBmp = nil) or (FSrcCopy = nil) or (FSourceBmp = nil) then Exit;
  MaxX := Max(0, FSrcCopy.Width - FZoomW);
  MaxY := Max(0, FSrcCopy.Height - FZoomH);
  FZoomX := EnsureRange(X, 0, MaxX);
  FZoomY := EnsureRange(Y, 0, MaxY);
  StartWork;
  pboxPreview.Invalidate;
end;

function TPoissonDlg.CursorRect: TRect;
var
  Sx, Sy: Double;
begin
  Sx := FNavW / FSrcCopy.Width;
  Sy := FNavH / FSrcCopy.Height;
  Result.Left := Max(0, Round(FZoomX * Sx));
  Result.Top := Max(0, Round(FZoomY * Sy));
  Result.Right := Min(FNavW, Round((FZoomX + FZoomW) * Sx));
  Result.Bottom := Min(FNavH, Round((FZoomY + FZoomH) * Sy));
end;

procedure TPoissonDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  ImgX := Round(X * FSrcCopy.Width / FNavW);
  ImgY := Round(Y * FSrcCopy.Height / FNavH);
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TPoissonDlg.pboxPreviewPaint(Sender: TObject);
var
  R: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) then
      Draw(0, 0, FWorkingPreview);
    if (FSrcCopy <> nil) and (FZoomW > 0) then
    begin
      R := CursorRect;
      Brush.Style := bsClear;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Rectangle(R);
      Brush.Style := bsSolid;
    end;
  end;
end;

procedure TPoissonDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

end.
