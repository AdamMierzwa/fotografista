unit uTitleBar;

interface

uses
  System.Types, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.TitleBarCtrls;

type
  TFotoForm = class(TForm)
  strict private
    FTitleBarApplied: Boolean;
    FContentHost: TPanel;
    FTitleBarPanel: TTitleBarPanel;
    FBarHeight: Integer;
    procedure TitleBarPanelPaint(Sender: TObject; Canvas: TCanvas; var ARect: TRect);
  protected
    function UseCustomTitleBar: Boolean; virtual;
    procedure DoShow; override;
    procedure LayoutDialogContent;
  public
    procedure AfterConstruction; override;
    function ContentParent: TWinControl;
    function TitleBarGap: Integer;
    function CtrlGap: Integer;
    function RowGap: Integer;
    function SectionGap: Integer;
    procedure FitToContent(AMarginBottom: Integer = 8; AMarginRight: Integer = 8);
    procedure ReflowTrackBarRows; overload;
    procedure ReflowTrackBarRows(Host: TWinControl); overload;
    procedure CenterHorizontally(C: TControl);
    procedure AlignRightEdge(C: TControl; Margin: Integer = 0);
    procedure AlignButtonsRight(const Buttons: array of TButton; RightMargin: Integer = 0);
    function StackBelow(TopOf: Integer; Gap: Integer): Integer; overload;
    function StackBelow(C: TControl; Gap: Integer): Integer; overload;
    procedure FitHeight(MarginBottom: Integer = 0);
  end;

procedure PaintTitleBarCaption(Canvas: TCanvas; const ARect: TRect; AForm: TCustomForm);

implementation

uses
  System.SysUtils, System.Math, Winapi.Windows, Vcl.Themes, Vcl.ComCtrls;

const
  cTextOffset = 6;
  cTitleBarHeight = 32;


function TFotoForm.UseCustomTitleBar: Boolean;
begin
  Result := False;
end;

function TFotoForm.ContentParent: TWinControl;
begin
  if FTitleBarApplied then
    Result := FContentHost
  else
    Result := Self;
end;

function TFotoForm.TitleBarGap: Integer;
begin
  if FTitleBarApplied then
    Result := 36
  else
    Result := 0;
end;

function TFotoForm.CtrlGap: Integer;
begin
  Result := 4;
end;

function TFotoForm.RowGap: Integer;
begin
  Result := Self.Canvas.TextHeight('Wg') div 3;
end;

function TFotoForm.SectionGap: Integer;
begin
  Result := Self.Canvas.TextHeight('Wg');
end;

procedure TFotoForm.FitToContent(AMarginBottom: Integer = 8; AMarginRight: Integer = 8);
var
  I: Integer;
  C: TControl;
  MaxBottom, MaxRight: Integer;
begin
  MaxBottom := 0;
  MaxRight := 0;

  for I := 0 to Self.ControlCount - 1 do
  begin
    C := Self.Controls[I];
    if (C = FTitleBarPanel) or (C = FContentHost) then
      Continue;
    if not C.Visible then
      Continue;
    if C is TListBox then
      TListBox(C).ItemHeight := TListBox(C).Canvas.TextHeight('Wg') + 2;
    if C.Top + C.Height > MaxBottom then
      MaxBottom := C.Top + C.Height;
    if C.Left + C.Width > MaxRight then
      MaxRight := C.Left + C.Width;
  end;

  ClientHeight := MaxBottom + AMarginBottom + TitleBarGap;
  ClientWidth := MaxRight + AMarginRight;
end;

procedure TFotoForm.CenterHorizontally(C: TControl);
begin
  C.Left := (ClientWidth - C.Width) div 2;
end;

procedure TFotoForm.AlignRightEdge(C: TControl; Margin: Integer);
begin
  C.Left := ClientWidth - Margin - C.Width;
end;

procedure TFotoForm.AlignButtonsRight(const Buttons: array of TButton; RightMargin: Integer);
var
  I: Integer;
  X: Integer;
begin
  if Length(Buttons) = 0 then Exit;
  X := ClientWidth - RightMargin;
  for I := High(Buttons) downto Low(Buttons) do
  begin
    Dec(X, Buttons[I].Width);
    Buttons[I].Left := X;
    Dec(X, CtrlGap * 2);
  end;
end;

function TFotoForm.StackBelow(TopOf: Integer; Gap: Integer): Integer;
begin
  Result := TopOf + Gap;
