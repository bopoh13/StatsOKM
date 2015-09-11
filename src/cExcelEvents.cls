VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cExcelEvents"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Option Base 1
'12345678901234567890123456789012345bopoh13@ya67890123456789012345678901234567890

Private WithEvents App As Application, Clipboard_RangeAddress As String
Attribute App.VB_VarHelpID = -1
Private Count As Long ' Счётчик; Если с минусом, то номер строки

Private Sub Class_Initialize() ' Open #1.2
  Set App = Application
  ' Запретить ввод без перемещения курсора. Не работает при выборе из списка
  App.OnKey "^~", "SendKeyEnter": App.OnKey "^{ENTER}", "SendKeyEnter"
  ' Вставка данных через горячие клавиши rev.330
  App.OnKey "^v", "SendKeysCtrlV": App.OnKey "+{INSERT}", "SendKeysCtrlV"
End Sub

Private Sub App_WorkbookOpen(ByVal Wb As Workbook) ' Open #1.3
  ' Действий не требуется
End Sub

Private Sub App_WorkbookActivate(ByVal Wb As Workbook) ' Open #1.4
  On Error Resume Next
    If ThisWb.FullName = Wb.FullName Then ' rev.370
      Quit = False: Clipboard_RangeAddress = Selection.address ' Для буфера
      With App.CommandBars("Cell") ' Удаление меню специальной вставки
        ' http://www.rondebruin.nl/win/s4/win011.htm
        With .Controls.Add(Id:=370, Temporary:=True, _
          Before:=.Controls(.FindControl(Id:=22).Caption).Index)
          .Caption = "&Вставить значения": .FaceId = 22 ' Недокументировано
        End With
        .FindControl(Id:=22).Delete ' Удалить меню: Вставить
        .FindControl(Id:=3624).Delete ' Удалить меню: Вставить таблицу
      End With: App.Calculation = xlAutomatic ' rev.370
    End If: If Err Then ErrCollection Err.Number, 2, 16: Quit = 1 ' EPN = 2
End Sub

Private Sub App_WorkbookBeforeClose(ByVal Wb As Workbook, _
Cancel As Boolean) ' Close #1.1
  On Error Resume Next
    If ThisWb.FullName = Wb.FullName Then
      Cancel = ChangedBeforeSave(Wb.ActiveSheet) ' Отменить закрытие файла
      If Not Cancel And IsArray(SuppDiff) And SuppNumRow > 1 Then _
        RecordCells True ' ЗАПИСЬ, Удалено 'Set App = Nothing' rev.390
      App_SheetActivate Wb.ActiveSheet ' Костыль
    End If: If Err Then ErrCollection Err.Number, 2, 16: Quit = 1 ' EPN = 2
End Sub

Private Sub App_WorkbookDeactivate(ByVal Wb As Workbook) ' Close #1.2
Dim CopyMode As Boolean: CopyMode = App.CutCopyMode ' Буфер заполнен rev.370
  ' Отключено в rev.330
  On Error Resume Next ' Деактивация книги работает только в окне документа
    If ThisWb.FullName = Wb.FullName Then
      App.CellDragAndDrop = True: App.MoveAfterReturnDirection = xlDown
      App.DisplayPasteOptions = True: App.CommandBars("Cell").Reset ' rev.370
      If CopyMode Then _
        ThisWb.Sheets(cnfRenew).Range(Clipboard_RangeAddress).Copy ' rev.370
      'If GetSheetList(SUPP) > 0 Then
      '  Debug.Print SUPP; " "; Wb.Sheets(Sh_List(SUPP)).CodeName
      '  Debug.Print SUPP: Stop
      If Wb.Sheets(GetSheetList(SUPP)).Name = cnfRenew _
      And IsArray(SuppDiff) And SuppNumRow > 1 Then
        RecordCells CheckSupplier
        ' см.App_SheetDeactivate - SuppDiff = Empty: ProtectSheet Wb.ActiveSheet
      End If
    End If: If Err Then ErrCollection Err.Number, 2, 16: Quit = 1 ' EPN = 2
End Sub

