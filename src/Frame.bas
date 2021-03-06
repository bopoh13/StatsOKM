Attribute VB_Name = "Frame"
Option Explicit
Option Base 1
Option Private Module ' rev.340
'12345678901234567890123456789012345bopoh13@ya67890123456789012345678901234567890

Private Counter As Integer ' Счётчик

Property Get GetUserName() As String
  GetUserName = Environ("UserName")
End Property

Private Sub SendKeyEnter() ' Эмуляция нажатия клавиши «Enter» rev.380
  On Error Resume Next
    If ThisWb.FullName = ActiveWorkbook.FullName Then _
      SendKeys "{ESC}", True: SendKeys "{ENTER}", False ' Костыль
End Sub

Private Sub SendKeysCtrlV() ' Эмуляция нажатия клавиш «Ctrl+V» rev.420
  On Error Resume Next
    With Selection
      .PasteSpecial Paste:=xlPasteValues, Operation:=xlNone
      If ThisWb.FullName <> ActiveWorkbook.FullName Then
        ' Вставка форматов, Очистка условного форматирования
        .PasteSpecial Paste:=xlPasteFormats, Operation:=xlNone
        .Cells.FormatConditions.Delete
      End If
      If Err Then
        ReDim Get_Supp(ActiveSheet.Cells.SpecialCells(xlLastCell).Row)
        For Counter = LBound(Get_Supp) To UBound(Get_Supp)
          Get_Supp(Counter) = .Offset(Counter - SuppNumRow, 0).Value
        Next Counter: ActiveSheet.PasteSpecial Format:="Текст"
        Erase Get_Supp
      End If
    End With
End Sub

Property Let Quit(ByVal xlBlock As Boolean) ' Вместо "End" rev.340
  With Application
    .CommandBars("Cell").Reset: .CommandBars("Row").Reset ' rev.410
    If xlBlock Then
      UnprotectSheet(ThisWb.Sheets(GetSheetIndex(SUPP))) _
        .Cells.Locked = True
      ProtectSheet ThisWb.Sheets(Sh_List(SUPP))
      .CellDragAndDrop = True: .MoveAfterReturnDirection = xlDown
      .DisplayPasteOptions = True: End ' rev.390
    Else
      .CellDragAndDrop = False: .MoveAfterReturnDirection = xlToRight
      .DisplayPasteOptions = False ' rev.370
      ActiveWindow.Caption = ActiveWorkbook.Name & " (rev." & REV & ")" _
        & IIf(ActiveWorkbook.ReadOnly, "  [Только для чтения]", "") ' rev.360
      If .WindowState <> xlMaximized Then .WindowState = xlMaximized ' rev.400
    End If
  End With
End Property

' Загрузка данных с настройками ' rev.300
Public Sub SettingsStatistics(ByRef Cost As Collection) ' rev.410
Dim N_List As New Collection, iND As Object, bank As String, suffix As String
Const ACC_PATH = "X:\Avtor_M\#Finansist\YCHET" ' Директория «YCHET» rev.330
  ' ВАЖНО! Обновление списка с Индексами листов
  If GetSheetIndex(CONF) < 1 Then ErrCollection 1001, 1, 16 ' EPN = 1
  Worksheets(Sh_List(CONF)).Visible = xlSheetVeryHidden ' СКРЫТЬ rev.420
  RemoveCollection Cost: RemoveCollection Settings ' rev.410
  Settings.Add DateSerial(2009, 1, 1), "date0"
  On Error Resume Next
    For Each iND In ThisWb.NameS
    With iND
        bank = Left(.Name, InStr(.Name, "_")): suffix = Mid(.Name, Len(bank) + 1)
        ' Внутренние диапазоны
        If .Name Like "_xl*" Then Debug.Print "Системный диапазон "; .Name
        ' Необходимо наличие .Name = Список_поставщиков, чтобы сохранить N_List
        If N_List("key") <> bank Then ' Если Коллекция на листе закончилась
          Settings.Add N_List, N_List("key"): Set N_List = Nothing ' Записать
        End If
        If .RefersToRange.Count = 1 Then
          If Len(bank) > 2 And .Value Like "*[#]*" Then ' Если «Ссылка» битая
            .Visible = True: ErrCollection 57, 1, 16, "'" & .Name & "'" ' EPN = 1
          ElseIf bank Like "*!" & CONF Then ' Если лист "Настройки"
            Settings.Add CStr(.RefersToRange.Value), suffix
          ' Если появляется Банки: ПЗ, А, ПВ, СВ, АП, БО, КФ, ЮВО, ОПФ
          ElseIf bank Like SHEETS_ALL Or bank = SUPP Then ' Если Банк ...
            If N_List.Count < 1 Then ' ... смотрим, является ли Банк «новым»
            ' Вписываем Имя листа, на котором он находится «новый» Банк
              N_List.Add bank, "key": N_List.Add .RefersToRange.Row, "head"
            End If: N_List.Add .RefersToRange.Column, suffix
          End If
        End If: If .Name = SUPP_LIST Then .Delete ' rev.410
      End With: Err.Clear
    Next iND: Settings.Add IIf(Len(Dir(ACC_PATH, vbDirectory)) > 0, _
      ACC_PATH, ThisWb.Path), "SetPath" ' rev.410
    
    bank = ThisWb.Sheets(Sh_List(SUPP)).Name ' rev.410
    With ThisWb.NameS.Add(Name:=SUPP_LIST, RefersTo:="=$E$1") ' rev.410
      .Comment = "Список листа Поставщики": .RefersTo = "=OFFSET('" _
        & bank & "'!$J$1,1,,COUNTA('" & bank & "'!$J:$J)-1,)"
    End With
