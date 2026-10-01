unit uPreviewFit;

interface

uses
  Winapi.Windows, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  uTitleBar;

procedure FitPreviewToDialog(Dlg: TForm; PB: TPaintBox; ImgW, ImgH: Integer); overload;
procedure FitPreviewToDialog(Dlg: TForm; Host: TWinControl; PB: TPaintBox; ImgW, ImgH: Integer); overload;

implementation

procedure FitPreviewToDialog(Dlg: TForm; PB: TPaintBox; ImgW, ImgH: Integer);
var
  ParentCtrl: TWinControl;
begin
  if Dlg is TFotoForm then
  begin
    ParentCtrl := TFotoForm(Dlg).ContentParent;
    if ParentCtrl.ControlCount = 0 then
      ParentCtrl := Dlg;
  end else
    ParentCtrl := Dlg;
  FitPreviewToDialog(Dlg, ParentCtrl, PB, ImgW, ImgH);
end;

procedure FitPreviewToDialog(Dlg: TForm; Host: TWinControl; PB: TPaintBox; ImgW, ImgH: Integer);
var
  Scale: Double;
  PW, PH, Delta, I, MaxBottom, Gap: Integer;
  C: TControl;
begin
  if (ImgW <= 0) or (ImgH <= 0) then Exit;
  if Host = nil then Exit;

  Dlg.DoubleBuffered := True;

  if Dlg is TFotoForm then
    Gap := TFotoForm(Dlg).TitleBarGap
  else
    Gap := 0;

  Scale := Min(400.0 / ImgW, 400.0 / ImgH);
  if Scale > 1.0 then Scale := 1.0;
  PW := Max(1, Round(ImgW * Scale));
  PH := Max(1, Round(ImgH * Scale));

  Delta := PH - PB.Height;
  PB.Width := PW;
  PB.Height := PH;

  if PW < Host.Width - 30 then
    PB.Left := (Host.Width - PW) div 2
  else
    PB.Left := 15;

  MaxBottom := PB.Top + PH;

  for I := 0 to Host.ControlCount - 1 do
  begin
    C := Host.Controls[I];
    if C = PB then Continue;
    if C.Top > PB.Top + (PB.Height - Delta) then
      C.Top := C.Top + Delta;
    if C.Top + C.Height > MaxBottom then
      MaxBottom := C.Top + C.Height;
  end;

  Dlg.ClientHeight := MaxBottom + 10 + Gap;
end;

end.