end;

function TFotoForm.StackBelow(C: TControl; Gap: Integer): Integer;
begin
  Result := C.Top + C.Height + Gap;
end;

procedure TFotoForm.FitHeight(MarginBottom: Integer);
var
  Host: TWinControl;
  I: Integer;
  C: TControl;
  MaxBottom: Integer;
begin
  Host := ContentParent;
  MaxBottom := 0;
  for I := 0 to Host.ControlCount - 1 do
  begin
    C := Host.Controls[I];
    if not C.Visible then Continue;
    if C.Top + C.Height > MaxBottom then
      MaxBottom := C.Top + C.Height;
  end;
  ClientHeight := MaxBottom + MarginBottom + TitleBarGap;
end;

procedure TFotoForm.AfterConstruction;
var
  Panel: TTitleBarPanel;
  CanApply: Boolean;
  I: Integer;
begin
  inherited AfterConstruction;
  CanApply := (not (csDesigning in ComponentState)) and (not FTitleBarApplied)
    and UseCustomTitleBar and CustomTitleBar.Supported
    and (FormStyle <> fsMDIChild) and (Parent = nil);
  if CanApply then
  begin
    FTitleBarApplied := True;

    FBarHeight := Max(cTitleBarHeight, Abs(Self.Font.Height) + 20);

    Panel := TTitleBarPanel.Create(Self);
    Panel.Parent := Self;
    Panel.Left := 0;
    Panel.Top := 0;
    Panel.Align := alTop;
    Panel.Height := FBarHeight;
    Panel.OnPaint := TitleBarPanelPaint;
    FTitleBarPanel := Panel;

    FContentHost := TPanel.Create(Self);
    FContentHost.Parent := Self;
    FContentHost.Align := alClient;
    FContentHost.BevelOuter := bvNone;
    FContentHost.BorderStyle := bsNone;
    FContentHost.ParentBackground := True;

    I := 0;
    while I < ControlCount do
      if (Controls[I] = Panel) or (Controls[I] = FContentHost) then
        Inc(I)
      else
        Controls[I].Parent := FContentHost;

    CustomTitleBar.Enabled := True;
    if CustomTitleBar.Enabled then
    begin
      CustomTitleBar.Control := Panel;
      CustomTitleBar.ShowCaption := False;
      CustomTitleBar.ShowIcon := False;
      CustomTitleBar.SystemColors := False;
      CustomTitleBar.StyleColors := True;
      CustomTitleBar.SystemButtons := False;
      CustomTitleBar.SystemHeight := False;
      CustomTitleBar.Height := FBarHeight;
    end;
  end;

  if not (csDesigning in ComponentState) then
    ReflowTrackBarRows;
end;

procedure TFotoForm.TitleBarPanelPaint(Sender: TObject; Canvas: TCanvas; var ARect: TRect);
begin
  PaintTitleBarCaption(Canvas, ARect, Self);
end;

procedure TFotoForm.DoShow;
var
  I: Integer;
begin
  if FTitleBarApplied and (FContentHost <> nil) then
  begin
    I := 0;
    while I < ControlCount do
      if (Controls[I] = FTitleBarPanel) or (Controls[I] = FContentHost) then
        Inc(I)
      else
        Controls[I].Parent := FContentHost;

    FBarHeight := Max(cTitleBarHeight, Abs(Self.Font.Height) + 20);
    if FTitleBarPanel <> nil then
      FTitleBarPanel.Height := FBarHeight;
    CustomTitleBar.Height := FBarHeight;
  end;
  inherited DoShow;
end;

procedure TFotoForm.LayoutDialogContent;
var
  Host: TWinControl;
  I, J, BtnY, BtnCount: Integer;
  C: TControl;
  Sorted: TList;
  Buttons: array of TButton;