Private Sub App_WorkbookBeforeSave(ByVal Wb As Workbook, _
ByVal SaveAsUI As Boolean, Cancel As Boolean) ' Close #1.3
  On Error Resume Next ' SaveAsUI не работает, причина не известна
    If ThisWb.FullName = Wb.FullName Then
      Cancel = ChangedBeforeSave(Wb.ActiveSheet) ' Отменить сохранения файла
      'Debug.Print Cancel; Len(cnfRenew): Stop
      If Not Cancel And Len(cnfRenew) > 0 Then
        If IsArray(SuppDiff) And SuppNumRow > 1 Then RecordCells True ' ЗАПИСЬ
        Count = 0: SpecificationSheets Wb.ActiveSheet.Index ' rev.380
      End If
    End If: If Err Then ErrCollection Err.Number, 2, 16: Quit = 1 ' EPN = 2
End Sub

Private Sub App_SheetDeactivate(ByVal Sh As Object) ' #S Серый лист
  App.Cursor = xlNorthwestArrow ' Курсор «Стрелка»
  'App.ScreenUpdating = False  ' ВЫКЛ Обновление экрана
  If Count < 0 And Not Sh.ProtectScenarios Then _
    Sh.Rows(Abs(Count)).Locked = True: Count = 0 ' Защита ячеек
  If Sh.CodeName = ARCH Then
    On Error Resume Next
      App.ScreenUpdating = False: SortSupplier Sh, 10, 15 ' rev.360
      Sh.Visible = xlSheetHidden: App.ScreenUpdating = True ' СКРЫТЬ
      If Err Then ErrCollection Err.Number, 3, 16, Sh.Name: Exit Sub ' EPN = 3
    On Error GoTo 0
  End If
  ''Stop: Debug.Print SuppNumRow; Selection.Row
  If Sh.CodeName = SUPP And IsArray(SuppDiff) _
  And SuppNumRow > 1 Then RecordCells CheckSupplier
  ' Нельзя применять ProtectSheet Sh - стирается буфер
  ' Нельзя применять SuppDiff = Empty - возникает ошибка
End Sub

Private Sub App_SheetActivate(ByVal Sh As Object) ' #S Белый лист
  With ActiveSheet
    If .CodeName Like SHEETS_ALL Or .CodeName = ARCH Then _
      PartNumRow = ActiveCell.Row: SuppDiff = Empty ' rev.400
    If .CodeName = SUPP And IsEmpty(SuppDiff) Then
      Erase Get_Supp: SuppNumRow = Selection.Row ' rev.390
      ' Создаём массив с изменениями о поставщике (до ФИО = 15) rev.310
      SuppDiff = MultidimArr(.Cells(SuppNumRow, 1).Resize(, 15).Value, 1)
    End If ': App.ScreenUpdating = True ' ВКЛ Обновление экрана
    App.Cursor = xlDefault ' Восстановить Курсор «по умолчанию»
    'Clipboard_RangeAddress = Selection.address ' Для буфера - откл rev.370
    If Len(cnfRenew) > 0 Then AutoOpenControls: cnfRenew = .Name
  End With
End Sub



Private Sub App_SheetBeforeDoubleClick(ByVal Sh As Object, _
ByVal Target As Range, Cancel As Boolean)
  'App.ScreenUpdating = False ' ВЫКЛ Обновление экрана
  If Sh.CodeName = SUPP And Not IsEmpty(Sh.Cells(Target.Row, 10)) _
  And Target.Row > 1 And Target.Column <= 15 Then ' rev.400
    With UnprotectSheet(ThisWb.Sheets(Sh_List(ARCH)))
      .Activate: .Visible = xlSheetVisible
      If ActiveSheet.CodeName = .CodeName And Not IsEmpty(.Cells(1, 10)) Then
        .Cells(1, 10).Select
        .Range("A1:O4").AutoFilter Field:=10, Criteria1:=Sh.Cells(Target.Row, 10)
        ActiveWindow.ScrollRow = 1: ActiveWindow.ScrollColumn = 1 ' CTRL+HOME
      Else
        Sh.Activate: Cancel = True ' Отменяем событие "Двойной клик"
      End If
    End With: ProtectSheet ThisWb.Sheets(Sh_List(ARCH))
  End If
  Stop
  If Sh.CodeName Like SHEETS_ALL And Target.Locked Then _
    Cancel = True: SendKeys "{F2}", False ' rev.250 Фокус должен быть на MS Excel
    'If Target.AllowEdit Then MsgBox ' ЗАМЕНИТЬ! rev.370
  'App.ScreenUpdating = True ' ВКЛ Обновление экрана
