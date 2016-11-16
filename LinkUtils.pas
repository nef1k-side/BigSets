unit LinkUtils;

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


function  _bsCreateLink(const index: integer): PSetLink;
function  _bsChainLinkAfter(var prevLink: PSetLink; var targetLink: PSetLink): PSetLink;
function  _bsCreateLinkAfter(var prevLink: PSetLink; const index: integer): PSetLink;
function  _bsRetrieveLinkWithIndex(chainHead: PSetLink; const targetIndex: integer; createIfNExists: boolean): PSetLink;
procedure _bsInsertInSmallSet(var targetLink: PSetLink; const value: byte);
procedure _bsDeleteLinkAfter(var targetLink: PSetLink);
function  _bsRetrieveLinkBefore(chainHead: PSetLink; targetLink: PSetLink): PSetLink;


implementation

{
  Возвращает ссылку на звено, которое предшествует targetLink
}
function _bsRetrieveLinkBefore(chainHead: PSetLink; targetLink: PSetLink): PSetLink;
var
  currentLink: PSetLink;
  isFound: boolean;
begin
  //Поиск по звеньям от начала и до победного конца
  currentLink:= chainHead;
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

  //Если она nil, то ну как бы и всё, она удалена =]
  if linkToDelete = nil then
    exit;

  //Если она не nil, то нужно перевязать targetLink минуя linkToDelete
  _bsChainLinkAfter(targetLink, linkToDelete^.next);

  //И освободить память, выделенную под linkToDelete
  dispose(linkToDelete);
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
  //Если targetLink ещё никуда не подвязана
  if targetLink^.next = nil then
  begin
    //Подвязываем звено к следующему элементу
    targetLink^.next:= prevLink^.next;
  end;

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
function _bsRetrieveLinkWithIndex(chainHead: PSetLink; const targetIndex: integer; createIfNExists: boolean): PSetLink;
var
  prevLink: PSetLink;
  curLink: PSetLink;

  isFound: boolean;
begin
  curLink:= chainHead;
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
  if ((curLink = nil) or (curLink^.index > targetIndex)) and (createIfNExists) then
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