unit uUndo;

interface

uses
  Vcl.Graphics;

const
  MAX_UNDO = 20;

procedure UndoInit;
// AName = '' : stan WSTEPNY (efekt z oknem) - zostaje na stosie dopiero po
// UndoCommit (FinishEffect); niezatwierdzony (Anuluj) znika przy nastepnym
// zapisie, Cofnij lub Ponow. AName <> '' : stan od razu zatwierdzony.
procedure UndoPush(ABmp: TBitmap; const AName: string = '');
procedure UndoPushMasked(ABmp, AMask: TBitmap; AProt: TBitmap = nil;
  const AName: string = '');
procedure UndoCommit(const AName: string);
function Undo(ABmp: TBitmap; AMask: TBitmap = nil; AProt: TBitmap = nil): Boolean;
function Redo(ABmp: TBitmap; AMask: TBitmap = nil; AProt: TBitmap = nil): Boolean;
function UndoRestoreOriginal(ABmp: TBitmap): Boolean;
function UndoCanUndo: Boolean;
function UndoCanRedo: Boolean;
// Nazwa operacji, ktora cofnie Cofnij / przywroci Ponow ('' gdy brak).
function UndoTopName: string;
function RedoTopName: string;
procedure UndoClear;

implementation

var
  UndoStack: array of TBitmap;
  RedoStack: array of TBitmap;
  UndoMaskStack: array of TBitmap;
  RedoMaskStack: array of TBitmap;
  UndoProtStack: array of TBitmap;
  RedoProtStack: array of TBitmap;
  // Nazwy operacji rownolegle do stosow (jak g_undo_names / g_redo_names
  // w Hollywood, image_undo.hws).
  UndoNames: TArray<string>;
  RedoNames: TArray<string>;
  // Wierzch UndoStack to stan wstepny (UndoPush bez nazwy, przed oknem
  // efektu), jeszcze nie zatwierdzony przez UndoCommit.
  UndoPending: Boolean;

procedure UndoClearRedo; forward;

procedure UndoInit;
begin
  UndoClear;
end;

// Usuwa niezatwierdzony stan wstepny (okno efektu anulowane).
procedure UndoDiscardPending;
begin
  if not UndoPending then Exit;
  UndoPending := False;
  if Length(UndoStack) = 0 then Exit;
  UndoStack[High(UndoStack)].Free;
  UndoMaskStack[High(UndoMaskStack)].Free;
  UndoProtStack[High(UndoProtStack)].Free;
  SetLength(UndoStack, Length(UndoStack) - 1);
  SetLength(UndoMaskStack, Length(UndoMaskStack) - 1);
  SetLength(UndoProtStack, Length(UndoProtStack) - 1);
  SetLength(UndoNames, Length(UndoNames) - 1);
end;

// Limit MAX_UNDO pilnowany przy zatwierdzeniu - anulowany stan wstepny
// nie wypycha najstarszego.
procedure UndoTrim;
begin
  while Length(UndoStack) > MAX_UNDO do
  begin
    UndoStack[0].Free;
    UndoMaskStack[0].Free;
    UndoProtStack[0].Free;
    Delete(UndoStack, 0, 1);
    Delete(UndoMaskStack, 0, 1);
    Delete(UndoProtStack, 0, 1);
    Delete(UndoNames, 0, 1);
  end;
end;

procedure UndoCommit(const AName: string);
begin
  if not UndoPending then Exit;
  UndoPending := False;
  UndoNames[High(UndoNames)] := AName;
  // Clear redo on new action
  UndoClearRedo;
  UndoTrim;
end;

procedure UndoPushFinish(const AName: string);
begin
  SetLength(UndoNames, Length(UndoNames) + 1);
  UndoNames[High(UndoNames)] := '';
  UndoPending := True;
  if AName <> '' then
    UndoCommit(AName);
end;

procedure UndoPush(ABmp: TBitmap; const AName: string);
var
  Bmp: TBitmap;
begin
  UndoDiscardPending;
  Bmp := TBitmap.Create;
  Bmp.Assign(ABmp);
  SetLength(UndoStack, Length(UndoStack) + 1);
  UndoStack[High(UndoStack)] := Bmp;
  SetLength(UndoMaskStack, Length(UndoMaskStack) + 1);
  UndoMaskStack[High(UndoMaskStack)] := nil;
  SetLength(UndoProtStack, Length(UndoProtStack) + 1);
  UndoProtStack[High(UndoProtStack)] := nil;
  UndoPushFinish(AName);
end;

procedure UndoPushMasked(ABmp, AMask: TBitmap; AProt: TBitmap;
  const AName: string);
var
  Bmp, Msk, Prot: TBitmap;