End Sub

Private Sub App_SheetBeforeRightClick(ByVal Sh As Object, _
ByVal Target As Range, Cancel As Boolean)
  If Target.Worksheet.CodeName = Sh.CodeName Then ' Если лист тот же
    ' Проверка выделения
    If Not Intersect(Target, Sh.Range("A:A")) Is Nothing _
    And Sh.Cells.Columns.Count = Target.Cells.CountLarge Then
      Count = -1 * Target.Row
      ' Если «Разрешено включать» = Пусто, то разблокировать строку
      If (Sh.CodeName = SUPP And (IsEmpty(Sh.Cells(Target.Row, 10)) _
        Or IsEmpty(Sh.Cells(Target.Row, 15)))) _
      Or (Sh.CodeName = "SF_" And IsEmpty(Sh.Cells(Target.Row, 18))) _
      Or (Sh.CodeName = "SB_" And IsEmpty(Sh.Cells(Target.Row, 18))) Then _
        Sh.Rows(Target.Row).Locked = False ' Снять защиту ячеек rev.360
    End If
  End If
End Sub

' Процедура App_SheetChange может выполняться 2-й раз
Private Sub App_SheetChange(ByVal Sh As Object, ByVal Target As Range)
'  Debug.Print "+ Row ="; Target.Row; " Column ="; Target.Column
  If Target.Worksheet.CodeName = Sh.CodeName Then ' Если лист тот же
    If Sh.CodeName Like SHEETS_ALL And Target.Row > 1 Then
      ' 18/04/2014 Автопростановка "Разрешено включать" по оперативному договору
      If Not IsEmpty(Sh.Cells(Target.Row, 8)) And Target.Column = 19 Then
        If Sh.Cells(Target.Row, Target.Column) = "опер." Then _
          Sh.Cells(Target.Row, 20) = Sh.Cells(Target.Row, 12) _
        Else Sh.Cells(Target.Row, 20).ClearContents
      End If
      ' 08/12/2014 Удаление всех символов, кроме цифр rev.390
      If Sh.CodeName = "SF_" And Target.Column > 24 And Target.Column < 46 Then
        If Not IsArray(Target) And Not Target.HasFormula Then ' Если не массив
          Count = Replace(Val(Target.Value), "-", "")
          If Not Target = Count Then Target = Count
        End If
      End If
      If App.CountA(Sh.Range(Sh.Cells(Target.Row, 31), _
        Sh.Cells(Target.Row, 33))) > 2 And Sh.Cells(Target.Row, 34) < 1 Then _
        If IsEmpty(Sh.Cells(Target.Row, 24)) Then Sh.Cells(Target.Row, 24) = _
        "не оплач." ' Автопростановка "не оплач." rev.390
    End If
  End If
  If ActiveSheet.CodeName Like "S[BF]_" And Target.Column = 29 Then ' rev.400
    With ThisWb.Sheets(Sh_List(IIf(Sh.CodeName = "SF_", "SB_", "SF_")))
      If Len(.Range("E2")) > 0 Then Clipboard_RangeAddress = .Range("E1") _
        .End(xlDown).Offset(1, 0).address Else Clipboard_RangeAddress = "$E$2"
      If .Range(Clipboard_RangeAddress).AllowEdit And WorksheetFunction.Sum( _
        Target.Offset(, -3).Resize(1, 4)) = Target.Offset(, -4) _
      And Target > 0 Then
        If MsgBox("Указано '" & Target & "' переходящих материала в " _
          & IIf(.CodeName = "SF_", "КФ", "БО") & ". " & vbCrLf _
          & "Добавить новую партию в " & IIf(.CodeName = "SF_", "КФ", "БО") _
          & "? ", 260 + 48, "Добавление партии") = vbYes Then ' rev.400
          Sh.Range("AX" & PartNumRow).Copy _
            Destination:=.Cells(.Range(Clipboard_RangeAddress).Row, 50)
          Sh.Range("AC" & PartNumRow).Copy _
            Destination:=.Cells(.Range(Clipboard_RangeAddress).Row, 25)
          Sh.Range("E" & PartNumRow & ":G" & PartNumRow).Copy _
            Destination:=.Range(Clipboard_RangeAddress)
          Clipboard_RangeAddress = .Range("F1").End(xlDown).address
          .Activate: .Range(Clipboard_RangeAddress).Select ' Костыль
          .Cells(PartNumRow, 2).NumberFormat = "@" ' Костыль
        End If
      End If: If Not .Range(Clipboard_RangeAddress).AllowEdit Then _
        ErrCollection 5, 3, 16, Clipboard_RangeAddress & " на листе '" & .Name
    End With
  End If
