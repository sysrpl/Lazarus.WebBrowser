unit WebSystem;

interface

{$i webbrowser.inc}

uses
  SysUtils, Classes, Graphics;

type
  Float = Single;
  PFloat = ^Float;
  LargeInt = Int64;
  PLargeInt = ^LargeInt;
  LargeWord = QWord;
  PLargeWord = ^LargeWord;
  SysInt = NativeInt;
  PSysInt = ^SysInt;

procedure MemClear(out Buffer; Size: UIntPtr); inline;
function MemCompare(const BufferA, BufferB; Size: LongWord): Boolean;

function OrdToType<T>(Value: LongWord): T;
function TypeToOrd<T>(Value: T): LongWord;

function GraphicFromFile(const FileName: string): TGraphic;
function GraphicFromStream(Stream: TStream): TGraphic;
function GraphicFromResourceName(const ResName: string): TGraphic;

{ TArray<T> is a shortcut to a typed dynamic array }

type
  TArray<T> = array of T;

{ TCompare\<T\> is used to compare two items }

  TCompare<T> = function(constref A, B: T): Integer;
{ TConvertString\<T\> is used to convert a type to a string }

  TConvertString<TItem> = function(constref Item: TItem): string;

{ TFilterFunc\<T\> is used to test if and item passes a test }

  TFilterFunc<T> = function(constref Value: T): Boolean;

  TArrayEnumerator<T> = class(TInterfacedObject, IEnumerator<T>)
  private
    FItems: TArray<T>;
    FPosition: Integer;
    FCount: Integer;
  public
    constructor Create(Items: TArray<T>; Count: Integer = -1);
    { IEnumerator<T> }
    function GetCurrent: T;
    function MoveNext: Boolean;
    procedure Reset;
    property Current: T read GetCurrent;
  end;

{ TSortingOrder can be used to a sort items forward, backwards, or not at all }

  TSortingOrder = (soAscend, soDescend, soNone);

{ TArrayList\<T\> is a simple extension to dynamic arrays }

  TArrayList<T> = record
  public type
    TArrayListEnumerator = class(TArrayEnumerator<T>) end;
    TCompareFunc = TCompare<T>;
    { Get the enumerator for the list }
    function GetEnumerator: IEnumerator<T>;
  private
    function CompareExists: Boolean;
    procedure QuickSort(Order: TSortingOrder; Compare: TCompare<T>; L, R: Integer);
    function GetIsEmpty: Boolean;
    function GetFirst: T;
    procedure SetFirst(const Value: T);
    function GetLast: T;
    procedure SetLast(const Value: T);
    function GetLength: Integer;
    procedure SetLength(Value: Integer);
    function GetData: Pointer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
  public
    class var DefaultCompare: TCompare<T>;
    class var DefaultConvertString: TConvertString<T>;
    { The array acting as a list }
    var Items: TArray<T>;
    class function ArrayOf(const Items: array of T): TArrayList<T>; static;
    class function Convert: TArrayList<T>; static;
    { Convert a list to an array }
    class operator Implicit(const Value: TArrayList<T>): TArray<T>;
    { Convert an array to a list }
    class operator Implicit(const Value: TArray<T>): TArrayList<T>;
    { Convert an open array to a list }
    class operator Implicit(const Value: array of T): TArrayList<T>;
    { Performs a simple safe copy of up to N elements }
    procedure Copy(out List: TArrayList<T>; N: Integer);
    { Performs a fast unsafe copy of up to N elements }
    procedure CopyFast(out List: TArrayList<T>; N: Integer);
    { Returns the lower bounds of the list }
    function Lo: Integer;
    { Returns the upper bounds of the list }
    function Hi: Integer;
    { Reverses theitems in the list }
    procedure Reverse;
    { Swap two items in the list }
    procedure Exchange(A, B: Integer);
    { Adds and item to the end of the list }
    procedure Push(const Item: T);
    { Appends an array of items to the list }
    procedure PushRange(const Collection: array of T);
    { Remove an item from the end of the list }
    function Pop: T;
    { Remove an item randomly from the list }
    function PopRandom: T;
    { Return a copy of the list with items passing through a filter }
    function Filter(Func: TFilterFunc<T>): TArrayList<T>;
    { Resurn the first item matching a condition }
    function FirstOf(Func: TFilterFunc<T>): T;
    { Removes an item by index from the list and decresaes the count by one }
    procedure Delete(Index: Integer);
    { Removes all items setting the count of the list to 0 }
    procedure Clear;
    { Sort the items using a comparer }
    procedure Sort(Order: TSortingOrder = soAscend; Comparer: TCompare<T> = nil);
    { Attempt to find the item using DefaultCompare }
    function IndexOf(const Item: T): Integer; overload;
    { Attempt to find the item using a supplied comparer }
    function IndexOf(const Item: T; Comparer: TCompare<T>): Integer; overload;
    { Join a the array into a string using a separator }
    function Join(const Separator: string; Convert: TConvertString<T> = nil): string;
    { Returns true if ther are no items in the list }
    property IsEmpty: Boolean read GetIsEmpty;
    { First item in the list }
    property First: T read GetFirst write SetFirst;
    { Last item in the list }
    property Last: T read GetLast write SetLast;
    { Number of items in the list }
    property Length: Integer read GetLength write SetLength;
    { Address where to the first item is located }
    property Data: Pointer read GetData;
    { Get or set an item }
    property Item[Index: Integer]: T read GetItem write SetItem; default;
  end;