begin
  UndoDiscardPending;
  Bmp := TBitmap.Create;
  Bmp.Assign(ABmp);
  Msk := nil;
  if AMask <> nil then
  begin
    Msk := TBitmap.Create;
    Msk.PixelFormat := pf8bit;
    Msk.Assign(AMask);
  end;
  Prot := nil;
  if AProt <> nil then
  begin
    Prot := TBitmap.Create;
    Prot.PixelFormat := pf8bit;
    Prot.Assign(AProt);
  end;
  SetLength(UndoStack, Length(UndoStack) + 1);
  UndoStack[High(UndoStack)] := Bmp;
  SetLength(UndoMaskStack, Length(UndoMaskStack) + 1);
  UndoMaskStack[High(UndoMaskStack)] := Msk;
  SetLength(UndoProtStack, Length(UndoProtStack) + 1);
  UndoProtStack[High(UndoProtStack)] := Prot;
  UndoPushFinish(AName);
end;

function Undo(ABmp: TBitmap; AMask: TBitmap; AProt: TBitmap): Boolean;
var
  Bmp, Msk, Prot: TBitmap;
begin
  UndoDiscardPending;
  if Length(UndoStack) = 0 then Exit(False);
  Bmp := UndoStack[High(UndoStack)];
  Msk := UndoMaskStack[High(UndoMaskStack)];
  Prot := UndoProtStack[High(UndoProtStack)];
  SetLength(UndoStack, Length(UndoStack) - 1);
  SetLength(UndoMaskStack, Length(UndoMaskStack) - 1);
  SetLength(UndoProtStack, Length(UndoProtStack) - 1);
  // Nazwa cofnietej operacji przechodzi na stos Ponow
  SetLength(RedoNames, Length(RedoNames) + 1);
  RedoNames[High(RedoNames)] := UndoNames[High(UndoNames)];
  SetLength(UndoNames, Length(UndoNames) - 1);
  // Push current to redo
  SetLength(RedoStack, Length(RedoStack) + 1);
  RedoStack[High(RedoStack)] := TBitmap.Create;
  RedoStack[High(RedoStack)].Assign(ABmp);
  SetLength(RedoMaskStack, Length(RedoMaskStack) + 1);
  RedoMaskStack[High(RedoMaskStack)] := nil;
  if AMask <> nil then
  begin
    RedoMaskStack[High(RedoMaskStack)] := TBitmap.Create;
    RedoMaskStack[High(RedoMaskStack)].Assign(AMask);
  end;
  SetLength(RedoProtStack, Length(RedoProtStack) + 1);
  RedoProtStack[High(RedoProtStack)] := nil;
  if AProt <> nil then
  begin
    RedoProtStack[High(RedoProtStack)] := TBitmap.Create;
    RedoProtStack[High(RedoProtStack)].Assign(AProt);
  end;
  // Restore
  ABmp.Assign(Bmp);
  Bmp.Free;
  if AMask <> nil then
  begin
    if Msk <> nil then
      AMask.Assign(Msk);
    Msk.Free;
  end
  else if Msk <> nil then
    Msk.Free;
  if AProt <> nil then
  begin
    if Prot <> nil then
      AProt.Assign(Prot);
    Prot.Free;
  end
  else if Prot <> nil then
    Prot.Free;
  Result := True;
end;

function Redo(ABmp: TBitmap; AMask: TBitmap; AProt: TBitmap): Boolean;
var
  Bmp, Msk, Prot: TBitmap;
begin
  UndoDiscardPending;
  if Length(RedoStack) = 0 then Exit(False);
  Bmp := RedoStack[High(RedoStack)];
  Msk := RedoMaskStack[High(RedoMaskStack)];
  Prot := RedoProtStack[High(RedoProtStack)];
  SetLength(RedoStack, Length(RedoStack) - 1);
  SetLength(RedoMaskStack, Length(RedoMaskStack) - 1);
  SetLength(RedoProtStack, Length(RedoProtStack) - 1);
  // Nazwa ponowionej operacji wraca na stos Cofnij
  SetLength(UndoNames, Length(UndoNames) + 1);
  UndoNames[High(UndoNames)] := RedoNames[High(RedoNames)];
  SetLength(RedoNames, Length(RedoNames) - 1);
  // Push current to undo
  SetLength(UndoStack, Length(UndoStack) + 1);
  UndoStack[High(UndoStack)] := TBitmap.Create;
  UndoStack[High(UndoStack)].Assign(ABmp);
  SetLength(UndoMaskStack, Length(UndoMaskStack) + 1);
  UndoMaskStack[High(UndoMaskStack)] := nil;
  if AMask <> nil then
  begin
    UndoMaskStack[High(UndoMaskStack)] := TBitmap.Create;
    UndoMaskStack[High(UndoMaskStack)].Assign(AMask);
  end;
  SetLength(UndoProtStack, Length(UndoProtStack) + 1);
  UndoProtStack[High(UndoProtStack)] := nil;
  if AProt <> nil then
  begin
    UndoProtStack[High(UndoProtStack)] := TBitmap.Create;
    UndoProtStack[High(UndoProtStack)].Assign(AProt);
  end;
  // Restore
  ABmp.Assign(Bmp);
  Bmp.Free;
  if AMask <> nil then
  begin
    if Msk <> nil then
      AMask.Assign(Msk);
    Msk.Free;
  end
  else if Msk <> nil then
    Msk.Free;
  if AProt <> nil then
  begin
    if Prot <> nil then
      AProt.Assign(Prot);
    Prot.Free;
  end
  else if Prot <> nil then
    Prot.Free;
  Result := True;