End Sub

' Обновление списка Индексов листов rev.300
Public Function GetSheetIndex(ByVal CodeNameSheet As String) As Byte
Dim App_Sh As Worksheet: RemoveCollection Sh_List
  If ThisWb Is Nothing Then Set ThisWb = ThisWorkbook ' rev.410
  'If XLApp Is Nothing Then Set XLApp = New cExcelEvents ' Модуль rev.380
  On Error Resume Next
    For Each App_Sh In ThisWb.Sheets
      Sh_List.Add CByte(App_Sh.Index), App_Sh.CodeName ' Индекс в список rev.380
      If App_Sh.CodeName = CodeNameSheet Or App_Sh.Name = CodeNameSheet Then _
        GetSheetIndex = App_Sh.Index
    Next App_Sh
    If Err Then ErrCollection Err.Number, 2, 16: Quit = True ' EPN = 2
End Function

Public Sub ProtectSheet(ByRef Sh As Worksheet) ' Защитить лист rev.300
  On Error Resume Next
    Sh.EnableOutlining = True ' ЗАГРУЗКА: Группировка на защищённом листе
    Sh.Protect Password:=Settings("CostPass"), UserInterfaceOnly:=True, _
      Contents:=True, AllowFiltering:=True, AllowDeletingRows:=True, _
      AllowFormattingColumns:=True, DrawingObjects:=False
    If Err Then ErrCollection Err.Number, 2, 16, Sh.Name ' EPN = 2
End Sub

' Снять защиту с листа (не использовать ScreenUpdating) rev.300
Public Function UnprotectSheet(ByRef Sh As Worksheet) As Worksheet
  On Error Resume Next
    If Sh.ProtectScenarios Then Sh.Unprotect Settings("CostPass")
    Set UnprotectSheet = Sh
    If Err Then ErrCollection Err.Number, 2, 16, Sh.Name ' EPN = 2
End Function

Public Sub SortSupplier(ByRef Sh As Worksheet, ByVal FirstKey As Byte, _
Optional ByVal SecondKey As Byte) ' rev.300
Dim LastRow As Long: LastRow = Sh.UsedRange.Rows.Count + 1 ' Последняя строка
  If Not Sh.AutoFilterMode Then Sh.Cells(1, FirstKey).AutoFilter
  With Sh.AutoFilter.Sort
    .SortFields.Clear: .Header = xlYes
    .SortFields.Add Key:=Sh.Cells(2, FirstKey).Resize(LastRow, 1)
    If SecondKey > 0 Then _
      .SortFields.Add Key:=Sh.Cells(2, SecondKey).Resize(LastRow, 1)
    .Orientation = xlTopToBottom: .Apply
  End With
End Sub

' Удаление коллекции
Private Sub RemoveCollection(ByRef CollectionName As Collection) ' rev.300
  For Counter = 1 To CollectionName.Count: CollectionName.Remove 1: Next Counter
End Sub