{ TMap\<K, V\> is a array like simple dictionary }

  TMap<K, V> = record
  private
    FKeys: TArrayList<K>;
    FValues: TArrayList<V>;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
  public
    { Get or set and item using a key }
    property Item[const Key: K]: V read GetItem write SetItem;
  end;

{ TBaseGrowList }

  TBaseList = class
  public
    constructor Create(N: Integer = 0); virtual;
  end;

  TBaseListClass = class of TBaseList;

{ TGrowList\<T\> is a class for incrementally adding large amounts of growing data }

  TGrowList<T> = class(TBaseList)
  private
    FBuffer: TArrayList<T>;
    FCount: Integer;
    FLength: Integer;
    procedure Grow(N: Integer);
    function GetData(Index: Integer): Pointer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; Value: T);
  protected
    procedure Added(N: Integer); virtual;
  public
    { Create a new dynamic buffer optionally allocating room for a N number
      of future items }
    constructor Create(N: Integer = 0); override;
    { Remove any extra data allocated by the previous grow }
    procedure Pack;
    { Create a copy of the list }
    function Clone: TObject; virtual;
    { Add a range of items to the list }
    procedure AddRange(const Range: array of T);
    { Add a single item to the list }
    procedure AddItem(const Item: T);
    { Clear the buffer optionally allocating room for a N number
      of future items }
    procedure Clear(N: Integer = 0);
    { Pointer to the data at a specified index }
    property Data[Index: Integer]: Pointer read GetData; default;
    { Item at specified index }
    property Item[Index: Integer]: T read GetItem write SetItem;
    { The number of items in the list }
    property Count: Integer read FCount;
  end;

  StringArray = TArrayList<string>;
  WordArray = TArrayList<Word>;
  IntArray = TArrayList<Integer>;
  Int64Array = TArrayList<Int64>;
  FloatArray = TArrayList<Float>;
  BoolArray = TArrayList<Boolean>;
  PointerArray = TArrayList<Pointer>;
  ObjectArray = TArrayList<TObject>;
  InterfaceArray = TArrayList<IInterface>;

function DefaultStringCompare(constref A, B: string): Integer;
function DefaultStringConvertString(constref Item: string): string;
function DefaultWordCompare(constref A, B: Word): Integer;
function DefaultWordConvertString(constref Item: Word): string;
function DefaultIntCompare(constref A, B: Integer): Integer;
function DefaultIntConvertString(constref Item: Integer): string;
function DefaultInt64Compare(constref A, B: Int64): Integer;
function DefaultInt64ConvertString(constref Item: Int64): string;
function DefaultFloatCompare(constref A, B: Float): Integer;
function DefaultFloatConvertString(constref Item: Float): string;
function DefaultObjectCompare(constref A, B: TObject): Integer;
function DefaultInterfaceCompare(constref A, B: IInterface): Integer;
function DefaultCompare8(constref A, B: Byte): Integer;
function DefaultCompare16(constref A, B: Word): Integer;
function DefaultCompare32(constref A, B: LongWord): Integer;
function DefaultCompare64(constref A, B: LargeWord): Integer;

implementation