end;

function UndoRestoreOriginal(ABmp: TBitmap): Boolean;
var
  OrigBmp: TBitmap;
  I: Integer;
  Names: TArray<string>;
begin
  UndoDiscardPending;
  if Length(UndoStack) = 0 then Exit(False);

  // Nazwy na stos Ponow: stan biezacy powstal z UndoNames[High], stan
  // UndoStack[I] z UndoNames[I - 1] (kolejnosc jak RedoStack nizej).
  Names := [UndoNames[High(UndoNames)]];
  for I := High(UndoStack) downto 1 do
    Names := Names + [UndoNames[I - 1]];

  // Maski alfa i protekcja sa pomijane przez "wroc do oryginalu" - zwalniane.
  for I := 0 to High(UndoMaskStack) do
    UndoMaskStack[I].Free;
  SetLength(UndoMaskStack, 0);
  for I := 0 to High(UndoProtStack) do
    UndoProtStack[I].Free;
  SetLength(UndoProtStack, 0);

  // Wyczy�� dotychczasowy stos Redo
  UndoClearRedo;

  // Przenie� obecny obraz na stos Redo jako pierwszy krok powrotny
  SetLength(RedoStack, Length(RedoStack) + 1);
  RedoStack[High(RedoStack)] := TBitmap.Create;
  RedoStack[High(RedoStack)].Assign(ABmp);

  // Przenie� pozosta�e stany z Undo do Redo (od najnowszego do drugiego najstarszego),
  // aby u�ytkownik m�g� ewentualnie przechodzi� przez nie po przywr�ceniu
  for I := High(UndoStack) downto 1 do
  begin
    SetLength(RedoStack, Length(RedoStack) + 1);
    RedoStack[High(RedoStack)] := UndoStack[I];
  end;

  // Najstarsza bitmapa (orygina�) to pierwszy element w UndoStack
  OrigBmp := UndoStack[0];
  ABmp.Assign(OrigBmp);
  OrigBmp.Free;

  // Wyczyszczenie stosu Undo (zostaje pusty, bo wr�cili�my do stanu 0)
  SetLength(UndoStack, 0);
  // Maski alfa i protekcja: w RedoStack trzymane jako nil - wyr�wnanie d�ugo�ci stos�w.
  for I := 0 to High(RedoMaskStack) do
    RedoMaskStack[I].Free;
  SetLength(RedoMaskStack, Length(RedoStack));
  for I := 0 to High(RedoMaskStack) do
    RedoMaskStack[I] := nil;
  SetLength(UndoMaskStack, 0);
  for I := 0 to High(RedoProtStack) do
    RedoProtStack[I].Free;
  SetLength(RedoProtStack, Length(RedoStack));
  for I := 0 to High(RedoProtStack) do
    RedoProtStack[I] := nil;
  SetLength(UndoProtStack, 0);
  RedoNames := Names;
  SetLength(UndoNames, 0);

  Result := True;
end;

procedure UndoClearRedo;
var
  I: Integer;
begin
  for I := 0 to High(RedoStack) do
    RedoStack[I].Free;
  SetLength(RedoStack, 0);
  for I := 0 to High(RedoMaskStack) do
    RedoMaskStack[I].Free;
  SetLength(RedoMaskStack, 0);
  for I := 0 to High(RedoProtStack) do
    RedoProtStack[I].Free;
  SetLength(RedoProtStack, 0);
  SetLength(RedoNames, 0);
end;

function UndoCanUndo: Boolean;
begin
  Result := Length(UndoStack) - Ord(UndoPending) > 0;
end;

function UndoCanRedo: Boolean;
begin
  Result := Length(RedoStack) > 0;
end;

function UndoTopName: string;
var
  I: Integer;
begin
  I := High(UndoNames) - Ord(UndoPending);
  if I >= 0 then Result := UndoNames[I] else Result := '';
end;

function RedoTopName: string;
begin
  if Length(RedoNames) > 0 then
    Result := RedoNames[High(RedoNames)]
  else
    Result := '';
end;

procedure UndoClear;
var
  I: Integer;
begin
  for I := 0 to High(UndoStack) do
    UndoStack[I].Free;
  SetLength(UndoStack, 0);
  for I := 0 to High(UndoMaskStack) do
    UndoMaskStack[I].Free;
  SetLength(UndoMaskStack, 0);
  for I := 0 to High(UndoProtStack) do
    UndoProtStack[I].Free;
  SetLength(UndoProtStack, 0);
  SetLength(UndoNames, 0);
  UndoPending := False;
  UndoClearRedo;
end;

end.
