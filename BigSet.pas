unit BigSet;

interface

const
  SMALL_SET_SIZE = 256;

type
  TSmallSet = set of byte;
  PSetLink = ^TSetLink;
  TSetLink = record
    data: TSmallSet;
    index: integer;
    next: PSetLink;
  end;

  TBigSet = PSetLink;

//PRIVATE
function _bsCreateLink(const index: integer): PSetLink;
function _bsChainLinkAfter(var prevLink: PSetLink; var targetLink: PSetLink): PSetLink;
function _bsCreateLinkAfter(var prevLink: PSetLink; const index: integer): PSetLink;
function _bsRetrieveLinkWithIndex(var _bigSet: TBigSet; const targetIndex: integer; createIfNExists: boolean): PSetLink;
procedure _bsInsertInSmallSet(var targetLink: PSetLink; const value: byte);
procedure _bsDeleteLinkAfter(var targetLink: PSetLink);
function _bsRetrieveLinkBefore(_bigSet: TBigSet; targetLink: PSetLink): PSetLink;

//PUBLIC
function bsCreate: TBigSet;
procedure bsInclude(var _bigSet: TBigSet; const value: integer);
function bsIsInSet(var _bigSet: TBigSet; const value: integer): boolean;
procedure bsExclude(var _bigSet: TBigSet; const value: integer);

implementation


{
  Создаёт пустое множество, возвращает указатель на него
}
function bsCreate: TBigSet;
begin
  result:= _bsCreateLink(0);
end;

{
  Включает элемент value во множество _bigSet
}
procedure bsInclude(var _bigSet: TBigSet; const value: integer);
var
  targetIndex: integer;
  targetValue: byte;
  targetLink: PSetLink;
begin
  //Вычисляем целевой индекс звена
  targetIndex:= value div SMALL_SET_SIZE;

  //Получаем звено, в которое нужно загнать элемент
  //targetLink:= (_bigSet, targetIndex);
  targetLink:= _bsRetrieveLinkWithIndex(_bigSet, targetIndex, true);

  //Вычисляем позицию элемента внутри звена
  targetValue:= value mod SMALL_SET_SIZE;

  //Загоняем элемент в звено на нужное место
  _bsInsertInSmallSet(targetLink, targetValue);
end;

{
  Исключает элемент value из множества _bigSet
}
function bsIsInSet(var _bigSet: TBigSet; const value: integer):boolean;
var
  targetIndex: integer;
  targetLink: PSetLink;
  targetValue: byte;
begin
  //Вычисляем предполагаемый индекс, в котором должен лежать элемент
  targetIndex:= value div SMALL_SET_SIZE;

  //Получаем ссылку на звено с предполагаемым индексом
  targetLink:= _bsRetrieveLinkWithIndex(_bigSet, targetIndex, false);

  //Если оно существует
  if targetLink <> nil then
  begin
    //Позиция элемента внутри маленького множества
    targetValue:= value mod SMALL_SET_SIZE;

    //Возвращаем, есть ли заданный элемент на нужном месте
    result:= targetValue in targetLink^.data;
  end

  //Иначе, если такое звено не найдено
  else
  begin
    //Возвращаем ЛОЖЬ
    result:= false;
  end;
end;

procedure bsExclude(var _bigSet: TBigSet; const value: integer);
var
  targetLink, prevLink: PSetLink;
  targetIndex: integer;
  targetValue: byte;
begin
  //TODO: Запилить исключение элемента из множества
  //Если элемент не во множестве, просто выходим
  if not bsIsInSet(_bigSet, value) then
  begin
    exit;
  end;

  //Вычисляем целевой индекс и позицию элемента внутри маленького множества
  targetIndex:= value div SMALL_SET_SIZE;
  targetValue:= value mod SMALL_SET_SIZE;

  //Получаем ссылку на звено с целевым индексом
  targetLink:= _bsRetrieveLinkWithIndex(_bigSet, targetIndex, false);

  //Исключаем элемент из звена
  targetLink^.data := targetLink^.data - [targetValue];

  //Если звено оказалось пустым, исключаем звено из списка
  if targetLink^.data = [] then
  begin
    prevLink:= _bsRetrieveLinkBefore(_bigSet, targetLink);
    if prevLink <> nil then
      _bsDeleteLinkAfter(prevLink);
  end;

  //?????
  //PROFIT