procedure MemClear(out Buffer; Size: UIntPtr);
begin
  FillChar(Buffer, Size, 0);
end;

function MemCompare(const BufferA, BufferB; Size: LongWord): Boolean;
var
  C, D: PByte;
begin
  C := @BufferA;
  D := @BufferB;
  if (C = nil) or (D = nil) then
    Exit(False);
  while Size > 0 do
  begin
    if C^ <> D^ then
      Exit(False);
    Inc(C);
    Inc(D);
    Dec(Size);
  end;
  Result := True;
end;

function OrdToType<T>(Value: LongWord): T;
var
  B: Byte;
  W: Word;
  L: LongWord;
begin
  Result := Default(T);
  case SizeOf(T) of
    1:
      begin
        B := Value;
        Move(B, Result, 1);
      end;
    2:
      begin
        W := Value;
        Move(W, Result, 2);
      end;
    4:
      begin
        L := Value;
        Move(L, Result, 4)
      end;
  end;
end;

function TypeToOrd<T>(Value: T): LongWord;
var
  B: Byte;
  W: Word;
  L: LongWord;
begin
  B := 0;
  W := 0;
  L := 0;
  Result := 0;
  case SizeOf(T) of
    1:
      begin
        Move(Value, B, 1);
        Result := B;
      end;
    2:
      begin
        Move(Value, W, 2);
        Result := W;
      end;
    4:
      begin
        Move(Value, L, 4);
        Result := L;
      end;
  end;
end;

function GraphicFromFile(const FileName: string): TGraphic;
var
  P: TPicture;
begin
  P := TPicture.Create;
  try
    P.LoadFromFile(FileName);
    Result := TGraphicClass(P.Graphic.ClassType).Create;
    Result.Assign(P.Graphic);
  finally
    P.Free;
  end;
end;

function GraphicFromStream(Stream: TStream): TGraphic;
var
  P: TPicture;
begin
  P := TPicture.Create;
  try
    Stream.Seek(0, 0);
    P.LoadFromStream(Stream);
    Result := TGraphicClass(P.Graphic.ClassType).Create;
    Result.Assign(P.Graphic);
  finally
    P.Free;
  end;
end;

function GraphicFromResourceName(const ResName: string): TGraphic;
var
  P: TPicture;
begin
  P := TPicture.Create;
  try
    P.LoadFromResourceName(HINSTANCE, ResName);
    Result := TGraphicClass(P.Graphic.ClassType).Create;
    Result.Assign(P.Graphic);
  finally
    P.Free;
  end;
end;

{ TArrayEnumerator<T> }

constructor TArrayEnumerator<T>.Create(Items: TArray<T>; Count: Integer = -1);
begin
  inherited Create;
  FItems := Items;
  FPosition := -1;
  if Count < 0 then
    FCount := Length(Items)
  else
    FCount := Count;
end;

function TArrayEnumerator<T>.GetCurrent: T;
begin
  Result := FItems[FPosition];
end;

function TArrayEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FCount;
end;

procedure TArrayEnumerator<T>.Reset;
begin
  FPosition := -1;
end;

{ TArrayList<T> }

function TArrayList<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := TArrayListEnumerator.Create(Items);
end;

class operator TArrayList<T>.Implicit(const Value: TArrayList<T>): TArray<T>;
begin
  Result := Value.Items;
end;

class operator TArrayList<T>.Implicit(const Value: TArray<T>): TArrayList<T>;
begin
  Result.Items := Value;
end;

class operator TArrayList<T>.Implicit(const Value: array of T): TArrayList<T>;
var
  I: T;
begin
  for I in Value do
    Result.Push(I);
end;

class function TArrayList<T>.ArrayOf(const Items: array of T): TArrayList<T>;
var
  I: T;
begin
  for I in Items do
    Result.Push(I);
end;

procedure TArrayList<T>.Copy(out List: TArrayList<T>; N: Integer);
var
  I: Integer;
begin
  if N < 1 then
    N := Length
  else if N > Length then
    N := Length;
  List.Length := N;
  if N < 1 then
    Exit;
  for I := 0 to N - 1 do
    List.Items[I] := Items[I];
end;

procedure TArrayList<T>.CopyFast(out List: TArrayList<T>; N: Integer);
begin
  if N < 1 then
    N := Length
  else if N > Length then
    N := Length;
  List.Length := N;
  if N < 1 then
    Exit;
  System.Move(Items[0], List.Items[0], N * SizeOf(T));
