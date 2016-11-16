unit BigSet;

interface

uses
  LinkUtils;

type
  TBigSet = PSetLink;

//Создаёт пустое множество, возвращает указатель на него
function bsCreate: TBigSet;

//Включает элемент value во множество _bigSet
procedure bsInclude(var _bigSet: TBigSet; const value: integer);

//Проверяет value на принадлежность большому множеству _bigSet
function bsIsInSet(var _bigSet: TBigSet; const value: integer): boolean;


//Исключает элемент value из множества _bigSet
procedure bsExclude(var _bigSet: TBigSet; const value: integer);

//Возвращает пересечение множеств bigSet1 и bigSet2
function bsCombine(bigSet1, bigSet2: TBigSet): TBigSet;

implementation

uses Math;


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
  Проверяет value на принадлежность большому множеству _bigSet
}
function bsIsInSet(var _bigSet: TBigSet; const value: integer): boolean;
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

{
  Исключает элемент value из множества _bigSet
}
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

function bsCombine(bigSet1, bigSet2: TBigSet): TBigSet;
var
  primaryLink,
  secondaryLink,
  bufLink,
  resultTailLink: PSetLink;
begin
  //Если первый список пуст, возвращаем второй
  if (bigSet1 = nil) then
  begin
    result:= bigSet2;
    exit;
  end
  //Если второй список пуст, возвращаем первый
  else if (bigSet2 = nil) then
  begin
    result:= bigSet1;
    exit;
  end;

  //Иначе надо думать...
  result:= bsCreate();
  resultTailLink:= result;

  primaryLink:= bigSet1;
  secondaryLink:= bigSet2;

  //См. полное описание алгоритма чтобы понять это условие. Оно не такое простое, как кажется
  while primaryLink <> nil do
  begin
    //Идём до тех пор, пока не дойдём до конца, либо пока индекс текущего звена, не станет больше/равен, чем у побочного
    while (primaryLink <> nil) and (primaryLink^.index < secondaryLink^.index) do
    begin
      //Добавляем пройденное звено в результирующую цепочку
      bufLink:= _bsCreateLinkAfter(resultTailLink, primaryLink^.index);
      bufLink^.data:= primaryLink^.data;

      //Сдвигаем указатель на хвост результата
      resultTailLink:= bufLink;

      //Переходим к следующему звену
      primaryLink:= primaryLink^.next;
    end;

    //Внимание! Тут может быть досрочный выход из цикла
    //Опять же, см. полное описание алгоритма. Тут всё не так просто
    if primaryLink = nil then
    begin
      Continue;
    end;

    if primaryLink^.index = secondaryLink^.index then
    begin
      
    end;

    //Меняем текущий и побочный указатели
    bufLink:= primaryLink;
    primaryLink:= secondaryLink;
    secondaryLink:= bufLink;
  end;



  {
    Идём по двум цепочкам
    Но не просто идём

    Есть два указателя на текущее звено: для перой цепи и для второй
    Выставляем их в начала цепей соответственно

    Есть текущий указатель, есть побочный указатель
    Текущее звено - звено, на которое указывает текущий указатель
    Побочное звено - звено, на которое указывает побочный указатель
    Аналогично с индексами (текущий и побочный индекс)

    Исходно, за текущий возьмём указатель
    на первую цепь, за побочный - на вторую

    Двигаем текущий указатель пока индекс текущего звена, не станет
    больше/равен, чем у побочного. Короче, во время движения текущего
    указателя индекс текущего звена, должен быть меньше, чем у побочного.
    Во время движения добавляем пройденные звенья в результирующую цепочку.

    Если текущий индекс равен побочному, добавляем текущее звено в
    результирующую цепочку с текущим индексом и объединением двух маленьких
    множеств. Затем сдвигаем побочный указатель на 1 шаг вперёд.

    Меняем текущий и побочный указатели и повторяем всё это.
  }
end;

end.