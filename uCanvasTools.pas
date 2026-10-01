unit uCanvasTools;

interface

uses
  System.Classes, System.SysUtils,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  // Wspólny kontrakt narzędzi rysunkowych działających na canvase.
  // Współrzędne X, Y to lokalne współrzędne PaintBox (w skali zoomu);
  // narzędzie samo konwertuje je na współrzędne obrazu (X / FZoomFactor),
  // zachowując dokładność float dla logiki selekcji.
  ICanvasTool = interface
    ['{AC8F5C7E-2C1A-4D5B-9F3A-6B7C8D9E0F11}']
    procedure Activate;
    procedure Deactivate;
    procedure MouseDown(Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    procedure MouseUp(Shift: TShiftState; X, Y: Integer);
    // Panel opcji narzędzia (np. przełącznik trybu + suwak pędzla) dla
    // hosta okna narzędziowego. Nil = narzędzie nie ma opcji.
    function GetOptionsPanel: TWinControl;
  end;

  TBrushSizeChangeEvent = procedure(Sender: TObject; AValue: Integer) of object;

  // Współdzielony suwak pędzla (1-100) z readoutem wartości.
  // Zbudowany w kodzie (bez własnego .dfm) — TrackBar + etykieta wartości.
  TBrushSizeSlider = class(TCustomControl)
  private
    FTrackBar: TTrackBar;
    FLblValue: TLabel;
    FOnChange: TBrushSizeChangeEvent;
    procedure TrackBarChange(Sender: TObject);
    procedure UpdateValueLabel;
    function GetValue: Integer;
    procedure SetValue(AValue: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    property Value: Integer read GetValue write SetValue;
    property OnChange: TBrushSizeChangeEvent read FOnChange write FOnChange;
  end;

implementation

{ TBrushSizeSlider }

constructor TBrushSizeSlider.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 33;

  FTrackBar := TTrackBar.Create(Self);
  FTrackBar.Parent := Self;
  FTrackBar.Left := 0;
  FTrackBar.Top := 0;
  FTrackBar.Width := 162;
  FTrackBar.Height := 33;
  FTrackBar.Min := 1;
  FTrackBar.Max := 100;
  FTrackBar.Position := 10;
  FTrackBar.Frequency := 10;
  FTrackBar.TickStyle := tsAuto;
  FTrackBar.ShowSelRange := False;
  FTrackBar.OnChange := TrackBarChange;

  FLblValue := TLabel.Create(Self);
  FLblValue.Parent := Self;
  FLblValue.Left := 166;
  FLblValue.Top := 8;
  FLblValue.Width := 30;
  FLblValue.Height := 18;
  FLblValue.AutoSize := False;
  FLblValue.Alignment := taLeftJustify;
  FLblValue.Caption := '10';
  FLblValue.StyleElements := [seClient, seBorder];
end;

procedure TBrushSizeSlider.TrackBarChange(Sender: TObject);
begin
  UpdateValueLabel;
  if Assigned(FOnChange) then
    FOnChange(Self, FTrackBar.Position);
end;

procedure TBrushSizeSlider.UpdateValueLabel;
begin
  if FLblValue <> nil then
    FLblValue.Caption := IntToStr(FTrackBar.Position);
end;

function TBrushSizeSlider.GetValue: Integer;
begin
  Result := FTrackBar.Position;
end;

procedure TBrushSizeSlider.SetValue(AValue: Integer);
begin
  if AValue < FTrackBar.Min then AValue := FTrackBar.Min;
  if AValue > FTrackBar.Max then AValue := FTrackBar.Max;
  FTrackBar.Position := AValue;
  UpdateValueLabel;
end;

end.