' Заполнение одномерного массива из двумерного (для Цен и текста) rev.380
Public Function MultidimArr(ByVal Cost As Variant, ByVal Row As Long, _
Optional ByRef FirstItem As Byte = 0) As Variant
Dim Arr As Variant
  If FirstItem > 0 Then ' для Цен
    ReDim Arr(LBound(Cost, 1) + FirstItem To UBound(Cost, 1)) As Currency
    If Not IsArray(Cost) Then MultidimArr = Arr: Exit Function
    For Counter = LBound(Arr) To UBound(Arr)
      If Not IsNull(Cost(Counter, Row)) Then Arr(Counter) = Cost(Counter, Row)
    Next Counter: MultidimArr = Arr
  Else ' для текстовых массивов
    ReDim Arr(LBound(Cost, 2) To UBound(Cost, 2)) As String
    For Counter = LBound(Arr) To UBound(Arr)
      'On Error Resume Next ' Пропуск значений-ошибок rev.380
        Arr(Counter) = Cost(Row, Counter)
    Next Counter: MultidimArr = Arr
  End If
End Function

' Удаление непечатаемых символов и «лишних» пробелов ' rev.420
Public Function ClearSpacesInText(ByVal text As String) As String
  text = Replace(text, Chr(160), " ")      ' неразрывный пробел
  'text = Replace(text, ".", ". ") ' Ошибка при проверке "т.п."
  text = Replace(text, " .", ". ")
  text = Replace(Replace(text, ",", ", "), " ,", ", ")
  text = Replace(Replace(text, "!", "! "), " !", "! ")
  text = Replace(Replace(text, "?", "? "), " ?", "? ")
  text = Replace(Replace(text, ":", ": "), " :", ": ")
  text = Replace(Replace(text, ";", "; "), " :", ": ")
  text = Replace(Replace(text, "( ", "("), " )", ")")
  text = Replace(text, Chr(10), " ")       ' Перевод строки
  text = Replace(text, Chr(13), " ")       ' Перевод каретки
  text = Replace(text, Chr(150), Chr(45))  ' Короткое тире
  text = Replace(text, Chr(151), Chr(45))  ' Длинное тире
  text = Replace(text, Chr(133), "...")    ' Многоточие
  text = Replace(text, Chr(172), "")       ' знак переноса
  Do While text Like "*  *" ' Выполнять ПОКА есть двойной пробел
    text = Replace(text, "  ", " ")
  Loop
  text = Replace(text, Chr(39), Chr(34))   ' апостроф
  text = Replace(text, Chr(171), Chr(34))  ' левые двойные кавычки
  text = Replace(text, Chr(187), Chr(34))  ' правые двойные кавычки
  text = Replace(text, Chr(147), Chr(34))  ' левые четверть круга кавычки
  text = Replace(text, Chr(148), Chr(34))  ' правые четверть круга кавычки
  text = Replace(text, Chr(34) & Chr(34), Chr(34))
  ClearSpacesInText = Trim(text)
End Function