begin
  Host := ContentParent;
  if (Host = nil) or (Host.ControlCount = 0) then Exit;

  Sorted := TList.Create;
  try
    for I := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[I];
      if C.Visible then
        Sorted.Add(C);
    end;

    for I := 0 to Sorted.Count - 2 do
      for J := I + 1 to Sorted.Count - 1 do
        if TControl(Sorted[J]).Top < TControl(Sorted[I]).Top then
          Sorted.Exchange(I, J);

    for I := 0 to Sorted.Count - 1 do
    begin
      C := TControl(Sorted[I]);
      if (C is TImage) or (C is TPaintBox) then
      begin
        CenterHorizontally(C);
        Break;
      end;
    end;

    for I := 0 to Sorted.Count - 2 do
    begin
      C := TControl(Sorted[I]);
      var NextC := TControl(Sorted[I + 1]);
      if (NextC.Top > C.Top) and (NextC.Top < C.Top + C.Height + RowGap) then
        NextC.Top := C.Top + C.Height + RowGap;
    end;

    BtnY := -1;
    for I := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[I];
      if (C is TButton) and C.Visible then
      begin
        if BtnY < 0 then
          BtnY := C.Top
        else if C.Top > BtnY then
          BtnY := C.Top;
      end;
    end;

    if BtnY >= 0 then
    begin
      BtnCount := 0;
      for I := 0 to Host.ControlCount - 1 do
      begin
        C := Host.Controls[I];
        if (C is TButton) and C.Visible and (C.Top = BtnY) then
          Inc(BtnCount);
      end;
      if BtnCount > 1 then
      begin
        SetLength(Buttons, BtnCount);
        BtnCount := 0;
        for I := 0 to Host.ControlCount - 1 do
        begin
          C := Host.Controls[I];
          if (C is TButton) and C.Visible and (C.Top = BtnY) then
          begin
            Buttons[BtnCount] := TButton(C);
            Inc(BtnCount);
          end;
        end;
        if Buttons[0].Left > Host.Width div 2 then
          AlignButtonsRight(Buttons, CtrlGap * 3);
      end;
    end;

    FitHeight(CtrlGap * 3);
  finally
    Sorted.Free;
  end;
end;

procedure TFotoForm.ReflowTrackBarRows;
begin
  ReflowTrackBarRows(ContentParent);
end;

procedure TFotoForm.ReflowTrackBarRows(Host: TWinControl);
var
  Gap, N, I, J, K: Integer;
  C: TControl;
  TBArr: array of TTrackBar;
  LblArr: array of TLabel;
  RdArr: array of TLabel;
  OrigTopArr: array of Integer;
  SwapTB: TTrackBar;
  Lbl: TLabel;
  Rd: TLabel;
  CumShift, RowBottom, NextOrigTop, LastLabelOrigTop: Integer;
  BtnY, BtnCount: Integer;
  Buttons: array of TButton;
