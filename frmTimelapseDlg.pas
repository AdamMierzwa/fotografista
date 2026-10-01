unit frmTimelapseDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.FileCtrl,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uTitleBar, uI18n, uImageIO, uTransform, uVideoWriter;

type
  TTimelapseSort = (tlsName, tlsDate);
  TTimelapseMode = (tlmSave, tlmPresent);
  TTimelapseView = (tlvWindow, tlvFullscreen);

  TTimelapseOptions = record
    SrcDir: string;
    DstDir: string;
    FileName: string;
    Sort: TTimelapseSort;
    ResIndex: Integer; // 0 = Original, 1 = 3840x2160, 2 = 1920x1080, 3 = 1280x720
    FPS: Double;
    HoldFirstSec: Double;
    HoldLastSec: Double;
    Mode: TTimelapseMode;
    View: TTimelapseView;
  end;

  TTimelapseDlg = class(TFotoForm)
    lblSrc: TLabel;
    lblSrcPath: TLabel;
    btnSrcChoice: TButton;
    pnlSort: TPanel;
    rbSortAlpha: TRadioButton;
    rbSortDate: TRadioButton;
    lblDst: TLabel;
    lblDstPath: TLabel;
    btnDstChoice: TButton;
    lblFileName: TLabel;
    edFileName: TEdit;
    lblFps: TLabel;
    edFps: TEdit;
    lblHoldFirst: TLabel;
    edHoldFirst: TEdit;
    lblHoldLast: TLabel;
    edHoldLast: TEdit;
    lblRes: TLabel;
    cmbRes: TComboBox;
    pnlMode: TPanel;
    rbSave: TRadioButton;
    rbPresent: TRadioButton;
    pnlView: TPanel;
    rbWindow: TRadioButton;
    rbFullscreen: TRadioButton;
    btnStart: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSrcChoiceClick(Sender: TObject);
    procedure btnDstChoiceClick(Sender: TObject);
    procedure rbSaveClick(Sender: TObject);
    procedure rbPresentClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FOpts: TTimelapseOptions;
    procedure LayoutDialog;
    procedure UpdateModeState;
  end;

  TTimelapsePlayer = class(TForm)
  private
    FFiles: TArray<string>;
    FIndex: Integer;
    FMiddleMs: Integer;
    FFirstMs: Integer;
    FLastMs: Integer;
    FImage: TBitmap;
    FTimer: TTimer;
    procedure DoPaint(Sender: TObject);
    procedure DoTick(Sender: TObject);
    procedure CloseOnKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CloseOnChar(Sender: TObject; var Key: Char);
    procedure LoadIndex(AIndex: Integer);
  public
    procedure Init(const AFiles: TArray<string>; AFPS: Double;
      AHoldFirstSec, AHoldLastSec: Double; AFullscreen: Boolean);
    destructor Destroy; override;
  end;

function ShowTimelapseDlg(out Opts: TTimelapseOptions): Boolean;
procedure RunTimelapse(const Opts: TTimelapseOptions);

implementation

{$R *.dfm}

type
  TTimelapseFile = record
    Path: string;
    Name: string;
    Created: TDateTime;
  end;

  TProgressForm = class(TFotoForm)
  public
    Lbl: TLabel;
    BtnAbort: TButton;
    Abort: Boolean;
    constructor Create(AOwner: TComponent); override;
    procedure SetFile(const AName: string; Idx, Total: Integer);
    procedure AbortClick(Sender: TObject);
  end;

{ TProgressForm }