end;

procedure TArrayList<T>.Reverse;
var
  Swap: T;
  I, J: Integer;
begin
  I := 0;
  J := Length;
  while I < J do
  begin
    Swap := Items[I];
    Items[I] := Items[J];
    Items[J] := Swap;
    Inc(I);
    Dec(J);
  end;
end;

function TArrayList<T>.Lo: Integer;
begin
  Result := Low(Items);
end;

function TArrayList<T>.Hi: Integer;
begin
  Result := High(Items);
end;

procedure TArrayList<T>.Exchange(A, B: Integer);
var
  Item: T;
begin
  if A <> B then
  begin
    Item := Items[A];
    Items[A] := Items[B];
    Items[B] := Item;
  end;
end;

procedure TArrayList<T>.Push(const Item: T);
var
  I: Integer;
begin
  I := Length;
  Length := I + 1;
  Items[I] := Item;
end;

procedure TArrayList<T>.PushRange(const Collection: array of T);
var
  I, J: Integer;
begin
  I := Length;
  J := High(Collection) - Low(Collection) + 1;
  if J < 1 then
    Exit;
  Length := I + J;
  for J := Low(Collection) to High(Collection) do
  begin
    Items[I] := Collection[J];
    Inc(I);
  end;
end;

function TArrayList<T>.Pop: T;
var
  I: Integer;
begin
  I := Length - 1;
  if I < 0 then
  begin
    Result := Default(T);
    Length := 0;
  end
  else
  begin
    Result := Items[I];
    Length := I;
  end;
end;

function TArrayList<T>.PopRandom: T;
var
  I: Integer;
begin
  I := Length;
  if I < 2 then
    Result := Pop
  else
  begin
    I := System.Random(I);
    Result := Items[I];
    Delete(I);
  end;
end;

function TArrayList<T>.Filter(Func: TFilterFunc<T>): TArrayList<T>;
var
  I, J: Integer;
begin
  J := System.Length(Items);
  System.SetLength(Result.Items, J);
  J := 0;
  for I := 0 to System.Length(Items) - 1 do
    if Func(Items[I]) then
    begin
   Result.Items[J] := Items[I];
   Inc(J);
    end;
  System.SetLength(Result.Items, J);
end;

function TArrayList<T>.FirstOf(Func: TFilterFunc<T>): T;
var
  I: Integer;
begin
  for I := 0 to System.Length(Items) - 1 do
    if Func(Items[I]) then
   Exit(Items[I]);
  Result := Default(T);
end;

procedure TArrayList<T>.Delete(Index: Integer);
var
  I, J: Integer;
begin
  I := Length - 1;
  for J := Index + 1 to I do
    Items[J - 1] := Items[J];
  Length := I;
end;

procedure TArrayList<T>.Clear;
begin
  Length := 0;
end;

{ TMap<K, V> }

function TMap<K, V>.GetItem(const Key: K): V;
var
  I: Integer;
begin
  I := FKeys.IndexOf(Key);
  if I > -1 then
    Result := FValues.Items[I]
  else
    Result := Default(V);
end;

procedure TMap<K, V>.SetItem(const Key: K; const Value: V);
var
  I: Integer;
begin
  I := FKeys.IndexOf(Key);
  if I > -1 then
    FValues.Items[I] := Value
  else
  begin
    FKeys.Push(Key);
    FValues.Push(Value);
  end;
end;

constructor TBaseList.Create(N: Integer = 0);
begin
  inherited Create;
end;

{ TGrowList<T> }

constructor TGrowList<T>.Create(N: Integer = 0);
begin
  inherited Create(N);
  Clear(N);
end;

procedure TGrowList<T>.Pack;
begin
  if FCount < FLength then
  begin
    FLength := FCount;
    FBuffer.Length := FLength;
  end;
end;

function TGrowList<T>.Clone: TObject;
var
  Copy: TGrowList<T>;
begin
  Copy := TBaseListClass(ClassType).Create as TGrowList<T>;
  if FCount = 0 then
    Exit(Copy);
  Copy.FCount := FCount;
  Copy.FLength := FCount;
  FBuffer.CopyFast(Copy.FBuffer, FCount);
  Result := Copy;
end;

