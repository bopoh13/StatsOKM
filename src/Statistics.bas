Attribute VB_Name = "Statistics"
Option Explicit
Option Base 1
'12345678901234567890123456789012345bopoh13@ya67890123456789012345678901234567890

Public Const SUPP_LIST = "Список_Поставщиков", REV As Integer = &H1A4
' Внутреннее имя листа «Настройки», Внутреннее имя листа «Архив» и «Поставщики»
Public Const CONF = "CONF_", ARCH = "ARCH_", SUPP = "SUPP_"
Public Const PARTNEROFORM_LIST = "На входе,После проверки", _
  PARTYTYPE_LIST = "Исходная,Доработка", EXTRA_LIST = "$Новое,$Новое" _
  & " +Наши вопр.,$Согл. вопросы,$Наши вопросы,$Доработка,$Иное" ' rev.420
Public Const CONTROFORM_LIST = "станд.,опер.", SHEETS_ALL = "[OQS]?_"
Private Const PERSON_LIST = "Ф/Л,Ю/Л" ' Не менять! "*/Л,Ф/Л,Ю/Л"

' Рабочая книга, Рабочий лист, Архивная таблица
Public ThisWb As Workbook, cnfRenew As String, Get_Supp() As String
' Массив с изменениями о поставщике, Номер выделенной строки о поставщике
Public SuppDiff As Variant, SuppNumRow As Long, PartNumRow As Long

' Коллекция с настройками книги, Коллекция с именами листов
Public Settings As New Collection, Sh_List As New Collection
' Коллекция с ценами ОКМ для Ф/Л и Ю/Л, Имя рабочего листа/параметра, Счётчик
Private Cost As New Collection, cstPath As String, Counter As Integer

