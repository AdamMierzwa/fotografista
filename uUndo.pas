unit uUndo;

interface

uses
  Vcl.Graphics;

const
  MAX_UNDO = 20;

procedure UndoInit;
procedure UndoPush(ABmp: TBitmap);
procedure UndoPushMasked(ABmp, AMask: TBitmap; AProt: TBitmap = nil);
function Undo(ABmp: TBitmap; AMask: TBitmap = nil; AProt: TBitmap = nil): Boolean;
function Redo(ABmp: TBitmap; AMask: TBitmap = nil; AProt: TBitmap = nil): Boolean;
function UndoRestoreOriginal(ABmp: TBitmap): Boolean;
function UndoCanUndo: Boolean;
function UndoCanRedo: Boolean;
procedure UndoClear;

implementation

var
  UndoStack: array of TBitmap;
  RedoStack: array of TBitmap;
  UndoMaskStack: array of TBitmap;
  RedoMaskStack: array of TBitmap;
  UndoProtStack: array of TBitmap;
  RedoProtStack: array of TBitmap;

procedure UndoClearRedo; forward;

procedure UndoInit;
begin
  UndoClear;
end;

procedure UndoPush(ABmp: TBitmap);
var
  Bmp: TBitmap;
begin
  if Length(UndoStack) >= MAX_UNDO then
  begin
    UndoStack[0].Free;
    UndoMaskStack[0].Free;
    UndoProtStack[0].Free;
    Delete(UndoStack, 0, 1);
    Delete(UndoMaskStack, 0, 1);
    Delete(UndoProtStack, 0, 1);
  end;
  Bmp := TBitmap.Create;
  Bmp.Assign(ABmp);
  SetLength(UndoStack, Length(UndoStack) + 1);
  UndoStack[High(UndoStack)] := Bmp;
  SetLength(UndoMaskStack, Length(UndoMaskStack) + 1);
  UndoMaskStack[High(UndoMaskStack)] := nil;
  SetLength(UndoProtStack, Length(UndoProtStack) + 1);
  UndoProtStack[High(UndoProtStack)] := nil;
  // Clear redo on new action
  UndoClearRedo;
end;

procedure UndoPushMasked(ABmp, AMask: TBitmap; AProt: TBitmap);
var
  Bmp, Msk, Prot: TBitmap;
begin
  if Length(UndoStack) >= MAX_UNDO then
  begin
    UndoStack[0].Free;
    UndoMaskStack[0].Free;
    UndoProtStack[0].Free;
    Delete(UndoStack, 0, 1);
    Delete(UndoMaskStack, 0, 1);
    Delete(UndoProtStack, 0, 1);
  end;
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
  // Clear redo on new action
  UndoClearRedo;
end;

function Undo(ABmp: TBitmap; AMask: TBitmap; AProt: TBitmap): Boolean;
var
  Bmp, Msk, Prot: TBitmap;
begin
  if Length(UndoStack) = 0 then Exit(False);
  Bmp := UndoStack[High(UndoStack)];
  Msk := UndoMaskStack[High(UndoMaskStack)];
  Prot := UndoProtStack[High(UndoProtStack)];
  SetLength(UndoStack, Length(UndoStack) - 1);
  SetLength(UndoMaskStack, Length(UndoMaskStack) - 1);
  SetLength(UndoProtStack, Length(UndoProtStack) - 1);
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
  if Length(RedoStack) = 0 then Exit(False);
  Bmp := RedoStack[High(RedoStack)];
  Msk := RedoMaskStack[High(RedoMaskStack)];
  Prot := RedoProtStack[High(RedoProtStack)];
  SetLength(RedoStack, Length(RedoStack) - 1);
  SetLength(RedoMaskStack, Length(RedoMaskStack) - 1);
  SetLength(RedoProtStack, Length(RedoProtStack) - 1);
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
begin
  if Length(UndoStack) = 0 then Exit(False);

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
end;

function UndoCanUndo: Boolean;
begin
  Result := Length(UndoStack) > 0;
end;

function UndoCanRedo: Boolean;
begin
  Result := Length(RedoStack) > 0;
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
  UndoClearRedo;
end;

end.