' Указания для пользователя при возникновении ошибки
Public Sub ErrCollection(ByVal ErrNumber As Long, ByVal ErrPartNum As Byte, _
ByVal Icon As Byte, Optional ByVal Str As String)
Dim Ask As Byte, Msg As String, Title As String
' https://support.microsoft.com/ru-ru/kb/146864
  Ask = 1: Title = "Ошибка чтения " ' По умолчанию
  Select Case ErrNumber * ErrPartNum ' Номер ошибки * EPN (ErrPartNum)
    ' EPN = 1
    'Case -2147217908, -2147217900: Msg = "Невозможно выполнить " _
      & IIf(ErrNumber Like "*908", "пустой ", "") & "запрос к базе данных. " _
      & "Восстановите резервную копию файла " & vbCrLf & Str ' Проверьте цены
    Case -2147217843: Msg = "Неверный пароль базы данных. " _
      & "Восстановите резервную копию файла " & vbCrLf & Str
    Case 20: Ask = 0: Msg = "У поставщика '" & Str & "' изменились основные да" _
      & "нные. " & vbCrLf & "Перед сохранением необходимо изменить поле 'Дата " _
      & "актуальности'. " & vbCrLf: Icon = 48: Title = "Ошибка ввода данных "
    Case 30: Ask = 0: Msg = "Вы пытались вставить диапазон ячеек. " & vbCrLf _
      & "На данном листе из буфера обмена можно вставить только первую строку."
    ' В данной версии нет предупреждения «Дата поступления» с пустым поставщиком
    Case 40: If Str Like "*''*" Then _
      Ask = 5: Msg = "Не указан поставщик " & Mid(Str, 19) & ". ": Icon = 64 _
      Else: Ask = 4: Msg = "Не найдены цены " & Str & ". " ' rev.340
    Case 50: Msg = "В файле ЦЕНЫ не заполнена таблица '" & Str & "'. " ' rev.400
    Case 57: Msg = "В настройках " & Str & " обнаружена битая ссылка. "
    Case 59: Msg = "Файл '" & Str & "' не найден! " _
      & "Работа с данными невозможна!": Title = "Ошибка открытия файла "
    Case 457: Ask = 2: Msg = "Невозможно обновить коллекцию с ценами '" & Str _
      & "'. Работа с данными невозможна! "
    Case 1001: Ask = 3: Msg = "Лист 'Настройки' не найден! " _
      & "Работа с данными невозможна! "
    Case 3704: Msg = "Не найдена таблица '" & Str & " стандарт' в файле ЦЕНЫ. "
    ' EPN = 2
    Case 10: Ask = 2: Msg = IIf(Len(Str), "Невозможно снять защиту с листа '" _
      & Str & "'. ", "Лист не защищён. ") & "Коллекция 'Settings' is Nothing! "
    Case 182, 184: Ask = 0: Msg = "Значение переменной 'ThisWb' is Nothing! " _
      & "Работа с данными невозможна! " & vbCrLf & IIf(ErrNumber = 92, "Необ" _
      & "ходимо закрыть файл '" & Windows(1).Caption & "' и открыть заново. " _
      & String(2, vbCr) & "При частом появлении ошибки о", "О") & "братитесь " _
      & "к специалисту по автоматизации. ": Title = "Внутренняя ошибка "
    Case 2008: Ask = 3: Msg = "На листе '" & Str & "' задан неизвестный пароль. "
    ' EPN = 3
    Case 15: Msg = "Невозможно создать новую партию." & vbCrLf _
      & "Заблокирована ячейка " & Str & "'. " & vbCrLf: Title = "Ошибка записи "
    Case 21: Msg = "Ошибка в формуле условного форматирования на листе '" _
      & Str & "'. ": Title = "Ошибка ввода данных " ' rev.360
    Case 273: Msg = "Невозможно применить сортировку к пустому фильтру " _
      & "на листе '" & Str & "'. "
    Case 3012: Msg = "Невозможно применить автофильтр на листе '" & Str & "'. "
    Case 3018: Msg = "Невозможно создать условное форматирование. Ошибка " _
      & "в связанных диапазонах, либо лист '" & Str & "' защищён от записи. " _
      & vbCrLf: Title = "Ошибка ввода данных "
    Case 3021: Msg = "Невозможно применить проверку данных. Ошибка " _
      & "в формуле, либо лист '" & Str & "' защищён от записи. " _
      & vbCrLf: Title = "Критическая ошибка ": Icon = 16 ' rev.370
    ' not EPN
    Case Else: Msg = "Неизвестная ошибка #" & ErrNumber & " ": Icon = 16
  End Select: Select Case Ask
    Case 1: Msg = Msg & vbCrLf & "Обратитесь к специалисту по автоматизации. "
    Case 2: Msg = Msg & vbCrLf & "Необходимо сохранить файл '" _
      & Windows(1).Caption & "' " & "и открыть заново. "
    Case 3: Msg = Msg & vbCrLf & "Восстановите резервную копию " _
      & "файла '" & Windows(1).Caption & "'. ": Title = "Критическая ошибка "
    Case 4: Msg = Msg & vbCrLf & "Проверьте 'Категорию цен' у поставщика, " _
      & "затем проставьте 'Дату поступления в ОКМ'. "
    Case 5: Msg = Msg & vbCrLf & "Выберите поставщика " _
      & "или удалите 'Дату поступления в ОКМ'. "
  End Select: MsgBox Msg, Icon, Title & IIf(ErrNumber > 0, ErrPartNum & "x", _
    "ADODB ") & ErrNumber: If Ask = 3 Then Quit = True
End Sub