procedure TGrowList<T>.Added(N: Integer);
begin
end;

procedure TGrowList<T>.Grow(N: Integer);
const
  MaxGrowSize = 50000;
var
  C: Integer;
begin
  if N < 1 then
    Exit;
  if N < 16 then
    N := 16;
  if N + FCount > FLength then
    if FLength = 0 then
    begin
      FLength := N;
      FBuffer.Length := N;
    end
    else
    begin
      if FLength > MaxGrowSize then
      begin
        if N < MaxGrowSize then
        C := MaxGrowSize
        else
        C := N;
        C := FLength + C;
      end
      else
      begin
        C := FLength + MaxGrowSize;
        C := FLength * 2;
        FLength := FLength + N;
        while C < FLength do
          C := C * 2;
      end;
     FLength := C;
     FBuffer.Length := C;
    end;
end;

procedure TGrowList<T>.Clear(N: Integer = 0);
begin
  FCount := 0;
  if N = 0 then
  begin
    FLength := 0;
    FBuffer.Length := 0
  end
  else if N > FBuffer.Length then
    Grow(N - FBuffer.Length);
  Added(0);
end;

procedure TGrowList<T>.AddRange(const Range: array of T);
var
  I, J: Integer;
begin
  I := Length(Range);
  if I < 1 then
    Exit;
  Grow(I);
  for J := 0 to I - 1 do
    FBuffer.Items[FCount + J] := Range[J];
  Inc(FCount, I);
  Added(I);
end;

procedure TGrowList<T>.AddItem(const Item: T);
begin
  Grow(1);
  FBuffer.Items[FCount] := Item;
  Inc(FCount);
  Added(1);
end;

function TGrowList<T>.GetData(Index: Integer): Pointer;
begin
  Result := @FBuffer.Items[Index];
end;

function TGrowList<T>.GetItem(Index: Integer): T;
begin
  Result := FBuffer.Items[Index];
end;

procedure TGrowList<T>.SetItem(Index: Integer; Value: T);
begin
  FBuffer.Items[Index] := Value;
end;

{ Compare functions }

function DefaultCompare8(constref A, B: Byte): Integer;
begin
  Result := B - A;
end;

function DefaultCompare16(constref A, B: Word): Integer;
begin
  Result := B - A;
end;

function DefaultCompare32(constref A, B: LongWord): Integer;
begin
  Result := B - A;
end;

function DefaultCompare64(constref A, B: LargeWord): Integer;
begin
  Result := B - A;
end;

function TArrayList<T>.CompareExists: Boolean;
begin
  if Assigned(DefaultCompare) then
    Exit(True);
  case SizeOf(T) of
    8: DefaultCompare := TCompareFunc(DefaultCompare8);
    16: DefaultCompare := TCompareFunc(DefaultCompare16);
    32: DefaultCompare := TCompareFunc(DefaultCompare32);
    64: DefaultCompare := TCompareFunc(DefaultCompare64);
  end;
  Result := Assigned(DefaultCompare);
end;

procedure TArrayList<T>.QuickSort(Order: TSortingOrder; Compare: TCompare<T>; L, R: Integer);
var
  F, I, J, P: Integer;
begin
  repeat
    if Order = soDescend then
   F := -1
    else
   F := 1;
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
   while Compare(Items[I], Items[P]) * F < 0 do Inc(I);
   while Compare(Items[J], Items[P]) * F > 0 do Dec(J);
   if I <= J then
   begin
  Exchange(I, J);
  if P = I then
    P := J
  else if P = J then
    P := I;
  Inc(I);
  Dec(J);
   end;
    until I > J;
    if L < J then QuickSort(Order, Compare, L, J);
    L := I;
  until I >= R;
end;

procedure TArrayList<T>.Sort(Order: TSortingOrder = soAscend; Comparer: TCompare<T> = nil);
var
  I: Integer;
begin
  if Order = soNone then
    Exit;
  I := Length;
  if I < 2 then
    Exit;
  if Assigned(Comparer) then
    QuickSort(Order, Comparer, 0, I - 1)
  else if CompareExists then
    QuickSort(Order, DefaultCompare, 0, I - 1);
end;

function TArrayList<T>.IndexOf(const Item: T): Integer;
var
  I: Integer;