Private Sub Auto_Open() ' Автомакрос ' rev.300
Dim Conn As Object, Rec As Object, Src As String, mdwPath As String
Const MDW_PATH = "\Application Data\Microsoft\Access\System.mdw"
Const COST_PATH = "\Архив\Cost.accdb" ' Цены
  SettingsStatistics Cost ' Загрузка настроек книги в коллекцию rev.410
  PartNumRow = ActiveCell.Row ' Номер строки партии материалов
  
  ' Проверка существования директории с настройками rev.330
  Set Conn = CreateObject("Scripting.FileSystemObject") ' fso
  cstPath = Settings("SetPath") & COST_PATH
  If Not Conn.FileExists(cstPath) Then _
    ErrCollection 59, 1, 16, cstPath: Quit = True ' EPN = 1
  Debug.Print String(6, vbTab) & Settings("SetPath"): Set Conn = Nothing
  ' Создание системной таблицы, если она не существует
  Set Conn = CreateObject("Scripting.FileSystemObject") ' fso
  mdwPath = Environ("UserProfile") & MDW_PATH ' Полный путь к файлу
  Do While Not Conn.FileExists(mdwPath) ' Выполнять ПОКА нет файла
    mdwPath = Left(mdwPath, InStrRev(mdwPath, "\") - 1)
    Do Until Conn.FolderExists(mdwPath) ' Выполнять ДО того, как появится папка
      Do While Not Conn.FolderExists(mdwPath) ' Выполнять ПОКА нет папки
        Src = Right(mdwPath, Len(mdwPath) - InStrRev(mdwPath, "\"))
        mdwPath = Left(mdwPath, InStrRev(mdwPath, "\") - 1)
      Loop: Conn.GetFolder(mdwPath).SubFolders.Add Src ' Создать папку
      mdwPath = Environ("UserProfile") & MDW_PATH ' Полный путь к файлу
      mdwPath = Left(mdwPath, InStrRev(mdwPath, "\") - 1)
    Loop: mdwPath = Environ("UserProfile") & MDW_PATH ' Полный путь к файлу
    ByteArrayToSystemMdw mdwPath ' Создаём системную таблицу
  Loop: Set Conn = Nothing
  
  On Error Resume Next
    Set Conn = CreateObject("ADODB.Connection") ' Открываем Connection
    Conn.ConnectionTimeout = 5
    Conn.Mode = 1 ' 1 = adModeRead, 2 = adModeWrite, 3 = adModeReadWrite
    Src = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & cstPath & ";"
    'Src = Src & "Jet OLEDB:Engine Type=6;" ' Тип подключения
    Src = Src & "Jet OLEDB:Encrypt Database=True;"
    Src = Src & "Jet OLEDB:Database Password=" & Settings("CostPass") & ";"
    Src = Src & "Jet OLEDB:System database=" & mdwPath ' Системная таблица
    Conn.Open ConnectionString:=Src ', UserId:="admin", Password:=""
    If Err Then ErrCollection Err.Number, 1, 16, cstPath: Quit = True ' EPN = 1
  On Error GoTo 0
  
  Set Rec = CreateObject("ADODB.Recordset") ' Создаём RecordSet
  With Rec ' Загружаем Цены в коллекцию
    For Each SuppDiff In Split(PERSON_LIST, ",")
      cnfRenew = SuppDiff: Src = "SELECT Name FROM [MSysObjects] " _
        & "WHERE Flags = 0 AND Type = 1 AND Name LIKE '" & cnfRenew & "%' "
      .Open Source:=Src, ActiveConnection:=Conn
      On Error Resume Next
        SuppDiff = .GetRows(Rows:=-1): .Close: Src = Empty
        For Counter = LBound(SuppDiff, 2) To UBound(SuppDiff, 2) ' rev.410
          mdwPath = SuppDiff(LBound(SuppDiff, 1), Counter)
          'Src = Src & "SELECT * FROM [" & mdwPath & "]"
          Src = Src & "SELECT MID('" & mdwPath & "', 5) AS 'Имя Таблицы', " _
            & "Актуально, [Группа 0], [Группа 1], [Группа 2], [Группа А], " _
            & "[НУМ 0], [НУМ 1], [НУМ 2], [НАШ 1], [НАШ 2], Вопросы, ЮВО" _
            & IIf(cnfRenew = "Ф/Л", ", [Оф письма], Кодекс", "") _
            & " FROM [" & mdwPath & "]"
          ' !Последний UNION ALL - НЕ ВКЛЮЧАТЬ!
          If Counter < UBound(SuppDiff, 2) Then Src = Src & " UNION ALL "
        Next Counter: Src = Src & " ORDER BY 1 ASC, Актуально ASC"
        ' При открытии пустого объекта Recordset свойства BOF и EOF содержат True
        .Open Source:=Src, ActiveConnection:=Conn
        Cost.Add .GetRows(Rows:=-1), cnfRenew: .Close
        If Err.Number = 457 Or Err.Number = 3704 Then
          ErrCollection Err.Number, 1, 16, cnfRenew: Quit = True ' EPN = 1
        ElseIf Err.Number = 3021 Then
          Src = "SELECT 'стандарт' AS '0', " _
            & "#" & Format(Settings("date0"), "yyyy-mm-dd") & "# AS '1'"
          For Counter = 2 To .Fields.Count - 1
            Src = Src & ", " & IIf(Counter < 5, "-1", "NULL") _
              & " AS '" & Counter & "'"
          Next Counter: .Open Source:=Src, ActiveConnection:=Conn
          Cost.Add .GetRows(Rows:=-1), cnfRenew: .Close
        End If: Debug.Print String(6, vbTab) & cnfRenew & " - Err #" _
          & Err.Number; "; Fields "; .Fields.Count: cnfRenew = Empty ' rev.410
      On Error GoTo 0
    Next SuppDiff
  End With: Set Rec = Nothing: Set Conn = Nothing
  
  With ThisWb ' Активация, только если другой лист активен
    .Sheets(Sh_List("SF_")).Activate ' ВАЖНО! Уйти с листа «Поставщики»"
    For Each Conn In .Sheets
      If Conn.CodeName = CONF And Not IsEmpty(SuppDiff) _
      And Not .ReadOnly Then Settings.Remove "CostDate": Settings.Add SuppDiff, _
        "CostDate", After:="date0": UnprotectSheet(Conn).Range(CONF & "CostDate") = SuppDiff: SuppDiff = Empty ' rev.410
      ProtectSheet Conn ' ВАЖНО! Блокировать каждый лист rev.410
    Next Conn: .Saved = True ' Не сохранять rev.410
    Debug.Print String(3, vbTab) & "ЦЕНЫ - " & .Sheets(Sh_List(CONF)) _
      .Range(CONF & "CostDate"): cnfRenew = ActiveSheet.Name
  End With
End Sub

Public Function CostChanged() As Boolean ' Передаём SuppDiff rev.420
Dim Conn As Object, LastCostDate As Long
  Set Conn = CreateObject("Scripting.FileSystemObject") ' fso
  If Conn.FileExists(cstPath) Then LastCostDate = Mid(Log(Conn _
    .GetFile(cstPath).DateLastModified) - 10, 3, 8): Set Conn = Nothing
  If LastCostDate > 0 And Settings.Count > 0 Then ' rev.410
    ' Проверка изменения файла с ценами
    If LastCostDate <> Settings("CostDate") Then
      If Len(cnfRenew) > 0 And Settings("CostDate") > 0 Then ' rev.420
        MsgBox "CostChanged"
        If MsgBox("Внимание! Обновился файл ЦЕНЫ. Пересчитать статистику? ", _
          64 + 4, "Требуется обновление ") = vbYes Then Application _
          .ScreenUpdating = False: ThisWb.Sheets(Sh_List(1)).Activate: _
          Auto_Open: Application.ScreenUpdating = True: ThisWb.Saved = False
        Exit Function
      End If: CostChanged = True
    End If: SuppDiff = LastCostDate
  End If
End Function

' Обновление формул на всех листах или в текущей строке
Public Sub CostUpdate(Optional ByVal Supplier As String = "*") ' rev.380
Dim App_Sh As Worksheet, RecRows As Integer, Item As Integer, Rec() As Variant
Dim TEMP_COUNT As Long ' ВРЕМЕННО
  With ThisWb.Sheets(GetSheetIndex(ARCH)) ' Поставщики из архива
    If Not (Not Not Get_Supp) > 0 Then
      ReDim Get_Supp(15, .UsedRange.Rows.Count) ' ВАЖНО! Последняя запись Empty
      For RecRows = LBound(Get_Supp, 1) To UBound(Get_Supp, 1)
        For Counter = LBound(Get_Supp, 2) To UBound(Get_Supp, 2)
          Get_Supp(RecRows, Counter) = .Cells(Counter + 1, RecRows) ' Костыль (1 = должен быть Settings("head"))
      Next Counter, RecRows: Get_Supp(15, Counter - 1) = Date ' ВАЖНО! Заполняем последнюю запись
    End If: cnfRenew = .Name ' ВАЖНО! Передаём имя листа
  End With: If Not Len(Supplier) > 1 Then PartNumRow = 1 + 1 ' Количество строк ' Костыль (1 = должен быть Settings("head"))
  
  For Each App_Sh In ThisWb.Sheets ' Процедура пересчёта итоговых сумм
''    If App_Sh.CodeName Like SHEETS_ALL And Supplier = "*" Then ' Зачем сравнивать с ActiveSheet.CodeName? rev.410

    'If App_Sh.CodeName Like SHEETS_ALL And Supplier = "*" _
    Or App_Sh.CodeName = ActiveSheet.CodeName Then ' rev.390
    If App_Sh.CodeName Like SHEETS_ALL And (Supplier = "*" _
    Or App_Sh.CodeName = ActiveSheet.CodeName) Then ' rev.410
    
If Not App_Sh.CodeName Like SHEETS_ALL Then MsgBox "CostUpdate для " & App_Sh.CodeName ' ВАЖНО! Проверка без SUPP_
      With UnprotectSheet(App_Sh) ' rev.380
        '.Activate ' НЕ ПРИМЕНЯТЬ Захват строки rev.410
        If Len(Supplier) > 1 Then RecRows = 1 Else RecRows = .UsedRange.Rows.Count - 1 ' Количество строк ' Костыль (1 = должен быть Settings("head"))
        If RecRows > 0 Then ' Если есть записи
'          Stop
          
          Application.StatusBar = "Пожалуйста, подождите. " & IIf(RecRows > 1, _
            "Идёт обновление цен...", "Обновление цен в строке #" & PartNumRow)
'          Debug.Print PartNumRow; " "; ActiveCell.Row: Stop
          Rec = .Cells(PartNumRow, 1).Resize(RecRows, 51).FormulaR1C1 ' rev.390
          For Item = LBound(Rec, 1) To UBound(Rec, 1)
            If GetSuppRow(Rec(Item, 5), IIf(.CodeName = "OE_", Date, CDate(Val(Rec(Item, 6))))) _
            And Rec(Item, 5) Like Supplier Then  ' Поиск строки SuppNumRow у поставщика rev.420
              Debug.Print SuppNumRow ' Поиск строки SuppNumRow у поставщика
              Rec(Item, 2) = "='" & cnfRenew & "'!R" & SuppNumRow & "C4"
              Rec(Item, 3) = "='" & cnfRenew & "'!R" & SuppNumRow & "C5"
              Rec(Item, 4) = "='" & cnfRenew & "'!R" & SuppNumRow & "C8"
              
              Select Case .CodeName ' Создание формул для записи rev.390
                Case "SB_", "SF_"
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")"
                  
                  Rec(Item, 30) = "=SUM(RC26:RC28)"
                  Rec(Item, 34) = "=SUM(RC31:RC33)"
                  ' НУМ Rec(1, 44) = "=SUM(RC40:RC43)"
                  Rec(Item, 48) = "=IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""НДС"",(RC46+RC47)*0.18,IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""УСН"",""без НДС"",""""))"
                  Rec(Item, 49) = "=SUM(RC46:RC48)"
                Case "OU_", "QB_" ' rev.410
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")" ' Заменить на Поступление в ДОАМ
                  
                  Rec(Item, 29) = "=IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""НДС"",(RC27+RC28)*0.18,IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""УСН"",""без НДС"",""""))"
                  If .CodeName = "QB_" Then Rec(Item, 26) = "=SUM(RC24:RC25)"
                  
                  Rec(Item, 30) = "=SUM(RC27:RC29)"
                Case "OE_" ' rev.410
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")"
                  
                  Rec(Item, 17) = "=IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""НДС"",(RC15+RC16)*0.18,IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""УСН"",""без НДС"",""""))"
                  Rec(Item, 18) = "=SUM(RC15:RC17)"
                Case "QT_" ' rev.410
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")"
                  Rec(Item, 26) = "=SUM(RC24:RC25)"
                Case "SL_" ' rev.410
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")" ' Заменить на Поступление в ДОАМ
                  
                  Rec(Item, 26) = "=IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""НДС"",(RC24+RC25)*0.18,IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""УСН"",""без НДС"",""""))"
                  Rec(Item, 27) = "=SUM(RC24:RC26)"
                Case "SR_" ' rev.410
                  Rec(Item, 1) = "=TEXT(RC6,""ММММ.ГГ"")" ' Заменить на Поступление в ДОАМ
                  
                  Rec(Item, 23) = "=IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""НДС"",(RC21+RC22)*0.18,IF('" & cnfRenew & "'!R" & SuppNumRow & "C12=""УСН"",""без НДС"",""""))"
                  Rec(Item, 24) = "=SUM(RC21:RC23)"
              End Select
            Else
'              Stop ' Изменить?
              For Counter = LBound(Rec, 2) To UBound(Rec, 2)
                If InStr(Rec(Item, Counter), "=") > 0 Then _
                  Rec(Item, Counter) = Empty ' Удаляем формулы
              Next Counter
            End If: Select Case .CodeName ' ВРЕМЕННО rev.410
              Case "SB_", "SF_": TEMP_COUNT = 46
              Case "OU_", "QB_": TEMP_COUNT = 27
              Case "SL_": TEMP_COUNT = 24
              Case "SR_": TEMP_COUNT = 21
            End Select
            ' Через функцию GetCost перемнная cnfRenew принимает PERSON_LIST
            If .CodeName Like SHEETS_ALL Xor .CodeName = "OE_" _
            Xor .CodeName = "QT_" Then _
              Rec(Item, TEMP_COUNT) = GetCosts(Rec(Item, 5), Rec(Item, 6), _
                .CodeName, IIf(RecRows > 1, False, True)) ' Костыль rev.410
          Next Item

          Debug.Print "Строка - "; .Cells(PartNumRow, 1).Resize(UBound(Rec, 1)).Address
          
          .Cells(PartNumRow, 2).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          If .CodeName = "OE_" Then ' rev.410
            .Cells(PartNumRow, 7).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 9).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          ElseIf .CodeName = "QB_" Then
            .Cells(PartNumRow, 13).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 15).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 16).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          ElseIf .CodeName = "SL_" Then
            .Cells(PartNumRow, 14).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 16).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 17).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          ElseIf .CodeName = "SR_" Then
            .Cells(PartNumRow, 11).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 12).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 14).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          Else
            .Cells(PartNumRow, 16).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 18).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
            .Cells(PartNumRow, 19).Resize(UBound(Rec, 1)).NumberFormat = "General" ' Костыль
          End If
                      
          'If CDate(Val(Rec(Item - 1, 6))) >= Settings("date0") _
          And Len(Rec(Item - 1, 6)) > 0 And Not App_Sh.FilterMode Then
          If Not .FilterMode Then _
            .Cells(PartNumRow, 1).Resize(UBound(Rec, 1), UBound(Rec, 2)) _
            .FormulaR1C1 = Rec Else .Cells(PartNumRow, TEMP_COUNT) _
            .FormulaR1C1 = Rec(RecRows, TEMP_COUNT) ' Проблема с Автофильтром rev.410
        End If
      End With: ProtectSheet App_Sh
      If Len(Supplier) > 1 And SuppNumRow = 0 Then ' Если одна запись rev.380
        UnprotectSheet(ThisWb.Sheets(Sh_List(CONF))) _
          .Range(CONF & "CostDate") = 0
        ProtectSheet ThisWb.Sheets(Sh_List(CONF)): Exit For
      End If: If Len(Supplier) > 1 Then Exit For ' rev.420
    End If
  Next App_Sh: Application.StatusBar = False ' Erase Get_Supp
End Sub

' Установка рабочей конфигурации листов
Public Sub SpecificationSheets(ByVal SheetIndex As Byte) ' rev.300
Dim App_Sh As Worksheet, LastRow As Long, PreError As Variant ' rev.380
  On Error GoTo DataExit ' rev.350
    Debug.Print SheetIndex; " "; cnfRenew ' rev.410
    'Stop ' #3 Копирование заголовка, Установка условного форматирования
    
    For Each App_Sh In ThisWb.Sheets
      Application.EnableEvents = False ' ВЫКЛ События rev.400
      Application.ScreenUpdating = False ' ВЫКЛ Обновление экрана
      With UnprotectSheet(ThisWb.Sheets(App_Sh.Index))
        PreError = 0: .Activate ': UnprotectSheet App_Sh
        With ActiveWindow ' CTRL+HOME
          .ScrollRow = 1: .ScrollColumn = 1: .FreezePanes = False
        End With
        
        LastRow = App_Sh.UsedRange.Rows.Count ' Количество строк rev.330
        ' Очистка форматов, Очистка условного форматирования
        .Cells.ClearFormats: .Cells.FormatConditions.Delete
        ' Очистка группировки, Очистка проверки данных
        .Cells.ClearOutline: .Cells.Validation.Delete
        ' Очистка границы ячеек
        For Each PreError In Array(xlDiagonalDown, xlDiagonalUp, _
          xlEdgeLeft, xlEdgeTop, xlEdgeBottom, xlEdgeRight, _
          xlInsideVertical, xlInsideHorizontal)
          .Cells.Borders(PreError).LineStyle = xlNone
        Next PreError
        
'''        Debug.Print "Обработка " & .CodeName: Stop
        Select Case .CodeName
          Case SUPP, ARCH ' Лист «Поставщики», «Архив»
            If .CodeName = ARCH Then ThisWb.Sheets(Sh_List(SUPP)) _
              .Range("A1:O1").Copy Destination:=.Range("A1")
              'SendKeys "^{HOME}", False ' rev.250 Фокус должен быть на MS Excel
              '.Cells(1, 1).AutoFilter
            .Tab.ColorIndex = -4142: LastRow = LastRow + 8 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Columns("C:I").Columns.Group: .Columns("F:G").Columns.Group
            If .CodeName = SUPP Then
              .Columns("A:AB").Locked = False: .Rows("1:1").Locked = True
              .Columns("P:X").Columns.Group ' rev.380
            End If
            '.Outline.ShowLevels ColumnLevels:=2 ' rev.420
            
            ' Форматирование колонок
            .Columns("C:D").NumberFormat = "@" ' rev.400
            .Columns("O:O").NumberFormat = "m/d/yyyy"
            If .CodeName = SUPP Then
              .Range("A1:AB1").WrapText = True ' rev.340
              .Columns("Q:Q").NumberFormat = "m/d/yyyy"
              .Columns("R:R").NumberFormat = "[$-419]"".+. (""0000"") "";@"
              .Columns("V:V").NumberFormat = "[$-419]000-000-000-00;@"
              .Columns("W:W").NumberFormat = _
                "[<=9999999999]#000000000;#00000000000;@" ' rev.370
              .Columns("X:X").NumberFormat = "[$-419]000000000;@"
              .Columns("AA:AA").NumberFormat = "@"
            End If
            ' Границы таблицы rev.360
            With .Range("N:N,O:O").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 10, 15 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              With .Range("A2:A" & LastRow & ",D2:E" & LastRow & ",K2:L" & LastRow).FormatConditions _
                .Add(Type:=xlBlanksCondition) ' rev.420
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("D2:D" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2=""РИЦ"";$D2>""999"")")
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.350
              End With
              With .Range("C2:C" & LastRow).FormatConditions _
                .Add(Type:=xlBlanksCondition)
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              ' Поставщик (кратко)
              With .Range("J2:J" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(НЕ(ЕПУСТО($J2));ИЛИ(" _
                  & "ЕПУСТО($A2);ЕПУСТО($K2);ЕСЛИ($A2=""Ю/Л"";ЕПУСТО($L2))))")
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              With .Range("A2:Z" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=ЕПУСТО($J2)") ' rev.420
                .StopIfTrue = True: .SetFirstPriority
              End With
              If .CodeName = SUPP Then
                With .Range("A2:A" & LastRow & ",J2:J" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, Formula1:="=И(НЕ(ЕПУСТО(СМЕЩ($J2;-1;" _
                    & "0)));ЕПУСТО($J2))") ' rev.420
                  .Interior.ColorIndex = 44: .StopIfTrue = True: .SetFirstPriority
                End With
                ' ИНН
                With .Range("W2:W" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, Formula1:="=ИЛИ(ЕСЛИ(НЕ(ЕЧИСЛО($W2));" _
                    & "1;ЦЕЛОЕ($W2)<>$W2);ИЛИ(И($A2=""Ф/Л"";ИЛИ(ДЛСТР($W2)<11;ДЛСТР($W2)>12)));" _
                    & "И($A2=""Ю/Л"";ИЛИ(ДЛСТР($W2)<9;ДЛСТР($W2)>10)))")
                  .Interior.ColorIndex = 44: .StopIfTrue = True
                End With
                .Range("L2:AB" & LastRow).FormatConditions.Add Type:=xlNoBlanksCondition ' rev.410
                With .Range("N2:N" & LastRow & ",U2:U" & LastRow & ",Z2:Z" & LastRow).FormatConditions _
                  .Add(Type:=xlBlanksCondition) ' rev.360
                  .Interior.ColorIndex = 36: .StopIfTrue = True
                End With
                With .Range("Q2:Q" & LastRow & ",T2:T" & LastRow & ",V2:V" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, Formula1:="=$A2=""Ф/Л""")
                  .Interior.ColorIndex = 36: .StopIfTrue = True
                End With
                With .Range("L2:M" & LastRow & ",P2:P" & LastRow & ",X2:X" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, Formula1:="=$A2=""Ю/Л""") ' rev.410
                  .Interior.ColorIndex = 36: .StopIfTrue = True
                End With
              End If
              If .CodeName = ARCH Then ' rev.380
                With .Range("A2:O" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, Formula1:="=ЕПУСТО($J2)+МАКС(--(" _
                    & "$J2:$J" & LastRow & "=$J2)*$O2:$O" & LastRow & ")=$O2")
                  .Interior.ColorIndex = 43: .StopIfTrue = True
                  '.SetFirstPriority
                End With
                With .Range("A2:O" & LastRow).FormatConditions _
                  .Add(Type:=xlExpression, _
                    Formula1:="=И($O2>СЕГОДНЯ()-90;НЕ(ЕПУСТО($J2)))") ' rev.360
                  .Interior.ColorIndex = 27: .StopIfTrue = True
                  '.SetFirstPriority
                End With
              End If
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            If .CodeName = SUPP Then
              With .Range("J2:J" & LastRow).Validation ' rev.370
                .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                  Formula1:="=COUNTIF($J:$J,$J2)<=1"
                .ErrorTitle = "Поставщик (кратко)"
                .ErrorMessage = "Поставщик уже существует. Добавление " _
                  & "дубликата записи не требуется "
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("A2:A" & LastRow).Validation
                .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
                  Formula1:=PERSON_LIST
                .ErrorTitle = "Вид лица"
                .ErrorMessage = "Необходимо выбрать значение из списка "
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("D2:D" & LastRow).Validation
                .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                  Formula1:="=OR(AND($D2>=""001"",$D2<=""999"",LEN($D2)<4)," _
                  & "$D2=""станд."",$D2=""ДПР"")"
                .ErrorTitle = "Источник"
                .ErrorMessage = "Необходимо ввести 3-х значный номер РИЦа, " _
                  & "либо указать источник ""ДПР"" или ""станд."""
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("E2:E" & LastRow).Validation
                .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
                  Formula1:="Коммерч.,Некоммерч.,Ведомство," _
                  & "Ведомство (без подп.),РИЦ,Собств. источники КЦ" ' rev.360
                .ErrorTitle = "Тип организации"
                .ErrorMessage = "Необходимо выбрать значение из списка "
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("O2:O" & LastRow).Validation ' rev.380
                .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                  Operator:=xlGreaterEqual, Formula1:=Settings("date0")
                .ErrorTitle = "Дата актуальности"
                .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("L2:L" & LastRow).Validation ' rev.360
                .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
                  Formula1:="НДС,УСН"
                .ErrorTitle = "НДС / УСН"
                .ErrorMessage = "Необходимо выбрать значение из списка "
              End With
              With .Range("Q2:Q" & LastRow).Validation ' rev.380
                .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                  Operator:=xlGreaterEqual, Formula1:=DateAdd( _
                  "m", -840, Settings("date0"))
                .ErrorTitle = "Дата рождения"
                .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("R2:R" & LastRow).Validation ' rev.380
                .Add Type:=xlValidateWholeNumber, AlertStyle:=xlValidAlertStop, _
                  Operator:=xlGreaterEqual, Formula1:=DatePart( _
                  "yyyy", Settings("date0"))
                .ErrorTitle = "Заявление о проф. вычете"
                .ErrorMessage = "Необходимо ввести год не меньше " & .Formula1
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("V2:V" & LastRow).Validation
                .Add Type:=xlValidateWholeNumber, AlertStyle:=xlValidAlertStop, _
                  Operator:=xlBetween, Formula1:="100000000", _
                  Formula2:="99999999999"
                .ErrorTitle = "СНИЛС"
                .ErrorMessage = "Страховой номер в пенсионном фонде должен " _
                  & "содержать от 9 до 11 цифр "
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("W2:W" & LastRow).Validation ' ИНН
                .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                  Formula1:="=OR(AND($A2=""Ф/Л"",LEN($W2)>10,LEN($W2)<13)," _
                  & "AND($A2=""Ю/Л"",LEN($W2)>8,LEN($W2)<11))" ' rev.420
                .ErrorTitle = "ИНН"
                .ErrorMessage = "Идентификационный номер налогоплательщика " _
                  & "должен содержать: " & vbCrLf & vbTab & "для Ф/Л  от 11 " _
                  & "до 12 цифр" & vbCrLf & vbTab & "для Ю/Л  от 9 до 10 цифр"
                .ShowError = True: .IgnoreBlank = True
              End With
              With .Range("X2:X" & LastRow).Validation
                .Add Type:=xlValidateWholeNumber, AlertStyle:=xlValidAlertStop, _
                  Operator:=xlBetween, Formula1:="10000000", Formula2:="999999999"
                .ErrorTitle = "КПП"
                .ErrorMessage = "Код причины постановки должен " _
                  & "содержать от 8 до 9 цифр "
                .ShowError = True: .IgnoreBlank = True
              End With
              ' Список «Категория цены» для Поставщика
              'ListCost Sh_List(SUPP), 1 ' ОТМЕНИТЬ ПОВТОРНОЕ СОЗДАНИЕ СПИСКА
            End If
            
            If .CodeName = SUPP Then ' Закрепление области rev.350
              .Range("K2").Select: ActiveWindow.FreezePanes = True
            End If
          Case "OE_" ' rev.410
            .Tab.ColorIndex = -4142: LastRow = LastRow + 9 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:S1").WrapText = True
            .Columns("E:P").Locked = False: .Columns("S").Locked = False
            .Rows("1:1").Locked = True: .Columns("B:D").Columns.Group
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@"
            .Columns("S:S").NumberFormat = "@"
            With .Columns("M:R")
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:M")
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("G:G,I:I").NumberFormat = "@"
            ' Границы таблицы
            With .Range("D:D,N:N").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("M:M,O:O,R:R").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 11 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              With .Range("F2:F" & LastRow & ",H2:H" & LastRow & ",J2:M" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              
              With .Range("K:K").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(J1<СЕГОДНЯ()-ЕСЛИОШИБКА(ВЫБОР(ПОИСКПОЗ(ИНДЕКС($1:$1;1;СТОЛБЕЦ());K1:K1;0);30;9);14);J1<>"""";K1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True
              End With
            End If
            
            ' Закрепление области
            .Range("F2").Select: ActiveWindow.FreezePanes = True
          Case "SB_", "SF_"
            .Tab.ColorIndex = IIf(.CodeName = "SF_", 24, 37): LastRow = LastRow + 99 ' rev.420
              'SendKeys "^{HOME}", False ' rev.250 Фокус должен быть на MS Excel
              '.Cells(1, 1).AutoFilter
              
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:AY1").WrapText = True ' rev.390
            .Columns("E:I").Locked = False: .Columns("K:R").Locked = False
            '.Columns("T:AA").Locked = False ' rev.330
            .Columns("T:AC").Locked = False: .Columns("AE:AG").Locked = False ' rev.390
            .Columns("AI:AS").Locked = False: .Columns("AU").Locked = False ' rev.390
            .Columns("AX:AY").Locked = False: .Rows("1:1").Locked = True ' rev.390
            .Columns("B:D").Columns.Group: .Columns("I:S").Columns.Group ' rev.340
            .Columns("Z:AC").Columns.Group: .Columns("AE:AG").Columns.Group ' rev.390
            '.Columns("AG:AQ").Columns.Group: .Columns("AL:AO").Columns.Group
            .Columns("AI:AS").Columns.Group: .Columns("AI").Columns.Group ' rev.420
            .Columns("AN:AQ").Columns.Group
            '.Outline.ShowLevels ColumnLevels:=2 ' rev.420
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@" ' rev.340
            .Columns("AY:AY").NumberFormat = "@" ' rev.390
            With .Columns("X:AW") ' rev.390
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:X") ' rev.350
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("P:P,R:R,S:S").NumberFormat = "@" ' rev.350
            ' Границы таблицы rev.390
            With .Range("D:D,Y:Y,AB:AB,AC:AC,AG:AG,AK:AK,AM:AM,AR:AR") _
              .Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("X:X,AD:AD,AH:AH,AS:AS,AT:AT,AW:AW") _
              .Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 6, 7 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              ' Ошибка «Дата актуальности» или отсутствие цены в массиве Cost
              With .Range("A:AY").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$AT1<0") ' rev.400
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              .Range("Q:Q").FormatConditions.Add Type:=xlExpression, Formula1:="=И($Q1=39500;$R1=""СМИ-ГК-08"")" ' Костыль rev.380
              With .Range("F2:O" & LastRow & ",Q2:Q" & LastRow & ",T2:X" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")") ' rev.390
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("F2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$F$2:$F" & LastRow & ";$F2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.360
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 45: .StopIfTrue = True ' rev.360
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2<>"""";$G2="""";$Y2<>"""")") ' rev.390
                .Interior.ColorIndex = 44: .StopIfTrue = True ' rev.380
              End With
              With .Range("H2:H" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($H2="""";$S2=""" & Right(CONTROFORM_LIST, InStrRev(CONTROFORM_LIST, ",") - 2) & """)") ' rev.420
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("K:X").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$X1=""не оплач.""") ' Перемещено rev.380
                .Interior.ColorIndex = 48: .StopIfTrue = True
              End With
              
              ' ВЫБОР(ПОИСКПОЗ(СТОЛБЕЦ();$BA$1:$BC$1;0);30;9;14) = ЕСЛИОШИБКА(ВЫБОР(ПОИСКПОЗ(ИНДЕКС($1:$1;1;СТОЛБЕЦ());K1:L1;0);30;9);14)
              With .Range("K:L,V:V").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(J1<СЕГОДНЯ()-ЕСЛИОШИБКА(ВЫБОР(ПОИСКПОЗ(ИНДЕКС($1:$1;1;СТОЛБЕЦ());K1:L1;0);30;9);14);J1<>"""";K1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True ' rev.360
              End With
              ' Согласование было перемещено выше rev.360
              With .Range("M:N").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(L1>0;M1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$X1<>""""")
                .StopIfTrue = True ' Без цвета
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$U1<>""""")
                .Interior.ColorIndex = 43: .StopIfTrue = True
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($O1:$T1)>0;$N1="""")")
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.360
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$L1<>""""")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("Y:AS").FormatConditions _
                .Add(Type:=xlCellValue, Operator:=xlLess, Formula1:="=0") ' rev.390
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.360
              End With
              With .Range("Y2:Y" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2<>"""";$G2<>"""";$Y2="""")") ' rev.390
                .Interior.ColorIndex = 44: .StopIfTrue = True ' rev.420
              End With
              With .Range("Y2:AC" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($Z2:$AB2)>2;СУММ($Z2:$AC2)<>$Y2)") ' rev.390
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.360
              End With
              With .Range("Z2:AB" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($Z2:$AB2)<3;$Y2>0)") ' Изменено rev.390
                .Interior.ColorIndex = 44: .StopIfTrue = True ' rev.360
              End With
              With .Range("AE2:AH" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=ИЛИ(И(СЧЁТЗ($AE2:$AG2)>2;СУММ($AE2:$AG2)<>$AH2);$AH2>$Y2)") ' rev.410
                .Interior.ColorIndex = 3: .StopIfTrue = True ' rev.360
              End With
              With .Range("AE2:AG" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($AE2:$AG2)<3;СЧЁТЗ($Z2:$AB2)>2)") ' rev.390
                .Interior.ColorIndex = 44: .StopIfTrue = True ' rev.360
              End With
              With .Range("AN2:AR" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СУММ($AN2:$AQ2)<>$AR2") ' rev.390
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("AI2:AM" & LastRow & ",AS2:AT" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=ИЛИ(СУММ($AI2:$AM2)<>ЕСЛИ($AS2>0;0;СУММ(ЕСЛИ(ЕЧИСЛО(ПОИСК(""Наши вопр"";$AX2));$AL2:$AM2;$AI2:$AK2)));ЕСЛИ($AS2>0;$AH2<>$AS2;И(СЧЁТЗ($AE2:$AG2)>2;$AH2<>СУММ($AI2:$AM2))))") ' rev.400
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              
              'With .Range("E2:F" & LastRow & ",Y2:Y" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=НАЙТИ(""Переходящие из"";$AY2)") ' rev.410
              '  .Interior.ColorIndex = 35: .StopIfTrue = False
              'End With
              ' Переходящие материалы, Срочно Наши вопросы, Кодекс rev.390
              If .CodeName = "SF_" Then cnfRenew = Replace(cnfRenew, "КФ", "БО") _
              Else cnfRenew = Replace(cnfRenew, "БО", "КФ")
              Counter = ThisWb.Sheets(cnfRenew).UsedRange.Rows.Count ' rev.390
              With .Range("E2:F" & LastRow & ",AC2:AC" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(E2<>"""";$J2<>"""";ДВССЫЛ(""'" & cnfRenew & "'!$J$""&ПОИСКПОЗ($G2;--('" & cnfRenew & "'!$E$2:$E$" & Counter & "=$E2)*--('" & cnfRenew & "'!$F$2:$F$" & Counter & "=$F2)*'" & cnfRenew & "'!$G$2:$G$" & Counter & ";0))>$J2)") ' rev.410 Formula1:="=И(E2<>"""";СУММ($AC2:$AC2)>0)") rev.390
                .Interior.ColorIndex = 35: .StopIfTrue = False
              End With
              With .Range("E2:F" & LastRow & ",AL2:AM" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$AX2=""Срочно Наши вопросы""")
                .Interior.ColorIndex = 37: .StopIfTrue = False
              End With
              With .Range("E2:F" & LastRow & ",AS2:AS" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(E2<>"""";$AS2>0)")
                .Interior.ColorIndex = 40: .StopIfTrue = False
              End With
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            With .Range("F2:F" & LastRow).Validation ' rev.380
              .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                Operator:=xlGreaterEqual, Formula1:=Settings("date0")
              .ErrorTitle = "Дата поступления в ДОАМ"
              .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
              .ShowError = True: .IgnoreBlank = True
            End With
            With .Range("X2:X" & LastRow).Validation
              .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                Formula1:="=OR($X2=""не оплач."",AND($X2>$F2,ISNUMBER($X2)))"
              .ErrorTitle = "Дата перечислений"
              .ErrorMessage = "Необходимо ввести дату больше " _
                & """Даты поступления в ДОАМ"""
              .ShowError = True: .IgnoreBlank = True
            End With
            'With
            '  .NumberFormat = "#,##0"
            '  .HorizontalAlignment = xlRight
            '  .IndentLevel = 1
            'End With
            
            ' Закрепление области
            .Range("G2").Select: ActiveWindow.FreezePanes = True
          Case "OU_" ' rev.410
            .Tab.ColorIndex = 38: LastRow = LastRow + 99 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:AF1").WrapText = True
            .Columns("E:Z").Locked = False: .Columns("AB").Locked = False
            .Columns("AE:AF").Locked = False: .Rows("1:1").Locked = True
            .Columns("B:D").Columns.Group: .Columns("I:T").Columns.Group
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@"
            .Columns("AF:AF").NumberFormat = "@"
            With .Columns("X:AD")
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:X")
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("P:P,R:R,S:S").NumberFormat = "@"
            ' Границы таблицы
            With .Range("D:D,Y:Y").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("X:X,Z:Z,AA:AA,AD:AD").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 6 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              ' Ошибка "Дата актуальности" или отсуствие цены в массиве Cost
              With .Range("A:AF").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$AA1<0")
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              With .Range("F2:O" & LastRow & ",Q2:Q" & LastRow & ",T2:X" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("J:X").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$X1=""не оплач.""")
                .Interior.ColorIndex = 48: .StopIfTrue = True
              End With
              
              With .Range("I:I").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($I1<СЕГОДНЯ()-14;$I1<>"""";$J1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True ' rev.420
              End With
              With .Range("M:N").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(L1>0;M1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True
              End With
              With .Range("V:V").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($U1<СЕГОДНЯ()-14;$U1<>"""";$V1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True ' rev.420
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$X1<>""""")
                .StopIfTrue = True ' Без цвета
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$U1<>""""")
                .Interior.ColorIndex = 43: .StopIfTrue = True
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($O1:$T1)>0;$N1="""")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("O:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$L1<>""""")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("Y:Z").FormatConditions _
                .Add(Type:=xlCellValue, Operator:=xlLess, Formula1:="=0")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("Z2:Z" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$Z2>$Y2")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            With .Range("F2:F" & LastRow).Validation
              .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                Operator:=xlGreaterEqual, Formula1:=Settings("date0")
              .ErrorTitle = "Дата получения задания от ДКБ"
              .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
              .ShowError = True: .IgnoreBlank = True
            End With
            With .Range("X2:X" & LastRow).Validation
              .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                Formula1:="=OR($X2=""не оплач."",AND($X2>$F2,ISNUMBER($X2)))"
              .ErrorTitle = "Дата перечислений"
              .ErrorMessage = "Необходимо ввести дату больше " _
                & """Даты получения задания от ДКБ"""
              .ShowError = True: .IgnoreBlank = True
            End With
            
            ' Закрепление области
            .Range("G2").Select: ActiveWindow.FreezePanes = True
          Case "QB_", "QT_" ' rev.410
            .Tab.ColorIndex = IIf(.CodeName = "QB_", 36, 40): LastRow = LastRow + 99 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:AF1").WrapText = True
            .Columns("E:G").Locked = False: .Columns("I:I").Locked = False ' rev.420
            .Columns("K:V").Locked = False: .Columns("W:Y").Locked = False ' rev.420
            .Columns("AB").Locked = False: .Columns("AE:AF").Locked = False
            .Rows("1:1").Locked = True
            .Columns("B:D").Columns.Group: .Columns("H:P").Columns.Group ' rev.410
            .Columns("U:V").Columns.Group: .Columns("X:Y").Columns.Group
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@"
            .Columns(IIf(.CodeName = "QB_", "AF:AF", "AF:AF")).NumberFormat = "@"
            With .Columns("T:AD")
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:T")
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("M:M,O:P").NumberFormat = "@"
            ' Границы таблицы
            With .Range("D:D,U:U,X:X").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("T:T,V:V,W:W,Y:Y,Z:Z,AA:AA,AD:AD").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 6, 7 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              ' Ошибка "Дата актуальности" или отсуствие цены в массиве Cost
              With .Range("A:AF").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$AA1<0")
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              With .Range("F2:L" & LastRow & ",N2:N" & LastRow & ",Q2:T" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("F2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$F$2:$F" & LastRow & ";$F2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 45: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2<>"""";$G2="""";$W2>0)")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("L:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$T1=""не оплач.""")
                .Interior.ColorIndex = 48: .StopIfTrue = True
              End With
              
              With .Range("R:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(Q1<СЕГОДНЯ()-ЕСЛИОШИБКА(ВЫБОР(ПОИСКПОЗ(ИНДЕКС($1:$1;1;СТОЛБЕЦ());R1:R1;0);30;9);14);Q1<>"""";R1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True ' rev.360
              End With
              With .Range("L:P").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$T1<>""""")
                .StopIfTrue = True ' Без цвета
              End With
              With .Range("L:P").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$Q1<>""""")
                .Interior.ColorIndex = 43: .StopIfTrue = True
              End With
              With .Range("L:P").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=ИЛИ($I1<>"""";$K1<>"""")")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("U:Z").FormatConditions _
                .Add(Type:=xlCellValue, Operator:=xlLess, Formula1:="=0")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              
              ' УПРОСТИТЬ
              With .Range("U2:W" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($U2:$V2)>1;СУММ($U2:$V2)<>$W2)")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("U2:V" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($U2:$V2)<2;$W2>0)")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("X2:Z" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=ИЛИ(И(СЧЁТЗ($X2:$Y2)>1;СУММ($X2:$Y2)<>$Z2);$Z2>$W2)")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("X2:Y" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($X2:$Y2)<2;СЧЁТЗ($U2:$V2)>1)")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            With .Range("F2:F" & LastRow).Validation
              .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                Operator:=xlGreaterEqual, Formula1:=Settings("date0")
              .ErrorTitle = "Дата поступления в ДОАМ"
              .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
              .ShowError = True: .IgnoreBlank = True
            End With
            With .Range("T2:T" & LastRow).Validation
              .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                Formula1:="=OR($T2=""не оплач."",AND($T2>$F2,ISNUMBER($T2)))"
              .ErrorTitle = "Дата перечислений"
              .ErrorMessage = "Необходимо ввести дату больше " _
                & """Даты поступления в ДОАМ"""
              .ShowError = True: .IgnoreBlank = True
            End With
            
            ' Закрепление области
            .Range("G2").Select: ActiveWindow.FreezePanes = True
          Case "SL_" ' rev.410
            .Tab.ColorIndex = 35: LastRow = LastRow + 99 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:AB1").WrapText = True
            .Columns("E:W").Locked = False
            .Columns("Y").Locked = False: .Columns("AB").Locked = False
            .Rows("1:1").Locked = True
            .Columns("B:D").Columns.Group: .Columns("H:Q").Columns.Group
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@"
            .Columns("AB:AB").NumberFormat = "@"
            With .Columns("U:AA")
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:U")
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("N:N,P:Q").NumberFormat = "@"
            ' Границы таблицы
            With .Range("D:D,V:V").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("U:U,W:W,X:X,AA:AA").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 6, 7 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              With .Range("A:AB").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$X1<0")
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              With .Range("F2:M" & LastRow & ",O2:O" & LastRow & ",R2:U" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("F2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$F$2:$F" & LastRow & ";$F2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 45: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2<>"""";$G2="""";$V2<>"""")")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("I:U").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$U1=""не оплач.""")
                .Interior.ColorIndex = 48: .StopIfTrue = True
              End With
              
              With .Range("I:J,T:T").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(H1<СЕГОДНЯ()-ЕСЛИОШИБКА(ВЫБОР(ПОИСКПОЗ(ИНДЕКС($1:$1;1;СТОЛБЕЦ());I1:J1;0);30;9);14);H1<>"""";I1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True
              End With
              With .Range("K:L").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(J1>0;K1="""")")
                .Interior.ColorIndex = 38: .StopIfTrue = True
              End With
              With .Range("M:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$U1<>""""")
                .StopIfTrue = True ' Без цвета
              End With
              With .Range("M:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$S1<>""""")
                .Interior.ColorIndex = 43: .StopIfTrue = True
              End With
              With .Range("M:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(СЧЁТЗ($M1:$R1)>0;$L1="""")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("M:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$J1<>""""")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("V:W").FormatConditions _
                .Add(Type:=xlCellValue, Operator:=xlLess, Formula1:="=0")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("W2:W" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$W2>$V2")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            With .Range("F2:F" & LastRow).Validation
              .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                Operator:=xlGreaterEqual, Formula1:=Settings("date0")
              .ErrorTitle = "Дата поступления в ДОАМ"
              .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
              .ShowError = True: .IgnoreBlank = True
            End With
            With .Range("U2:U" & LastRow).Validation
              .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                Formula1:="=OR($U2=""не оплач."",AND($U2>$F2,ISNUMBER($U2)))"
              .ErrorTitle = "Дата перечислений"
              .ErrorMessage = "Необходимо ввести дату больше " _
                & """Даты поступления в ДОАМ"""
              .ShowError = True: .IgnoreBlank = True
            End With
            
            ' Закрепление области
            .Range("G2").Select: ActiveWindow.FreezePanes = True
          Case "SR_" ' rev.410
            .Tab.ColorIndex = -4142: LastRow = LastRow + 99 ' rev.420
            If .AutoFilterMode Then .ShowAllData Else .Cells(1, 1).AutoFilter ' Автофильтр
            PreError = PreError + 1
            
            .Range("A1:Y1").WrapText = True
            .Columns("E:T").Locked = False
            .Columns("V").Locked = False: .Columns("Y").Locked = False
            .Rows("1:1").Locked = True
            .Columns("B:D").Columns.Group: .Columns("H:N").Columns.Group
            
            ' Форматирование колонок
            .Columns("A:D").NumberFormat = "General"
            .Columns("B:B").NumberFormat = "@"
            .Columns("Y:Y").NumberFormat = "@"
            With .Columns("R:X")
              .NumberFormat = "#,##0"
              .HorizontalAlignment = xlRight: .IndentLevel = 1
            End With: .Rows("1:1").HorizontalAlignment = xlGeneral
            With .Columns("F:R")
              .NumberFormat = "m/d/yyyy"
              .HorizontalAlignment = xlGeneral
            End With: .Range("K:K,M:N").NumberFormat = "@"
            ' Границы таблицы
            With .Range("D:D,S:S").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlThin
            End With
            With .Range("R:R,T:T,U:U,X:X").Borders(xlEdgeRight)
              .LineStyle = xlContinuous: .Weight = xlMedium
            End With
            ' Сортировка
            If .Cells.SpecialCells(xlLastCell).Row > &HE Then _
              SortSupplier App_Sh, 6, 7 ' rev.420
            PreError = PreError + 1
            ' Условное форматирование
            If Val(Application.Version) >= 12 Then
              With .Range("A:Y").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$U1<0")
                .Font.ColorIndex = 2: .Interior.ColorIndex = 9
                .StopIfTrue = True: .SetFirstPriority
              End With
              With .Range("F2:J" & LastRow & ",L2:L" & LastRow & ",O2:R" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И(ИЛИ(F2<ДАТАЗНАЧ(""" & _
                  Settings("date0") & """);F2>СЕГОДНЯ()+3);F2<>"""";F2<>""не оплач."")")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("F2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$F$2:$F" & LastRow & ";$F2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 3: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=СЧЁТЕСЛИМН($E$2:$E" & LastRow & ";$E2;$G$2:$G" & LastRow & ";$G2)>1")
                .Interior.ColorIndex = 45: .StopIfTrue = True
              End With
              With .Range("G2:G" & LastRow).FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=И($E2<>"""";$G2="""";$S2<>"""")")
                .Interior.ColorIndex = 44: .StopIfTrue = True
              End With
              With .Range("I:R").FormatConditions _
                .Add(Type:=xlExpression, Formula1:="=$R1=""не оплач.""")
                .Interior.ColorIndex = 48: .StopIfTrue = True
              End With
            End If
            PreError = PreError + 1
            ' Проверка ввода данных
            With .Range("F2:F" & LastRow).Validation
              .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
                Operator:=xlGreaterEqual, Formula1:=Settings("date0")
              .ErrorTitle = "Дата поступления в ДОАМ"
              .ErrorMessage = "Необходимо ввести дату не раньше " & .Formula1
              .ShowError = True: .IgnoreBlank = True
            End With
            With .Range("R2:R" & LastRow).Validation
              .Add Type:=xlValidateCustom, AlertStyle:=xlValidAlertStop, _
                Formula1:="=OR($R2=""не оплач."",AND($R2>$F2,ISNUMBER($R2)))"
              .ErrorTitle = "Дата перечислений"
              .ErrorMessage = "Необходимо ввести дату больше " _
                & """Даты поступления в ДОАМ"""
              .ShowError = True: .IgnoreBlank = True
            End With
            
            ' Закрепление области
            .Range("G2").Select: ActiveWindow.FreezePanes = True
        End Select
        ' Выделяем последнюю в столбце ячейку rev.420
        With .Range("F" & .Cells.SpecialCells(xlLastCell).Row)
          If LastRow > &HE And Len(.Value) > 0 Then .Select
        End With: ActiveWindow.ScrollRow = IIf(ActiveCell.Row > &HE, _
          ActiveCell.Row - &HE, 1)
        .Outline.ShowLevels ColumnLevels:=2: ProtectSheet App_Sh ' rev.420
        If Not .CodeName = CONF Then ' Если не скрытый лист rev.370
          With .Cells(1, 1).End(xlToRight).Offset(, 1) ' Скрыть столбцы
            App_Sh.Range(.Address, .End(xlToRight)).EntireColumn.Hidden = True
          End With
        End If
      End With
    Next App_Sh
'''    Debug.Print SheetIndex; " "; cnfRenew: Stop ' rev.410
    'On Error Resume Next
    '  ThisWb.Sheets(SheetIndex).Select
    '  If Err Then ThisWb.Sheets(Sh_List("SF_")).Select
    'ThisWb.Sheets(Sh_List("SF_")).Select ' НЕ ТРЕБУЕТСЯ rev.400
    'On Error GoTo 0
    Application.ScreenUpdating = True ' ВКЛ Обновление экрана
    Application.EnableEvents = True ' ВКЛ События rev.400
    'SendKeys "{NUMLOCK}", True ' Костыль v2.5 Фокус должен быть на MS Excel
  Exit Sub
DataExit:
  ErrCollection Err.Number + PreError, 3, 48, App_Sh.Name ' EPN = 3
End Sub

' Запись в «Архив» данных о поставщике из массива SuppDiff
Public Sub RecordCells(ByVal NewSupplier As Boolean)
Dim i As Integer: Counter = 0: i = 2
  If NewSupplier And IsArray(SuppDiff) Then ' => SuppNumRow = 0
    Application.ScreenUpdating = False ' ВЫКЛ Обновление экрана rev.400
    On Error Resume Next
      If Len(SuppDiff(10)) > 0 And Len(SuppDiff(11)) > 0 Then ' rev.410
        With UnprotectSheet(ThisWb.Sheets(Sh_List(ARCH)))
          Do Until IsEmpty(.Cells(i, 10)) ' Счётчик строк ' Выполнять ДО
'''            Stop ' ЗАПИСЬ
            ' Поставщик без «Даты актуальности» не добавляется
            If CDate(.Cells(i, 15)) = CDate(SuppDiff(15)) _
            And .Cells(i, 10) = SuppDiff(10) Then Counter = i ' rev.410
            i = i + 1
            If Err Then ErrCollection Err.Number, 1, 16: Quit = True ' EPN = 1
            'Debug.Print "RecordCells Err #" & Err.Number: If Err Then Exit Sub
          Loop: If Counter <> 0 Then i = Counter
          
          .Outline.ShowLevels ColumnLevels:=3 ' rev.420
          .Cells(i, 1).Resize(1, UBound(SuppDiff)) = SuppDiff
          If IsDate(SuppDiff(15)) Then .Cells(i, 15) = CDate(SuppDiff(15)) ' rev.360
          
          SortSupplier ThisWb.Sheets(Sh_List(ARCH)), 10, 15 ' rev.360
          'CostUpdate SuppDiff(10) ' rev.340
          Erase Get_Supp: CostUpdate ' rev.380
          
          If Err Then ErrCollection Err.Number, 3, 16, .Name ' EPN = 3
        End With: SuppNumRow = 0: SuppDiff = Empty ' Очищаем массив SuppDiff
        ProtectSheet ThisWb.Sheets(Sh_List(ARCH))
      End If
    On Error GoTo 0 ' ВАЖНО! Отключаем сообщения об ошибках
    Application.ScreenUpdating = True ' ВЫКЛ Обновление экрана rev.400
  End If
End Sub

' Изменились ли данные о поставщике на листе «Поставщики»
Public Function CheckSupplier() As Boolean
'  On Error Resume Next
    ' ВАЖНО! Обновление списка с Индексами листов
    With ThisWb.Sheets(GetSheetIndex(SUPP))
      'Stop ' АРХИВ -> ВСЕ ПОЛЯ ДО ДАТЫ АКТУАЛЬНОСТИ rev.410
      
      If Not Join(MultidimArr(.Cells(SuppNumRow, 1).Resize(1, 15).Value, 1)) _
        = Join(SuppDiff) And Len(.Cells(SuppNumRow, 15).Value) > 0 Then ' rev.410
      'If Not .Cells(SuppNumRow, 1).Value & .Cells(SuppNumRow, 4).Value _
        & .Cells(SuppNumRow, 5).Value & .Cells(SuppNumRow, 6).Value _
        & .Cells(SuppNumRow, 8).Value & .Cells(SuppNumRow, 10).Value _
        & .Cells(SuppNumRow, 11).Value & .Cells(SuppNumRow, 12).Value _
        & .Cells(SuppNumRow, 14).Value & .Cells(SuppNumRow, 15).Value _
        = SuppDiff(1) & SuppDiff(4) & SuppDiff(5) & SuppDiff(6) & SuppDiff(8) _
        & SuppDiff(10) & SuppDiff(11) & SuppDiff(12) & SuppDiff(14) _
        & SuppDiff(15) And Len(.Cells(SuppNumRow, 15).Value) > 0 Then ' rev.360
        
        If Err Then ErrCollection 10, 1, 16: Exit Function ' EPN = 1
        .Activate ' rev.410
        
        If CDate(.Cells(SuppNumRow, 15).Value) < CDate(SuppDiff(15)) Then
          If MsgBox("У поставщика '" & SuppDiff(10) & "' новая 'Дата актуальн" _
            & "ости' " & .Cells(SuppNumRow, 15).Value & " не может быть раньш" _
            & "е предыдущей. ", 1 + 16, "Дата актуальности") = vbCancel Then _
            .Cells(SuppNumRow, 15) = CDate(SuppDiff(15)) _
          Else .Cells(SuppNumRow, 15).Select: Exit Function ' rev.420
        End If
        If CDate(.Cells(SuppNumRow, 15).Value) = CDate(SuppDiff(15)) Then
          If MsgBox("У поставщика '" & SuppDiff(10) & "' изменились данные. " _
            & "Необходимо изменить 'Дату актуальности' на более позднюю. " _
            & vbCrLf & "Изменить 'Дату актуальности' " & .Cells(SuppNumRow, _
            15).Value & " на " & "текущую дату? ", 260 + 48, _
            "Данные о поставщике") = vbYes Then _
          .Cells(SuppNumRow, 15) = Date _
          Else .Cells(SuppNumRow, 15).Select: Exit Function ' rev.360
        End If
        If Len(.Cells(SuppNumRow, 11).Value) > 0 Then ' rev.410
          CheckSupplier = True ' Подтвердить изменение данных
          ' Создаём массив с изменениями о поставщике rev.310
          SuppDiff = MultidimArr(.Cells(SuppNumRow, 1) _
            .Resize(1, UBound(SuppDiff)).Value, 1)
        Else: .Cells(SuppNumRow, 15).ClearContents: End If
      End If
    End With
End Function

' Проверка перед действиями App_WorkbookBeforeClose и App_WorkbookBeforeSave
Public Function ChangedBeforeSave(ByRef Sh As Worksheet) As Boolean
  If Sh.CodeName = SUPP And IsArray(SuppDiff) And SuppNumRow > 1 Then
    If Not CheckSupplier Then ' Если изменены данные о поставщике
    
      ' rev.410 Зачем ещё раз проверять данные о поставщике? Где ошибка?
      If Not Join(MultidimArr(Sh.Cells(SuppNumRow, 1).Resize(1, 15).Value, 1)) _
        = Join(SuppDiff) And Len(Sh.Cells(SuppNumRow, 15).Value) > 0 Then
      'If Not Sh.Cells(SuppNumRow, 1).Value & Sh.Cells(SuppNumRow, 4).Value _
        & Sh.Cells(SuppNumRow, 5).Value & Sh.Cells(SuppNumRow, 6).Value _
        & Sh.Cells(SuppNumRow, 8).Value & Sh.Cells(SuppNumRow, 10).Value _
        & Sh.Cells(SuppNumRow, 11).Value & Sh.Cells(SuppNumRow, 12).Value _
        & Sh.Cells(SuppNumRow, 14).Value & Sh.Cells(SuppNumRow, 15).Value _
        = SuppDiff(1) & SuppDiff(4) & SuppDiff(5) & SuppDiff(6) & SuppDiff(8) _
        & SuppDiff(10) & SuppDiff(11) & SuppDiff(12) & SuppDiff(14) _
        & SuppDiff(15) And Len(Sh.Cells(SuppNumRow, 15).Value) > 0 Then ' rev.360
        
        ErrCollection 20, 1, 16, Sh.Cells(SuppNumRow, 10) ' EPN = 1
        ChangedBeforeSave = True
      End If
    End If
  End If
End Function

' Список с «Категориями цены»
Public Sub ListCost(ByRef Sh As Worksheet, ByVal TargetRow As Long)
Dim Src As String, OrgBody As String ''' ???
  OrgBody = Sh.Cells(TargetRow, 1) ' Список «Категория цены» для Поставщика
  ''Stop ' Добавить OrgBody
  Sh.Cells(TargetRow, 11).Validation.Delete ' Очистка проверки данных rev.360
  
  If Len(OrgBody) > 2 And PERSON_LIST Like "*" & OrgBody & "*" Then ' rev.420
    For Counter = LBound(Cost(OrgBody), 2) To UBound(Cost(OrgBody), 2)
      If Not Src Like "*" & Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) _
        & "*" And Asc(Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter)) <> 63 _
      Then Src = "," & Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) & Src
      'If Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) = "?РИЦ" Then _
        Counter = Counter + 1 ' Пропускаем архивные цены (РИЦ до 2012 года)
      'If Counter > LBound(Cost(OrgBody), 2) Then ' Пропускаем 1-ю запись
        ' Если таблица «Категория цены» = «Поставщик» <> предыдущее знач.таблицы
      '  If Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) = Sh.Cells( _
          TargetRow, 10) And Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) _
          <> Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter - 1) Then _
          Src = Cost(OrgBody)(LBound(Cost(OrgBody), 1), Counter) & "," & Src
      'Else
      '  Src = "стандарт,?ДПР" ' Исключаем как архивные «Категория цены» = «?РИЦ»
      'End If
    Next Counter
    With Sh.Cells(TargetRow, 11).Validation ' rev.420
      .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, Formula1:=Mid(Src, 1)
      .ErrorTitle = "Категория цен"
      .ErrorMessage = "Необходимо выбрать значение из списка "
      .ShowError = True: .IgnoreBlank = True
    End With
  End If
End Sub

' Создание формулы "Сумма" rev.410
Public Function GetCosts(ByVal Supplier As String, ByVal PartDate As Variant, _
ByVal CodeNameSheet As String, ByVal ErrMessage As Boolean) As String
Dim SuppCost As Variant, OrgBody As String
  On Error GoTo DataExit ' rev.340 If IsEmpty(Cost) Then GoTo DataExit
    OrgBody = Get_Supp(1, SuppNumRow - 1) ' Костыль
    For Counter = LBound(Cost(OrgBody), 2) To UBound(Cost(OrgBody), 2)
    
    Debug.Print Cost(OrgBody)(0, Counter); "="; Get_Supp(11, SuppNumRow - 1) ' Костыль
    Debug.Print Cost(OrgBody)(1, Counter); "<="; CDate(PartDate)
      
      If Cost(OrgBody)(0, Counter) = Get_Supp(11, SuppNumRow - 1) _
      And Cost(OrgBody)(1, Counter) <= CDate(PartDate) Then
        ' ВАЖНО! Если следующее поле цены "Актуально" > "Даты актуальности"
        If Counter < UBound(Cost(OrgBody), 2) Then _
          If Cost(OrgBody)(0, Counter) <> Cost(OrgBody)(0, Counter + 1) _
          Or (Cost(OrgBody)(0, Counter) = Cost(OrgBody)(0, Counter + 1) _
          And Cost(OrgBody)(1, Counter + 1) > CDate(PartDate)) Then Exit For
        If Counter = UBound(Cost(OrgBody), 2) Then Exit For ' rev.410
      End If
    Next Counter: If Counter > UBound(Cost(OrgBody), 2) Then GoTo DataExit _
      Else SuppCost = MultidimArr(Cost(OrgBody), Counter, 2): _
      If ErrMessage Then SuppNumRow = Counter: cnfRenew = OrgBody ' НЕ ОШИБКА rev.410
    If Len(OrgBody) > 2 And PERSON_LIST Like "*" & OrgBody & "*" Then
      Select Case CodeNameSheet
        Case "SB_", "SF_" ' rev.390
          For Counter = LBound(SuppCost) To UBound(SuppCost)
            PartDate = SuppCost(Counter)
            Select Case Counter
              Case 2: GetCosts = "=RC[-11]*" & PartDate ' Группа 0
              Case 3: GetCosts = GetCosts & "+RC[-10]*" & PartDate ' Группа 1
              Case 4: GetCosts = GetCosts & "+RC[-9]*" & PartDate ' Группа 2
              Case 6: If PartDate > 0 Then GetCosts = Replace(GetCosts, _
                "RC[-11]", "(RC[-11]-RC[-6])") & "+RC[-6]*" & PartDate ' НУМ 0
              Case 7: If PartDate > 0 Then GetCosts = Replace(GetCosts, _
                "RC[-10]", "(RC[-10]-RC[-5])") & "+RC[-5]*" & PartDate ' НУМ 1
              Case 8: If PartDate > 0 Then GetCosts = Replace(GetCosts, _
                "RC[-9]", "(RC[-9]-RC[-4])") & "+RC[-4]*" & PartDate ' НУМ 2
              Case 9: GetCosts = GetCosts & "+RC[-8]*" & PartDate ' НАШ 1
              Case 10: GetCosts = GetCosts & "+RC[-7]*" & PartDate ' НАШ 2
              Case 14: If PartDate > 0 Then GetCosts = GetCosts _
                & "+RC[-1]*" & PartDate ' Бухонлайн и [Кодекс] Ф/Л
            End Select
          Next Counter
        Case "OU_" ' Актуализация материалов [Группа А] = 5 rev.410
          GetCosts = "=RC[-1]*" & SuppCost(5)
        Case "QB_" ' Покупка вопросов [Вопросы] = 11 rev.410
          GetCosts = "=IF(RC[4]=""На входе"",RC[-4],RC[-1])*" & SuppCost(11)
        Case "SL_" ' Статистика ЮВО [ЮВО] = 12 rev.410
          GetCosts = "=RC[-1]*" & SuppCost(12)
        Case "SR_" ' Письма ОФП [Оф письма] Ф/Л = 13 rev.410
          GetCosts = "=RC[-1]*" & SuppCost(13)
        Case Else: GetCosts = "=-300" ' ВНЕ ГРУПП
      End Select
    End If: Exit Function
DataExit:
  If Len(Supplier) > 0 Then ' rev.380
    If ErrMessage Then ErrCollection 40, 1, 48, "для поставщика '" & Supplier _
      & "' " & IIf(CDate(Val(PartDate)) >= Settings("date0"), "на " _
      & Format(PartDate, "ddddd"), "в строке #" & PartNumRow) ' EPN = 1
    GetCosts = IIf(Len(PartDate) > 0, "=-200", "=-100") ' ЗАЧЕМ? rev.410: SuppDiff = Empty
    ' Ошибка, поэтому обновить суммы при открытии статистики rev.380
    'UnprotectSheet(ThisWb.Sheets(Sh_List(CONF))).Range(CONF & "CostDate") = 0
    'ProtectSheet ThisWb.Sheets(Sh_List(CONF))
  Else: GetCosts = Empty
  End If
End Function

' Поиск строки SuppNumRow с данными о Поставщике на листе "Архив" rev.420
Public Function GetSuppRow(ByVal Supplier As String, ByVal PartDate As Date) _
As Boolean
  On Error GoTo DataExit ' rev.410
    SuppNumRow = 0: Counter = 1 ' Счётчик строк листа "Архив"; Костыль
    ' ВАЖНО! Обновление списка с Индексами листов
    Do While Len(Get_Supp(10, Counter)) > 0 ' Счётчик строк ' Выполнять ПОКА
      If Get_Supp(10, Counter) = Supplier _
      And CDate(Get_Supp(15, Counter)) <= PartDate Then
        ' ВАЖНО! Если следующая "Дата актуальности" > "Дата поступления", то
        If Get_Supp(10, Counter) <> Get_Supp(10, Counter + 1) Or _
          (Get_Supp(10, Counter) = Get_Supp(10, Counter + 1) _
        And CDate(Get_Supp(15, Counter + 1)) > PartDate) Then _
          SuppNumRow = Counter + 1: GetSuppRow = True: Exit Function
      End If: Counter = Counter + 1
    Loop: Exit Function ' rev.410
DataExit:
  ErrCollection Err.Number, 1, 48 ' EPN = 1 rev.410
End Function

Public Function GetDateAndCosts(ByVal CodeNameSheet As String, ByVal PartDate _
As Variant) As Variant ' Цены поставщика (только для ShowCosts) rev.420
Dim OrgBody As String: If IsArray(PartDate) Then OrgBody = PartDate(1)
  If PERSON_LIST Like "*" & cnfRenew & "*" Then ' rev.410
    GetDateAndCosts = MultidimArr(Cost(cnfRenew), SuppNumRow, 1)
    Debug.Print UBound(Cost(cnfRenew)) ' Верхняя граница Коллекции
    cnfRenew = cnfRenew & " " & Cost(cnfRenew)(0, SuppNumRow)
  ElseIf IsArray(PartDate) Then
    If Len(PartDate(15)) > 0 And IsDate(PartDate(15)) Then ' rev.420
    If CDate(PartDate(15)) >= Settings("date0") Then
      'Debug.Print UBound(Cost(OrgBody)); cnfRenew ' Верхняя граница Коллекции
      cnfRenew = PartDate(1) & " " & PartDate(11) ' Имя таблицы ЦЕНЫ rev.410
      For Counter = LBound(Cost(OrgBody), 2) To UBound(Cost(OrgBody), 2)
        If Cost(OrgBody)(0, Counter) = PartDate(11) _
        And Cost(OrgBody)(1, Counter) <= CDate(PartDate(15)) Then
          ' ВАЖНО! Если следующее поле цены "Актуально" > "Даты актуальности"
          If Counter < UBound(Cost(OrgBody), 2) Then _
          If Cost(OrgBody)(0, Counter) <> Cost(OrgBody)(0, Counter + 1) _
          Or (Cost(OrgBody)(0, Counter) = Cost(OrgBody)(0, Counter + 1) _
          And Cost(OrgBody)(1, Counter + 1) > CDate(PartDate(15))) Then Exit For
          If Counter = UBound(Cost(OrgBody), 2) Then Exit For ' rev.410
        End If
      Next Counter: If Counter > UBound(Cost(OrgBody), 2) Then _
        ErrCollection 50, 1, 16, cnfRenew Else GetDateAndCosts = _
        MultidimArr(Cost(OrgBody), Counter, 1) ' EPN = 1 rev.410
    End If
    End If
  End If
End Function
