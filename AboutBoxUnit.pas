unit AboutBoxUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  uI18n, uTitleBar;

type
  TfrmAbout = class(TFotoForm)
    procedure FormCreate(Sender: TObject);
  private
    imgRetro: TImage;
    lblTitle: TLabel;
    lblVersion: TLabel;
    lblSubtitle: TLabel;
    lblTech1: TLabel;
    lblTech2: TLabel;
    lblTech3: TLabel;
    lblDesc: TLabel;
    Bevel1: TBevel;
    btnOK: TButton;
    lblCopyright: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure LayoutAbout;
  protected
    procedure DoShow; override;
  public
    procedure RefitButtons; override;
  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.dfm}
{$R about_logo.res}

const
  // Realna wersja aplikacji pokazywana w oknie About.
  // Podbijać TYLKO przy realnej, funkcjonalnej zmianie (nowa funkcja / poprawka).
  // Niezależna od numeru paczki MSIX (licznik Store) - ten podbija się przy każdej
  // submisji, nawet przy odbiciu, i nie ma wpływu na tę stałą.
  RealAppVersion = '1.3.0';

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  // Konfiguracja okna (rozmiar liczy LayoutAbout z zawartosci)
  Caption := T('About Fotografista');
  Position := poMainFormCenter;
  BorderIcons := [biSystemMenu];
  BorderStyle := bsSingle;  // było: bsDialog — TEST

  // Lewy panel graficzny (miejsce na grafikę retro)
  imgRetro := TImage.Create(Self);
  imgRetro.Parent := Self;
  imgRetro.Left := 12;
  imgRetro.Top := 12;
  imgRetro.Width := 150;
  imgRetro.Height := 220;
  imgRetro.Proportional := True;
  imgRetro.Center := True;

  try
    imgRetro.Picture.Bitmap.LoadFromResourceName(HInstance, 'ABOUT_LOGO');
  except
    if FileExists(ExtractFilePath(ParamStr(0)) + 'about_logo.bmp') then
      imgRetro.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'about_logo.bmp');
  end;

  // Nagłówek programu
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := Self;
  lblTitle.Left := 180;
  lblTitle.Top := 12;
  lblTitle.Caption := 'Fotografista';
  lblTitle.AutoSize := True;
  lblTitle.Font.Size := 18;
  lblTitle.Font.Style := [fsBold];

  // Numer wersji – obok nazwy, bez wytłuszczenia
  lblVersion := TLabel.Create(Self);
  lblVersion.Parent := Self;
  lblVersion.Left := lblTitle.Left + lblTitle.Width + 6;
  lblVersion.Top := lblTitle.Top;
  lblVersion.Caption := RealAppVersion;
  lblVersion.AutoSize := True;
  lblVersion.Font.Size := 18;
  lblVersion.Font.Style := [];

  // Podtytuł – ustawiamy dynamicznie
  lblSubtitle := TLabel.Create(Self);
  lblSubtitle.Parent := Self;
  lblSubtitle.Left := 180;
  lblSubtitle.Top := lblTitle.Top + lblTitle.Height + 4;  // <<< klucz
  lblSubtitle.Caption := T('Professional graphics editor');
  lblSubtitle.Font.Color := clNavy;

  // Specyfikacja techniczna
  lblTech1 := TLabel.Create(Self);
  lblTech1.Parent := Self;
  lblTech1.Left := 180;
  lblTech1.Top := lblSubtitle.Top + lblSubtitle.Height + RowGap;
  lblTech1.Caption := '• ' + T('Architecture: 100% native (VCL / Object Pascal)');

  lblTech2 := TLabel.Create(Self);
  lblTech2.Parent := Self;
  lblTech2.Left := 180;
  lblTech2.Top := lblTech1.Top + lblTech1.Height + RowGap;
  lblTech2.Caption := '• ' + T('Performance: direct access to the rendering pipeline');

  lblTech3 := TLabel.Create(Self);
  lblTech3.Parent := Self;
  lblTech3.Left := 180;
  lblTech3.Top := lblTech2.Top + lblTech2.Height + RowGap;
  lblTech3.Caption := '• ' + T('Environment: independent of x86/x64 runtime');

  lblDesc := TLabel.Create(Self);
  lblDesc.Parent := Self;
  lblDesc.Left := 180;
  lblDesc.Top := lblTech3.Top + lblTech3.Height + SectionGap;
  lblDesc.Caption := T('High-performance desktop application') + sLineBreak + T('without the overhead of web frameworks.');

  // Pozioma linia oddzielająca
  Bevel1 := TBevel.Create(Self);
  Bevel1.Parent := Self;
  Bevel1.Left := 14;
  Bevel1.Top := lblDesc.Top + lblDesc.Height + SectionGap;
  Bevel1.Height := 2;

  // Przycisk OK
  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Left := 423;
  btnOK.Top := Bevel1.Top + Bevel1.Height + RowGap;
  btnOK.Width := 85;
  btnOK.Height := 25;
  btnOK.Caption := T('OK');
  btnOK.OnClick := btnOKClick;
  btnOK.Default := True;
  btnOK.Cancel := True;

  // Dolny tekst informacyjny (zastąpienie Memo czystym Labelem bez pasków przewijania)
  lblCopyright := TLabel.Create(Self);
  lblCopyright.Parent := Self;
  lblCopyright.Left := 26;
  lblCopyright.Top := Bevel1.Top + Bevel1.Height + RowGap;
  lblCopyright.Width := 390;
  lblCopyright.WordWrap := True;
  lblCopyright.Caption :=
    'Copyright © 2026 Adam Bogumił Mierzwa. All rights reserved.' + sLineBreak +
    'Protected by ancient Object Pascal spells, VCL framework sorcery,' + sLineBreak +
    'and absolute contempt for resource-hungry web wrappers.';

  lblCopyright.AutoSize := True;
  lblCopyright.WordWrap := False;

  // Pozycje powyzej sa tylko startowe - uklad liczy LayoutAbout (takze po
  // zmianie czcionki, przez RefitButtons).
  LayoutAbout;