constructor TProgressForm.Create(AOwner: TComponent);
var
  BtnW, LblW: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := T('Timelapse');
  BorderStyle := bsDialog;
  BorderIcons := [];
  Position := poScreenCenter;

  Canvas.Font.Assign(Self.Font);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.AutoSize := False;
  Lbl.EllipsisPosition := epEndEllipsis;
  Lbl.Height := Canvas.TextHeight('Hg') + 4;
  Lbl.Left := CtrlGap * 3;
  Lbl.Top := CtrlGap * 3;
  Lbl.Caption := T('Processing...') + ' 0/0';

  BtnAbort := TButton.Create(Self);
  BtnAbort.Parent := Self;
  BtnAbort.Caption := T('Cancel');
  BtnAbort.OnClick := AbortClick;

  BtnW := Canvas.TextWidth(T('Cancel')) + 24;
  LblW := Canvas.TextWidth(T('Processing...') + ' 0/0') + CtrlGap * 2;
  if LblW < BtnW then LblW := BtnW;
  Lbl.Width := LblW;
  BtnAbort.Width := BtnW;
  BtnAbort.Top := Lbl.Top + Lbl.Height + RowGap;

  FitToContent(CtrlGap * 3, CtrlGap * 3);
  AlignButtonsRight([BtnAbort], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
end;

procedure TProgressForm.SetFile(const AName: string; Idx, Total: Integer);
begin
  Lbl.Caption := AName + ' (' + IntToStr(Idx) + '/' + IntToStr(Total) + ')';
end;

procedure TProgressForm.AbortClick(Sender: TObject);
begin
  Abort := True;
end;

function TimelapseImageFile(const AName: string): Boolean;
const
  Exts: array[0..7] of string = ('.bmp', '.jpg', '.jpeg', '.png', '.gif',
    '.tif', '.tiff', '.webp');
var
  E: string;
  i: Integer;
begin
  Result := False;
  E := LowerCase(ExtractFileExt(AName));
  for i := 0 to High(Exts) do
    if E = Exts[i] then
      Exit(True);
end;

function FileTimeToDateTime(const FT: TFileTime): TDateTime;
var
  LFT: TFileTime;
  ST: TSystemTime;
begin
  Result := 0;
  if FT.dwHighDateTime = 0 then Exit;
  if not FileTimeToLocalFileTime(FT, LFT) then Exit;
  if not FileTimeToSystemTime(LFT, ST) then Exit;
  Result := SystemTimeToDateTime(ST);
end;

function ExifDateTaken(const APath: string; out DT: TDateTime): Boolean;
const
  PropDateTimeOriginal = $9003;
var
  GPBmp: TGPBitmap;
  BufSize: Cardinal;
  Prop: PPropertyItem;
  S: string;
  P: PAnsiChar;
  Y, Mo, D, H, Mi, Sec: Integer;
begin
  Result := False;
  GPBmp := TGPBitmap.Create(WideString(APath));
  try
    if GPBmp.GetWidth = 0 then Exit;
    BufSize := GPBmp.GetPropertyItemSize(PropDateTimeOriginal);
    if BufSize = 0 then Exit;
    GetMem(Prop, BufSize);
    try
      if GPBmp.GetPropertyItem(PropDateTimeOriginal, BufSize, Prop) <> Ok then Exit;
      if Prop^.type_ <> PropertyTagTypeASCII then Exit;
      P := PAnsiChar(Prop^.value);
      if P = nil then Exit;
      SetString(S, P, Prop^.length);
      if S = '' then Exit;
      Y := StrToIntDef(Copy(S, 1, 4), 0);
      Mo := StrToIntDef(Copy(S, 6, 2), 0);
      D := StrToIntDef(Copy(S, 9, 2), 0);
      H := StrToIntDef(Copy(S, 12, 2), 0);
      Mi := StrToIntDef(Copy(S, 15, 2), 0);
      Sec := StrToIntDef(Copy(S, 18, 2), 0);
      try
        DT := EncodeDate(Y, Mo, D) + EncodeTime(H, Mi, Sec, 0);
        Result := True;
      except
      end;
    finally
      FreeMem(Prop);
    end;
  finally
    GPBmp.Free;
  end;
end;

function BuildFileList(const SrcDir: string; SortByDate: Boolean): TArray<TTimelapseFile>;
var
  SR: TSearchRec;
  Dir, FullPath: string;
  Files: TArray<TTimelapseFile>;
  i, j: Integer;
  Tmp: TTimelapseFile;
  Cmp: Boolean;
begin
  SetLength(Files, 0);
  Dir := IncludeTrailingPathDelimiter(SrcDir);
  if FindFirst(Dir + '*.*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then
          if TimelapseImageFile(SR.Name) then
          begin
            FullPath := Dir + SR.Name;
            SetLength(Files, Length(Files) + 1);
            Files[High(Files)].Name := SR.Name;
            Files[High(Files)].Path := FullPath;
            {$IFDEF MSWINDOWS}
            {$WARN SYMBOL_PLATFORM OFF}
            Files[High(Files)].Created := FileTimeToDateTime(SR.FindData.ftCreationTime);
            {$WARN SYMBOL_PLATFORM ON}
            {$ELSE}
            Files[High(Files)].Created := FileDateToDateTime(SR.Time);
            {$ENDIF}
            if SortByDate then
              ExifDateTaken(FullPath, Files[High(Files)].Created);
          end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  if SortByDate then
    for i := 0 to High(Files) - 1 do
      for j := i + 1 to High(Files) do
      begin
        Cmp := Files[j].Created < Files[i].Created;
        if Cmp then
        begin
          Tmp := Files[i];
          Files[i] := Files[j];
          Files[j] := Tmp;
        end;
      end
  else
    for i := 0 to High(Files) - 1 do
      for j := i + 1 to High(Files) do
      begin
        Cmp := CompareText(Files[j].Name, Files[i].Name) < 0;
        if Cmp then
        begin
          Tmp := Files[i];
          Files[i] := Files[j];
          Files[j] := Tmp;
        end;
      end;
  Result := Files;
end;

destructor TTimelapsePlayer.Destroy;
begin
  FImage.Free;
  inherited Destroy;
end;

procedure TTimelapsePlayer.Init(const AFiles: TArray<string>; AFPS: Double;
  AHoldFirstSec, AHoldLastSec: Double; AFullscreen: Boolean);
var
  MiddleMs, FirstMs, LastMs: Integer;
begin
  FFiles := AFiles;
  FIndex := 0;
  if AFPS <= 0 then AFPS := 25;
  MiddleMs := Max(40, Round((1 / AFPS) * 1000));
  FirstMs := Max(MiddleMs, Round(AHoldFirstSec * 1000));
  LastMs := Max(MiddleMs, Round(AHoldLastSec * 1000));
  FMiddleMs := MiddleMs;
  FFirstMs := FirstMs;
  FLastMs := LastMs;
  Caption := T('Timelapse');
  Color := clBlack;
  KeyPreview := True;
  OnPaint := DoPaint;
  OnKeyDown := CloseOnKey;
  OnKeyPress := CloseOnChar;
  if AFullscreen then
  begin
    BorderStyle := bsNone;
    Position := poScreenCenter;
    WindowState := wsMaximized;
  end
  else
  begin
    BorderStyle := bsSizeable;
    Position := poScreenCenter;
    ClientWidth := MulDiv(Screen.WorkAreaWidth, 80, 100);
    ClientHeight := MulDiv(Screen.WorkAreaHeight, 80, 100);
    Constraints.MinWidth := MulDiv(Screen.WorkAreaWidth, 40, 100);
    Constraints.MinHeight := MulDiv(Screen.WorkAreaHeight, 40, 100);
  end;
  FTimer := TTimer.Create(Self);
  FTimer.OnTimer := DoTick;
  if Length(FFiles) > 0 then
  begin
    LoadIndex(0);
    FTimer.Interval := FFirstMs;
  end;
end;

procedure TTimelapsePlayer.LoadIndex(AIndex: Integer);
var
  Bmp: TBitmap;
begin
  if (AIndex < 0) or (AIndex > High(FFiles)) then Exit;
  try
    Bmp := LoadImageFile(FFiles[AIndex]);
    FImage.Free;
    FImage := Bmp;
  except
  end;
  Invalidate;
end;

procedure TTimelapsePlayer.DoTick(Sender: TObject);
begin
  if Length(FFiles) = 0 then Exit;
  FIndex := (FIndex + 1) mod Length(FFiles);
  LoadIndex(FIndex);
  if FIndex = 0 then
    FTimer.Interval := FFirstMs
  else if FIndex = High(FFiles) then
    FTimer.Interval := FLastMs
  else
    FTimer.Interval := FMiddleMs;
end;

procedure TTimelapsePlayer.DoPaint(Sender: TObject);
var
  W, H, DW, DH, X, Y: Integer;
  Scale: Double;
  R: TRect;
begin
  Canvas.Brush.Color := clBlack;
  Canvas.FillRect(ClientRect);
  if (FImage = nil) or (FImage.Width = 0) or (FImage.Height = 0) then Exit;
  W := FImage.Width;
  H := FImage.Height;
  DW := ClientWidth;
  DH := ClientHeight;
  Scale := Min(DW / W, DH / H);
  if Scale > 1.0 then Scale := 1.0;
  DW := Round(W * Scale);
  DH := Round(H * Scale);
  X := (ClientWidth - DW) div 2;
  Y := (ClientHeight - DH) div 2;
  R := Rect(X, Y, X + DW, Y + DH);
  Canvas.StretchDraw(R, FImage);
end;

procedure TTimelapsePlayer.CloseOnKey(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Close;
end;

procedure TTimelapsePlayer.CloseOnChar(Sender: TObject; var Key: Char);
begin
  Close;
end;

function ShowTimelapseDlg(out Opts: TTimelapseOptions): Boolean;
var
  Dlg: TTimelapseDlg;
begin
  Result := False;
  Dlg := TTimelapseDlg.Create(Application);
  try
    Dlg.LayoutDialog;
    if Dlg.ShowModal = mrOk then
    begin
      Opts := Dlg.FOpts;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TTimelapseDlg }

procedure TTimelapseDlg.FormCreate(Sender: TObject);
begin
  cmbRes.Items.Add(T('Original'));
  cmbRes.Items.Add(T('3840×2160'));
  cmbRes.Items.Add(T('1920×1080'));
  cmbRes.Items.Add(T('1280×720'));
  cmbRes.ItemIndex := 0;
  rbFullscreen.Checked := True;
end;

procedure TTimelapseDlg.UpdateModeState;
var
  IsPresent: Boolean;
begin
  IsPresent := rbPresent.Checked;
  lblDst.Enabled := not IsPresent;
  lblDstPath.Enabled := not IsPresent;
  btnDstChoice.Enabled := not IsPresent;
  lblFileName.Enabled := not IsPresent;
  edFileName.Enabled := not IsPresent;
  lblRes.Enabled := not IsPresent;
  cmbRes.Enabled := not IsPresent;
  pnlView.Visible := IsPresent;
  LayoutDialog;
end;

procedure TTimelapseDlg.rbSaveClick(Sender: TObject);
begin
  UpdateModeState;
end;

procedure TTimelapseDlg.rbPresentClick(Sender: TObject);
begin
  UpdateModeState;
end;

procedure TTimelapseDlg.btnSrcChoiceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := lblSrcPath.Caption;
  if Dir = '...' then Dir := '';
  if SelectDirectory(T('Select source folder'), '', Dir, [sdNewUI]) then
  begin
    lblSrcPath.Caption := Dir;
    LayoutDialog;
  end;
end;

procedure TTimelapseDlg.btnDstChoiceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := lblDstPath.Caption;
  if Dir = '...' then Dir := '';
  if SelectDirectory(T('Select output folder'), '', Dir, [sdNewUI]) then
  begin
    lblDstPath.Caption := Dir;
    LayoutDialog;
  end;
end;

procedure TTimelapseDlg.btnStartClick(Sender: TObject);
var
  Txt: string;
  FPS: Double;
  HoldFirst, HoldLast: Double;
  Inv: TFormatSettings;
begin
  Txt := Trim(lblSrcPath.Caption);
  if (Txt = '') or (Txt = '...') then
  begin
    MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  if rbSave.Checked then
  begin
    Txt := Trim(lblDstPath.Caption);
    if (Txt = '') or (Txt = '...') then
    begin
      MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
      Exit;
    end;
    Txt := Trim(edFileName.Text);
    if Txt = '' then
    begin
      MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
      Exit;
    end;
  end;

  Inv := TFormatSettings.Invariant;
  Txt := StringReplace(Trim(edFps.Text), ',', '.', [rfReplaceAll]);
  FPS := StrToFloatDef(Txt, 25, Inv);
  if FPS <= 0 then
  begin
    MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  Txt := StringReplace(Trim(edHoldFirst.Text), ',', '.', [rfReplaceAll]);
  HoldFirst := StrToFloatDef(Txt, 0, Inv);
  if HoldFirst < 0 then HoldFirst := 0;
  Txt := StringReplace(Trim(edHoldLast.Text), ',', '.', [rfReplaceAll]);
  HoldLast := StrToFloatDef(Txt, 0, Inv);
  if HoldLast < 0 then HoldLast := 0;

  FOpts.SrcDir := Trim(lblSrcPath.Caption);
  FOpts.DstDir := Trim(lblDstPath.Caption);
  FOpts.FileName := Trim(edFileName.Text);
  if FOpts.FileName = '' then FOpts.FileName := 'timelapse.mp4';
  FOpts.Sort := tlsName;
  if rbSortDate.Checked then FOpts.Sort := tlsDate;
  FOpts.FPS := FPS;
  FOpts.HoldFirstSec := HoldFirst;
  FOpts.HoldLastSec := HoldLast;
  FOpts.ResIndex := cmbRes.ItemIndex;
  if FOpts.ResIndex < 0 then FOpts.ResIndex := 0;
  FOpts.Mode := tlmSave;
  if rbPresent.Checked then FOpts.Mode := tlmPresent;
  FOpts.View := tlvWindow;
  if rbFullscreen.Checked then FOpts.View := tlvFullscreen;

  if FOpts.Mode = tlmSave then
    if FileExists(IncludeTrailingPathDelimiter(FOpts.DstDir) + FOpts.FileName) then
      if MessageDlg(Format(T('File "%s" already exists.'), [FOpts.FileName]) + #13#10 +
        T('Overwrite?'), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
        Exit;

  ModalResult := mrOk;
end;

procedure TTimelapseDlg.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TTimelapseDlg.LayoutDialog;
// Jawny layout runtime — wzorzec frmStereogramDlg.LayoutDialog / frmTshirtDlg.
var
  Margin, ColLeft, ColCtrl, ColW, RowTop, LabelW, BtnW, MaxW, W, I, RadioW: Integer;
  A: array[0..6] of string;
begin
  Margin := CtrlGap * 3;
  ColLeft := Margin;

  // Szerokość kolumny etykiet — najszersza przetłumaczona etykieta.
  A[0] := T('Source folder:');
  A[1] := T('Output folder:');
  A[2] := T('File name:');
  A[3] := T('Frames per second:');
  A[4] := T('Hold first frame [s]:');
  A[5] := T('Hold last frame [s]:');
  A[6] := T('Target resolution:');
  Self.Canvas.Font.Assign(Self.Font);
  LabelW := 0;
  for I := 0 to 6 do
  begin
    W := Self.Canvas.TextWidth(A[I]);
    if W > LabelW then LabelW := W;
  end;
  ColCtrl := ColLeft + LabelW + CtrlGap * 2;

  // Szerokość przycisku wyboru — tekst + zapas.
  Self.Canvas.Font.Assign(btnSrcChoice.Font);
  BtnW := Self.Canvas.TextWidth(T('Choose...')) + 24;
  btnSrcChoice.Width := BtnW;
  btnDstChoice.Width := BtnW;

  // Szerokość kolumny kontrolek — najszerszy item combo (+ strzałka), pola edycji.
  Self.Canvas.Font.Assign(cmbRes.Font);
  MaxW := 0;
  for I := 0 to cmbRes.Items.Count - 1 do
  begin
    W := Self.Canvas.TextWidth(cmbRes.Items[I]);
    if W > MaxW then MaxW := W;
  end;
  ColW := MaxW + 60;
  if edFileName.Width > ColW then ColW := edFileName.Width;
  if edFps.Width > ColW then ColW := edFps.Width;
  if edHoldFirst.Width > ColW then ColW := edHoldFirst.Width;
  if edHoldLast.Width > ColW then ColW := edHoldLast.Width;
  // Ścieżka + przycisk muszą się zmieścić w kolumnie (szerokość dopasowana do pełnej ścieżki).
  Self.Canvas.Font.Assign(Self.Font);
  W := Self.Canvas.TextWidth(lblSrcPath.Caption);
  if Self.Canvas.TextWidth(lblDstPath.Caption) > W then
    W := Self.Canvas.TextWidth(lblDstPath.Caption);
  W := Max(BtnW + CtrlGap + W, ColW);
  ColW := W;
  // Etykiety ścieżek: AutoSize=False, więc wysokość z fontu (nie obcinać dołu liter).
  Self.Canvas.Font.Assign(lblSrcPath.Font);
  W := Self.Canvas.TextHeight('Wg');
  lblSrcPath.Height := W;
  lblDstPath.Height := W;
  cmbRes.Width := ColW;

  RowTop := Margin;

  // Wiersz 1: katalog źródłowy.
  lblSrc.Left := ColLeft;
  lblSrc.Top := RowTop + (btnSrcChoice.Height - lblSrc.Height) div 2;
  lblSrcPath.Left := ColCtrl;
  lblSrcPath.Width := ColW - BtnW - CtrlGap;
  lblSrcPath.Top := lblSrc.Top;
  btnSrcChoice.Left := ColCtrl + ColW - BtnW;
  btnSrcChoice.Top := RowTop;
  RowTop := StackBelow(btnSrcChoice, RowGap * 2);

  // Sortowanie.
  Self.Canvas.Font.Assign(rbSortAlpha.Font);
  A[5] := T('Alphabetically');
  A[6] := T('By creation date');
  RadioW := 0;
  for I := 5 to 6 do
  begin
    W := Self.Canvas.TextWidth(A[I]) + 30;
    if W > RadioW then RadioW := W;
  end;
  rbSortAlpha.Width := RadioW;
  rbSortDate.Width := RadioW;
  rbSortAlpha.Left := 0;
  rbSortAlpha.Top := 0;
  rbSortDate.Left := 0;
  rbSortDate.Top := rbSortAlpha.Height + 4;
  pnlSort.Left := ColLeft;
  pnlSort.Top := RowTop;
  pnlSort.Width := RadioW;
  pnlSort.Height := rbSortDate.Top + rbSortDate.Height;
  RowTop := StackBelow(pnlSort, SectionGap);

  // Wiersz 3: katalog wynikowy.
  lblDst.Left := ColLeft;
  lblDst.Top := RowTop + (btnDstChoice.Height - lblDst.Height) div 2;
  lblDstPath.Left := ColCtrl;
  lblDstPath.Width := ColW - BtnW - CtrlGap;
  lblDstPath.Top := lblDst.Top;
  btnDstChoice.Left := ColCtrl + ColW - BtnW;
  btnDstChoice.Top := RowTop;
  RowTop := StackBelow(btnDstChoice, RowGap * 2);

  // Nazwa pliku wynikowego.
  lblFileName.Left := ColLeft;
  lblFileName.Top := RowTop + (edFileName.Height - lblFileName.Height) div 2;
  edFileName.Left := ColCtrl;
  edFileName.Width := ColW;
  edFileName.Top := RowTop;
  RowTop := StackBelow(edFileName, RowGap * 2);

  // Częstotliwość klatek.
  lblFps.Left := ColLeft;
  lblFps.Top := RowTop + (edFps.Height - lblFps.Height) div 2;
  edFps.Left := ColCtrl;
  edFps.Top := RowTop;
  RowTop := StackBelow(edFps, RowGap * 2);

  // Przytrzymanie pierwszej klatki.
  lblHoldFirst.Left := ColLeft;
  lblHoldFirst.Top := RowTop + (edHoldFirst.Height - lblHoldFirst.Height) div 2;
  edHoldFirst.Left := ColCtrl;
  edHoldFirst.Top := RowTop;
  RowTop := StackBelow(edHoldFirst, RowGap * 2);

  // Przytrzymanie ostatniej klatki.
  lblHoldLast.Left := ColLeft;
  lblHoldLast.Top := RowTop + (edHoldLast.Height - lblHoldLast.Height) div 2;
  edHoldLast.Left := ColCtrl;
  edHoldLast.Top := RowTop;
  RowTop := StackBelow(edHoldLast, RowGap * 2);

  // Rozdzielczość docelowa.
  lblRes.Left := ColLeft;
  lblRes.Top := RowTop + (cmbRes.Height - lblRes.Height) div 2;
  cmbRes.Left := ColCtrl;
  cmbRes.Top := RowTop;
  RowTop := StackBelow(cmbRes, SectionGap);

  // Tryb.
  RadioW := 0;
  A[5] := T('Save to file');
  A[6] := T('Show as presentation');
  for I := 5 to 6 do
  begin
    W := Self.Canvas.TextWidth(A[I]) + 30;
    if W > RadioW then RadioW := W;
  end;
  rbSave.Width := RadioW;
  rbPresent.Width := RadioW;
  rbSave.Left := 0;
  rbSave.Top := 0;
  rbPresent.Left := 0;
  rbPresent.Top := rbSave.Height + 4;
  pnlMode.Left := ColLeft;
  pnlMode.Top := RowTop;
  pnlMode.Width := RadioW;
  pnlMode.Height := rbPresent.Top + rbPresent.Height;
  RowTop := StackBelow(pnlMode, SectionGap);

  // Widok prezentacji — tylko gdy aktywna prezentacja.
  if pnlView.Visible then
  begin
    Self.Canvas.Font.Assign(rbWindow.Font);
    RadioW := 0;
    A[5] := T('In window');
    A[6] := T('Full screen');
    for I := 5 to 6 do
    begin
      W := Self.Canvas.TextWidth(A[I]) + 30;
      if W > RadioW then RadioW := W;
    end;
    rbWindow.Width := RadioW;
    rbFullscreen.Width := RadioW;
    rbWindow.Left := 0;
    rbWindow.Top := 0;
    rbFullscreen.Left := 0;
    rbFullscreen.Top := rbWindow.Height + 4;
    pnlView.Left := ColLeft;
    pnlView.Top := RowTop;
    pnlView.Width := RadioW;
    pnlView.Height := rbFullscreen.Top + rbFullscreen.Height;
    RowTop := StackBelow(pnlView, SectionGap);
  end;

  // Przyciski dolne: Start po lewej, Zamknij po prawej.
  Self.Canvas.Font.Assign(btnStart.Font);
  W := Self.Canvas.TextWidth(T('Start')) + 24;
  btnStart.Width := W;
  W := Self.Canvas.TextWidth(T('Close')) + 24;
  btnClose.Width := W;
  btnStart.Left := ColLeft;
  btnClose.Left := ColCtrl + ColW - btnClose.Width;
  btnStart.Top := RowTop + SectionGap;
  btnClose.Top := btnStart.Top;

  FitToContent(CtrlGap * 3, CtrlGap * 3);
end;

function MakeFrame(ABmp: TBitmap; TW, TH: Integer): TBitmap;
var
  NW, NH, X, Y: Integer;
  Scale: Double;
begin
  Scale := Min(TW / ABmp.Width, TH / ABmp.Height);
  NW := Max(1, Trunc(ABmp.Width * Scale));
  NH := Max(1, Trunc(ABmp.Height * Scale));
  X := (TW - NW) div 2;
  Y := (TH - NH) div 2;
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.Width := TW;
  Result.Height := TH;
  Result.Canvas.Brush.Color := clBlack;
  Result.Canvas.FillRect(Rect(0, 0, TW, TH));
  SetStretchBltMode(Result.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(Result.Canvas.Handle, 0, 0, nil);
  Result.Canvas.StretchDraw(Rect(X, Y, X + NW, Y + NH), ABmp);
end;

procedure RunTimelapse(const Opts: TTimelapseOptions);
var
  Files: TArray<TTimelapseFile>;
  Paths: TArray<string>;
  i, r, OkCount, ErrCount, TW, TH, Reps: Integer;
  DstPath, Msg: string;
  Bmp, Frame: TBitmap;
  Prog: TProgressForm;
  Aborted: Boolean;
  Player: TTimelapsePlayer;
  Writer: TVideoWriter;
  FPS: Double;
begin
  Files := BuildFileList(Opts.SrcDir, Opts.Sort = tlsDate);
  if Length(Files) = 0 then
  begin
    MessageDlg(T('No images in the source folder.'), mtInformation, [mbOK], 0);
    Exit;
  end;
  FPS := Opts.FPS;
  if FPS <= 0 then FPS := 25;

  if Opts.Mode = tlmPresent then
  begin
    SetLength(Paths, Length(Files));
    for i := 0 to High(Files) do
      Paths[i] := Files[i].Path;
    Player := TTimelapsePlayer.CreateNew(Application);
    try
      Player.Init(Paths, FPS, Opts.HoldFirstSec, Opts.HoldLastSec,
        Opts.View = tlvFullscreen);
      Player.ShowModal;
    finally
      Player.Free;
    end;
    Exit;
  end;

  // Eksport: wideo MP4 (H.264) w katalogu wynikowym.
  case Opts.ResIndex of
    1: begin TW := 3840; TH := 2160; end;
    2: begin TW := 1920; TH := 1080; end;
    3: begin TW := 1280; TH := 720; end;
  else
    begin TW := 0; TH := 0; end;
  end;
  if (TW mod 2) <> 0 then Dec(TW);
  if (TH mod 2) <> 0 then Dec(TH);
  if TW < 2 then TW := 0;
  if TH < 2 then TH := 0;

  OkCount := 0;
  ErrCount := 0;

  DstPath := IncludeTrailingPathDelimiter(Opts.DstDir) + Opts.FileName;
  if FileExists(DstPath) then DeleteFile(DstPath);

  Prog := TProgressForm.Create(nil);
  try
    Prog.Lbl.Caption := T('Processing...') + ' ' + IntToStr(0) + '/' + IntToStr(Length(Files));
    Prog.Show;
    Application.ProcessMessages;

    // Oryginalna rozdzielczość = wymiary pierwszego zdjęcia (parzyste).
    if TW = 0 then
    begin
      Bmp := nil;
      try
        Bmp := LoadImageFile(Files[0].Path);
        TW := Bmp.Width;
        TH := Bmp.Height;
      except
      end;
      Bmp.Free;
      if (TW mod 2) <> 0 then Dec(TW);
      if (TH mod 2) <> 0 then Dec(TH);
    end;

    Writer := TVideoWriter.Create(DstPath, TW, TH, FPS);
    try
      for i := 0 to High(Files) do
      begin
        if Prog.Abort then Break;

        Prog.SetFile(Files[i].Name, i + 1, Length(Files));
        Application.ProcessMessages;
        if Prog.Abort then Break;

        try
          Bmp := LoadImageFile(Files[i].Path);
          try
            if (i = 0) and (i = High(Files)) then
              Reps := Max(Round(Opts.HoldFirstSec * FPS), Round(Opts.HoldLastSec * FPS))
            else if i = 0 then
              Reps := Round(Opts.HoldFirstSec * FPS)
            else if i = High(Files) then
              Reps := Round(Opts.HoldLastSec * FPS)
            else
              Reps := 1;
            if Reps < 1 then Reps := 1;

            Frame := MakeFrame(Bmp, TW, TH);
            try
              for r := 1 to Reps do
                Writer.AddFrame(Frame);
            finally
              Frame.Free;
            end;
            Inc(OkCount);
          finally
            Bmp.Free;
          end;
        except
          Inc(ErrCount);
        end;
      end;
      Writer.Finalize;
    finally
      Writer.Free;
    end;

    Prog.Close;
  finally
    Aborted := Prog.Abort;
    Prog.Free;
  end;

  if Aborted then
    DeleteFile(DstPath);

  Msg := T('Processed') + ': ' + IntToStr(OkCount) + '/' + IntToStr(Length(Files));
  if ErrCount > 0 then
    Msg := Msg + sLineBreak + T('errors') + ': ' + IntToStr(ErrCount);
  if Aborted then
    Msg := T('Cancel') + sLineBreak + Msg
  else
    Msg := Msg + sLineBreak + DstPath;
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

end.