end;

{
  Возвращает ссылку на звено, которое предшествует targetLink
}
function _bsRetrieveLinkBefore(_bigSet: TBigSet; targetLink: PSetLink): PSetLink;
var
  currentLink: PSetLink;
  isFound: boolean;
begin
  //Поиск по звеньям от начала и до победного конца
  currentLink:=_bigSet;
  isFound:= false;
  while (currentLink <> nil) and (not isFound) do
  begin
    //Проверяем условие
    isFound:= currentLink^.next = targetLink;

    //Если не нашли, идём дальше
    if not isFound then
      currentLink:= currentLink^.next;
  end;

  result:= currentLink;
end;

procedure _bsDeleteLinkAfter(var targetLink: PSetLink);
var
  linkToDelete: PSetLink;
begin
  //Если переданное звено nil, делать нам тут нечего
  if targetLink = nil then
  begin
    exit;
  end;

  //Получаем ссылку на то звено, которое нужно удалить
  linkToDelete:= targetLink^.next;
  //Если она оказалась
  if linkToDelete = nil then

  _bsChainLinkAfter(targetLink, linkToDelete^.next);
end;

{
  Добавляет в обычное множество звена targetLink элемент value
}
procedure _bsInsertInSmallSet(var targetLink: PSetLink; const value: byte);
begin
  targetLink^.data:= targetLink^.data + [value];
end;

{
  Создаёт звено цепи
  Возвращает указатель на него
}
function _bsCreateLink(const index: integer): PSetLink;
begin
  new(result);
  result^.data:= [];
  result^.index:= index;
  result^.next:= nil;
end;

{
  Привязывает звено targetLink после звена prevLink
  Возвращает указатель на targetLink
}
function _bsChainLinkAfter(var prevLink: PSetLink; var targetLink: PSetLink): PSetLink;
begin
  //Подвязываем звено к следующему элементу
  targetLink^.next:= prevLink^.next;

  //А теперь впихиваем звено в цепь
  prevLink^.next:= targetLink;

  result:= targetLink;
end;

{
  Создаёт звено цепи с индексом index и привязывает его после prevLink
}
function _bsCreateLinkAfter(var prevLink: PSetLink; const index: integer): PSetLink;
begin
  result:= _bsCreateLink(index);
  
  if prevLink <> nil then
    result:= _bsChainLinkAfter(prevLink, result);  
end;

{
  Ищет звено с индексом targetIndex и возвращает ссылку на него
  Если звено не найдено, оно создаётся так, чтобы итоговая цепь была упорядочена
}
function _bsRetrieveLinkWithIndex(var _bigSet: TBigSet; const targetIndex: integer; createIfNExists: boolean): PSetLink;
var
  prevLink: PSetLink;
  curLink: PSetLink;

  isFound: boolean;
begin
  curLink:= _bigSet;
  result:= nil;
  prevLink:= nil;
  isFound:= curLink^.index >= targetIndex;
  
  //Идти либо до конца, либо до того момент, когда
  while (curLink <> nil) and (not isFound) do
  begin
    //Индекс текущего звена не станет больше, либо равным целевому
    isFound:= curLink^.index >= targetIndex;

    if curLink^.index < targetIndex then
    begin
      //Шагаем дальше
      prevLink:= curLink;
      curLink:= curLink^.next;
    end;
  end;

  //Иначе, если текущий индекс стал больше целевого, либо мы оказались где-то в жопе, а звено нам всё же нужно
  if (curLink = nil) or (curLink^.index > targetIndex) and (createIfNExists) then
  begin
      //Создаём звено после предыдущего с целевым индексом
      //Возвращаем указатель на только что созданное звено
      result:= _bsCreateLinkAfter(prevLink, targetIndex);
  end

  //Иначе, если текущий индекс равен целевому
  else if curLink^.index = targetIndex then
  begin
    //Возвращаем указатель на текущее звено
    result:= curLink;
  end;
end;

end.