begin
  Result := -1;
  I := Length;
  if (I > 0) and CompareExists then
    for I := Lo to Hi do
      if DefaultCompare(Item, Items[I]) = 0 then
  Exit(I);
end;

function TArrayList<T>.IndexOf(const Item: T; Comparer: TCompare<T>): Integer;
var
  I: Integer;
begin
  Result := -1;
  I := Length;
  if I > 0 then
    for I := Lo to Hi do
   if Comparer(Item, Items[I]) = 0 then
  Exit(I);
end;

function TArrayList<T>.Join(const Separator: string; Convert: TConvertString<T> = nil): string;
var
  I: Integer;
begin
  Result := '';
  if Length < 1 then
    Exit;
  if Assigned(Convert) then
  begin
    Result := Convert(First);
    for I := Low(Items) + 1 to High(Items) do
   Result := Result + Separator + Convert(Items[I]);
  end
  else if Assigned(DefaultConvertString) then
  begin
    Result := DefaultConvertString(First);
    for I := Low(Items) + 1 to High(Items) do
   Result := Result + Separator + DefaultConvertString(Items[I]);
  end;
end;

function TArrayList<T>.GetIsEmpty: Boolean;
begin
  Result := Length = 0;
end;

function TArrayList<T>.GetFirst: T;
begin
  if Length > 0 then
    Result := Items[0]
  else
    Result := Default(T);
end;

procedure TArrayList<T>.SetFirst(const Value: T);
begin
  if Length > 0 then
    Items[0] := Value;
end;

function TArrayList<T>.GetLast: T;
begin
  if Length > 0 then
    Result := Items[Length - 1]
  else
    Result := Default(T);
end;

procedure TArrayList<T>.SetLast(const Value: T);
begin
  if Length > 0 then
    Items[Length - 1] := Value;
end;

function TArrayList<T>.GetLength: Integer;
begin
  Result := System.Length(Items);
end;

procedure TArrayList<T>.SetLength(Value: Integer);
begin
  System.SetLength(Items, Value);
end;

function TArrayList<T>.GetData: Pointer;
begin
  Result := @Items[0];
end;

function TArrayList<T>.GetItem(Index: Integer): T;
begin
  Result := Items[Index];
end;

procedure TArrayList<T>.SetItem(Index: Integer; const Value: T);
begin
  Items[Index] := Value;
end;

class function TArrayList<T>.Convert: TArrayList<T>;
begin
  Result.Length := 0;
end;

function DefaultStringCompare(constref A, B: string): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

function DefaultStringConvertString(constref Item: string): string;
begin
  Result := Item;
end;

function DefaultWordCompare(constref A, B: Word): Integer;
begin
  Result := B - A;
end;

function DefaultWordConvertString(constref Item: Word): string;
begin
  Result := IntToStr(Item);
end;

function DefaultIntCompare(constref A, B: Integer): Integer;
begin
  Result := B - A;
end;

function DefaultIntConvertString(constref Item: Integer): string;
begin
  Result := IntToStr(Item);
end;

function DefaultInt64Compare(constref A, B: Int64): Integer;
begin
  Result := B - A;
end;

function DefaultInt64ConvertString(constref Item: Int64): string;
begin
  Result := IntToStr(Item);
end;

function DefaultFloatCompare(constref A, B: Float): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

function DefaultFloatConvertString(constref Item: Float): string;
begin
  Result := FloatToStr(Item);
end;

function DefaultObjectCompare(constref A, B: TObject): Integer;
begin
  Result := IntPtr(A) - IntPtr(B);
end;

function DefaultInterfaceCompare(constref A, B: IInterface): Integer;
begin
  Result := IntPtr(A) - IntPtr(B);
end;

initialization
  StringArray.DefaultCompare := DefaultStringCompare;
  StringArray.DefaultConvertString := DefaultStringConvertString;
  WordArray.DefaultCompare := DefaultWordCompare;
  WordArray.DefaultConvertString := DefaultWordConvertString;
  IntArray.DefaultCompare := DefaultIntCompare;
  IntArray.DefaultConvertString := DefaultIntConvertString;
  Int64Array.DefaultCompare := DefaultInt64Compare;
  Int64Array.DefaultConvertString := DefaultInt64ConvertString;
  FloatArray.DefaultCompare := DefaultFloatCompare;
  FloatArray.DefaultConvertString := DefaultFloatConvertString;
end.