begin
  if (Host = nil) or (Host.ControlCount = 0) then Exit;
  RowBottom := 0;

  Gap := RowGap;

  N := 0;
  for I := 0 to Host.ControlCount - 1 do
    if Host.Controls[I] is TTrackBar then
      Inc(N);
  if N = 0 then Exit;

  SetLength(TBArr, N);
  SetLength(LblArr, N);
  SetLength(RdArr, N);
  SetLength(OrigTopArr, N);

  J := 0;
  for I := 0 to Host.ControlCount - 1 do
    if Host.Controls[I] is TTrackBar then
    begin
      TBArr[J] := TTrackBar(Host.Controls[I]);
      Inc(J);
    end;

  for I := 0 to N - 2 do
    for J := I + 1 to N - 1 do
      if TBArr[J].Top < TBArr[I].Top then
      begin
        SwapTB := TBArr[I]; TBArr[I] := TBArr[J]; TBArr[J] := SwapTB;
      end;

  for I := 0 to N - 1 do
  begin
    LblArr[I] := nil;
    for J := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[J];
      if not (C is TLabel) then Continue;
      if not TLabel(C).AutoSize then Continue;
      if C.Top > TBArr[I].Top + TBArr[I].Height then Continue;
      if (LblArr[I] = nil) or (C.Top > LblArr[I].Top) then
        LblArr[I] := TLabel(C);
    end;

    if LblArr[I] <> nil then
      OrigTopArr[I] := LblArr[I].Top
    else
      OrigTopArr[I] := TBArr[I].Top;

    RdArr[I] := nil;
    for J := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[J];
      if not (C is TLabel) then Continue;
      if TLabel(C).AutoSize then Continue;
      if C.Top < OrigTopArr[I] then Continue;
      K := 0;
      while K < I do
      begin
        if RdArr[K] = TLabel(C) then Break;
        Inc(K);
      end;
      if K < I then Continue;
      if (RdArr[I] = nil) or (C.Top < RdArr[I].Top) then
        RdArr[I] := TLabel(C);
    end;
  end;

  CumShift := 0;
  LastLabelOrigTop := OrigTopArr[N - 1];

  for I := 0 to N - 1 do
  begin
    Lbl := LblArr[I];
    Rd := RdArr[I];

    if Lbl <> nil then
    begin
      Lbl.Top := OrigTopArr[I] + CumShift;
      TBArr[I].Top := Lbl.Top + Lbl.Height + Gap + (Gap div 2);
    end
    else
      TBArr[I].Top := TBArr[I].Top + CumShift;

    if Rd <> nil then
    begin
      Rd.Top := TBArr[I].Top + TBArr[I].Height + Gap;
      Rd.Left := TBArr[I].Left + (TBArr[I].Width - Rd.Width) div 2;
    end;

    if Rd <> nil then
      RowBottom := Rd.Top + Rd.Height
    else
      RowBottom := TBArr[I].Top + TBArr[I].Height;

    if I < N - 1 then
    begin
      NextOrigTop := OrigTopArr[I + 1];
      CumShift := Max(0, RowBottom + Gap - NextOrigTop);
    end;
  end;

  NextOrigTop := MaxInt;
  for J := 0 to Host.ControlCount - 1 do
  begin
    C := Host.Controls[J];
    K := 0;
    while K < N do
    begin
      if (C = LblArr[K]) or (C = TBArr[K]) or (C = RdArr[K]) then Break;
      Inc(K);
    end;
    if K < N then Continue;
    if C.Top > LastLabelOrigTop then
      if C.Top < NextOrigTop then
        NextOrigTop := C.Top;
  end;
  if NextOrigTop < MaxInt then
    CumShift := Max(0, RowBottom + Gap - NextOrigTop);

  if CumShift > 0 then
    for J := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[J];
      K := 0;
      while K < N do
      begin
        if (C = LblArr[K]) or (C = TBArr[K]) or (C = RdArr[K]) then Break;
        Inc(K);
      end;
      if K < N then Continue;
      if C.Top > LastLabelOrigTop then
        C.Top := C.Top + CumShift;
    end;

  for I := 0 to Host.ControlCount - 1 do
  begin
    C := Host.Controls[I];
    if (C is TPaintBox) or (C is TImage) then
    begin
      CenterHorizontally(C);
      Break;
    end;
  end;

  BtnY := -1;
  for I := 0 to Host.ControlCount - 1 do
  begin
    C := Host.Controls[I];
    if (C is TButton) and C.Visible then
    begin
      if BtnY < 0 then
        BtnY := C.Top
      else if C.Top > BtnY then
        BtnY := C.Top;
    end;
  end;

  if BtnY >= 0 then
  begin
    BtnCount := 0;
    for I := 0 to Host.ControlCount - 1 do
    begin
      C := Host.Controls[I];
      if (C is TButton) and C.Visible and (Abs(C.Top - BtnY) <= 2) then
        Inc(BtnCount);
    end;
    if BtnCount > 1 then
    begin
      SetLength(Buttons, BtnCount);
      BtnCount := 0;
      for I := 0 to Host.ControlCount - 1 do
      begin
        C := Host.Controls[I];
        if (C is TButton) and C.Visible and (Abs(C.Top - BtnY) <= 2) then
        begin
          Buttons[BtnCount] := TButton(C);
          Inc(BtnCount);
        end;
      end;
      if Buttons[0].Left > Host.Width div 2 then
        AlignButtonsRight(Buttons, CtrlGap * 3);
    end;
  end;

  FitHeight(CtrlGap * 3);
end;

procedure PaintTitleBarCaption(Canvas: TCanvas; const ARect: TRect; AForm: TCustomForm);
const
  cDrawFlags = DT_LEFT or DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
var
  LTextRect: TRect;
begin
  if (AForm = nil) or (AForm.Caption = '') or (Canvas = nil) then
    Exit;

  Canvas.Font := AForm.Font;

  if AForm.Active then
    Canvas.Font.Color := StyleServices(AForm).GetSystemColor(clCaptionText)
  else
    Canvas.Font.Color := StyleServices(AForm).GetSystemColor(clInActiveCaptionText);

  Canvas.Brush.Style := bsClear;

  LTextRect := ARect;
  Inc(LTextRect.Left, cTextOffset);
  Dec(LTextRect.Right, cTextOffset);

  DrawText(Canvas.Handle, PChar(AForm.Caption), Length(AForm.Caption), LTextRect, cDrawFlags);
end;

end.