End Sub

Private Sub App_SheetSelectionChange(ByVal Sh As Object, ByVal Target As Range)
'Dim cell As Range ' Не работает при выборе из списка
  If Count < 0 Then Sh.Rows(Abs(Count)).Locked = True: Count = 0 ' Защита ячеек
  If Sh.CodeName = SUPP And Target.Column = 15 Then Exit Sub ' rev.360
  
  'Application.ScreenUpdating = False ' ВЫКЛ Обновление экрана
  If Sh.CodeName = SUPP And SuppNumRow <> Target.Row Then
    If IsArray(SuppDiff) And SuppNumRow > 1 Then RecordCells CheckSupplier
    ' Создаём массив с изменениями о поставщике rev.310
    If Not SuppNumRow = Selection.Row Then SuppDiff = Empty
    App_SheetActivate Sh ' Костыль
  End If
  If Sh.CodeName = SUPP And Target.Row > 1 Then ' rev.360
    If Target.Column = 11 And Not IsEmpty(Sh.Cells(Target.Row, 10)) Then _
      UnprotectSheet Sh: ListCost Sh, Target.Row: ProtectSheet Sh
    'Debug.Print SuppNumRow; " "; Selection.Row
    '' Создаём массив с изменениями о поставщике rev.310
    'If Not SuppNumRow = Selection.Row Then SuppDiff = Empty
    'App_SheetActivate Sh ' Костыль
  End If
  
  If Sh.CodeName Like SHEETS_ALL And Target.Row > 1 Then
    If (Target.Column = 5 Or Target.Column = 19 Or Target.Column = 50) _
    And Not IsEmpty(Sh.Cells(Target.Row - 1, 5)) Then ' rev.390
      ' And IsEmpty(Sh.Cells(Target.Row, 5)) ' ОШИБКА! В прошлых записях нет списка rev.330
      UnprotectSheet Sh ' Форма договора rev.310
      With Sh.Cells(Target.Row, 5).Validation
        .Delete: .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
          Formula1:="=" & SUPP_LIST  ' Добавляем список в ячейку
        .ErrorTitle = "Поставщик (кратко)"
        .ErrorMessage = "Необходимо выбрать значение из списка "
        .ShowError = True: .IgnoreBlank = True
      End With
      With Sh.Cells(Target.Row, 19).Validation
        .Delete: .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
          Formula1:=CONTROFORM_LIST
        .ErrorTitle = "Форма договора"
        .ErrorMessage = "Необходимо выбрать значение из списка "
        .IgnoreBlank = True: .InCellDropdown = True
        .Parent.Locked = False
      End With
      With Sh.Cells(Target.Row, 50).Validation ' rev.390
        .Delete: .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
          Formula1:=Replace(EXTRA_LIST, "$", "Срочно ")
        .ErrorTitle = "Срочно"
        .ErrorMessage = "Необходимо выбрать значение из списка "
        .IgnoreBlank = True: .InCellDropdown = True
        .Parent.Locked = False
      End With: ProtectSheet Sh ' rev.330
    End If
    
    PartNumRow = Target.Row ' rev.380
    If (Target.Column = 6 Or Target.Column = 7) And PartNumRow > 1 Then
      If Sh.Range(Clipboard_RangeAddress).Column > 5 Then
        App.ScreenUpdating = False ' ВЫКЛ Обновление экрана
        If Not IsEmpty(Sh.Cells(Target.Row, 5)) Then _
          CostUpdate Sh.Cells(Target.Row, 5) ' Костыль And SuppNumRow > 0
      End If: cnfRenew = Sh.Name
    Else: CostChanged ' Необходимость обновить статистику rev.340
    End If ': PartNumRow = Target.Row ' Перенесено выше
  End If: AutoOpenControls ' rev.330
  'Application.ScreenUpdating = True ' ВКЛ Обновление экрана
  Clipboard_RangeAddress = Selection.address ' Для буфера
End Sub