end;

// Uklad z zawartosci (2026-10-21; wczesniej kolumna tekstu na stalym Left = 180,
// linia 496 px, prawy margines stale 12 px - dlugi wiersz dotykal krawedzi,
// copyright na Left = 26). Jeden margines z czcionki z obu stron; kolumna
// tekstu zaraz za logo; linia i copyright od lewego marginesu na cala
// szerokosc tresci; OK do prawej.
procedure TfrmAbout.LayoutAbout;
var
  Margin, X, Y, MaxRight: Integer;

  procedure Row(L: TLabel; Gap: Integer);
  begin
    L.Left := X;
    L.Top := Y + Gap;
    Y := L.Top + L.Height;
    MaxRight := Max(MaxRight, L.Left + L.Width);
  end;

begin
  if (imgRetro = nil) or (btnOK = nil) then Exit;
  Margin := SectionGap;
  // pole logo = rozmiar obrazka z zasobow (bez pustego pola wokol, ktore
  // przy wysrodkowaniu dawalo szerszy lewy margines niz prawy)
  if (imgRetro.Picture.Graphic <> nil) and not imgRetro.Picture.Graphic.Empty then
  begin
    imgRetro.Width := imgRetro.Picture.Width;
    imgRetro.Height := imgRetro.Picture.Height;
  end;
  imgRetro.Left := Margin;

  X := imgRetro.Left + imgRetro.Width + SectionGap;
  MaxRight := 0;
  lblTitle.Left := X;
  lblTitle.Top := Margin;
  lblVersion.Left := lblTitle.Left + lblTitle.Width + CtrlGap * 2;
  lblVersion.Top := lblTitle.Top;
  MaxRight := Max(MaxRight, lblVersion.Left + lblVersion.Width);
  Y := lblTitle.Top + lblTitle.Height;
  Row(lblSubtitle, CtrlGap);
  Row(lblTech1, RowGap);
  Row(lblTech2, RowGap);
  Row(lblTech3, RowGap);
  Row(lblDesc, SectionGap);
  // logo wysrodkowane w pionie wzgledem bloku tekstu
  imgRetro.Top := Margin + Max(0, (Y - Margin - imgRetro.Height) div 2);
  Y := Max(Y, imgRetro.Top + imgRetro.Height);

  // linia i copyright od lewego marginesu
  Bevel1.Left := Margin;
  Bevel1.Top := Y + SectionGap;
  lblCopyright.Left := Margin;
  lblCopyright.Top := Bevel1.Top + Bevel1.Height + SectionGap;
  MaxRight := Max(MaxRight, lblCopyright.Left + lblCopyright.Width);

  FitButton(btnOK);
  btnOK.Top := lblCopyright.Top + lblCopyright.Height + SectionGap;
  ClientWidth := Max(MaxRight, Margin + btnOK.Width) + Margin;
  ClientHeight := btnOK.Top + btnOK.Height + Margin + TitleBarGap;
  Bevel1.Width := ClientWidth - Margin * 2;
  btnOK.Left := ClientWidth - Margin - btnOK.Width;
end;

procedure TfrmAbout.RefitButtons;
begin
  inherited;
  LayoutAbout;
end;

procedure TfrmAbout.btnOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmAbout.DoShow;
begin
  inherited;
end;

end.
