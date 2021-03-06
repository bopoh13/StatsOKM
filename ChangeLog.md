﻿### Условные обозначения

:exclamation: Новое, :fire: Исправлено, :star: Расширено, :star2: Оптимизировано, :grey_question: Тестовая версия

### r420

:star: Модуль ***Statistics.bas***
- :star: Функция `CostChanged`: сообщение с предложением обновить цены после изменения в файле с ценами
- :fire: Процедура `CostUpdate`: изменить условия завершения процедуры
- :fire: Процедура `SpecificationSheets`: небольшие изменения в форматировании ячеек; изменены условия выполнения процедуры `SortSupplier`; переместить курсор на последнюю строку (ошибка #r400)
- :star2: Функция `CheckSupplier`: текст сообщения при изменении данных в колонке "*Дата актуальности*"
- :grey_question: Процедура `ListCost`: изменить условия формирования списка
- :grey_question: Функция `GetSuppRow`: изменить тип параметра `PartDate`

:exclamation: Модуль ***Frame.bas***
- :exclamation: Функция `ClearSpacesInText`: удалить непечатаемые символы и двойные пробелы
- :star: Процедура `SendKeysCtrlV`: собрать данные из колонки в массив **Get_Supp**, затем перед вставкой нескольких строк на листе `SUPP_` вернуть строки из массива кроме первой
- :star: Процедура `SettingsStatistics`: скрыть лист с настройками
- :star: Процедура `ErrCollection`: удалить сообщение об изменении в файле с ценами; добавить сообщение о попытке вставить диапазон ячеек

:fire: Класс ***cExcelEvents.cls***
- :fire: Процедура `App_SheetActivate`: не изменять значение переменной `PartNumRow` на листе `ARCH_`
- :fire: Процедура `App_SheetChange`: проверить данные из буфера обмена перед вставкой (отладка, выполняется в процедуре `SendKeysCtrlV`); присвоить `Clipboard_RangeAddress` значение новой строки (ошибка #r410)

:star: Модуль ***AutoModuleRibbon.bas***
- :star: Процедура `GetEnabledMacro`: изменить условия проверки
- :star: Процедура `AutoOpenControls`: завершать выполнения процедуры при отсутствии объекта
- :fire: Процедура `ShowCosts`: добавить условия проверки в сообщение с ценами (ошибка #r410)

### r410

:fire: Модуль ***Statistics.bas***
- :star: Процедура `Auto_Open`: сортировка данных из файла с ценами по возрастанию, т.к. таблицы могут быть не отсортированы
- :star: Функция `CostChanged`: изменить условия проверки
- :grey_question:  Процедура `CostUpdate`: добавить временную переменную `TEMP_COUNT` для смены номера колонки; исправить условия (ошибка #r390); добавить условия для новых листов
- :fire: Процедура `SpecificationSheets`: небольшие изменения в форматировании ячеек; добавить форматирование ячеек для новых листов
- :fire: Функция `CheckSupplier`: проверять массив **SuppDiff** целиком; проверка изменения данных в колонке "*Дата актуальности*"
- :fire: Функция `GetCosts`: добавить проверку подсчёта записей в коллекцию **Cost** (аналогично функция `GetDateAndCosts`)

:fire: Модуль ***Frame.bas***
- :fire: Свойство `Quit`: восстановить панель контекстного меню для строки перед проверкой
- :fire: Процедура `SettingsStatistics`: условия создания коллекции
- :grey_question: Функция `GetSheetList`: методы делегированы процедуре `GetSheetIndex`
- :star: Процедура `ErrCollection`: сообщение об отсутствии таблицы в файле с ценами

:fire: Класс ***cExcelEvents.cls***
- :star: Процедура `App_WorkbookActivate`: удалить панель в меню строки
- :fire: Процедура `App_SheetActivate`: исправить ошибки при работе с массивом **SuppDiff**
- :grey_question: Процедура `App_SheetChange`: список листов заменен на `SF_` и `SB_` (отладка); ошибка присвоении переменной `Clipboard_RangeAddress` при отсутствии записей (отладка)
- :grey_question: Процедура `App_SheetSelectionChange`: список листов заменен на `QT_` и `QB_` (отладка); добавлены проверки для новых листов

:fire: Модуль ***AutoModuleRibbon.bas***
- :grey_question: Процедура `AutoOpenControls`: установить таймер для обновления ленточного меню при открытии книги
- :fire: Процедура `ShowCosts`: выполнить функцию `GetDateAndCosts` (ошибка #r400)

### r400

:exclamation: Записать константы прописными буквами

:star: Модуль ***Statistics.bas***
- :star2: Процедура `Auto_Open`: после открытия текущей книги присвоить статус "сохранено"
- :star2: Процедура `SpecificationSheets`: перед выполнением отключить события; переместить курсор на последнюю строку (возникает исключение при единственной записи)
- :star2: Функция `GetCosts`: перед выполнением отключить обновление экрана
- :grey_question: Функция `GetDateAndCosts`: дополнительные проверки для выборки цен поставщика (отладка)

:fire: Модуль ***Frame.bas***
- :star: Свойство `Quit`: разворачивать окно приложения (на весь экран)
- :star: Процедура `SettingsStatistics`: добавить коллекцию `K_List` для сбора данных о колонках листов `SF_` и `SB_`
- :star: Процедура `ErrCollection`: сообщение о пустой таблице в файле с ценами

:fire: Класс ***cExcelEvents.cls***
- :fire: Процедура `App_WorkbookBeforeSave`: выполнить процедуру `SpecificationSheets` (ошибка #r380)
- :fire: Процедура `App_SheetActivate`: `Sh` заменить => на `ActiveSheet` (ошибка #r390)
- :grey_question: Процедура `App_SheetBeforeDoubleClick`: дополнительные проверки индекса колонки и листа; отключить обновление экрана
- :fire: Процедура `App_SheetChange`: отобразить в сообщении лист `SF_` или `SB_`

:star: Модуль ***AutoModuleRibbon.bas***
- :star: Процедура `RefreshRibbon`: защита от изменений листа в случае отказа макросов из-за ленточного меню
- :grey_question: Процедура `ShowCosts`: сообщение с ценами больше нуля (отладка)

### r390

:exclamation: Файл ленточного меню ***customUI14.xml***: добавить Alt-клавиши и кнопку для просмотра цен поставщика

:star: Колонки "*Переходящих в Бюджет*", "*Направленных в Финансист*"; переместить колонку "*Кол-во поступивших материалов*" <= перед "*Направленных в БПК*"

:fire: Модуль ***Statistics.bas***
- :exclamation: Функция `GetDateAndCosts`: поиск цен поставщика и передача процедуре `ShowCosts`
- :fire: Процедура `CostUpdate`: проверка при пересчёте итоговых сумм
- :grey_question: Процедура `SpecificationSheets`: добавить проверку для переходящих материалов; небольшие изменения в форматировании ячеек
- :fire: Функция `GetCosts`: если цена за предыдущей период, то нужно изменить переменные `SuppNumRow` и `cnfRenew`; добавить цены для листа `SB_`

:fire: Модуль ***Frame.bas***
- :fire: Свойство `Quit`: восстановить панели перед проверкой
- :star: Процедура `ErrCollection`: сообщение о невозможности создания новой партии

:fire: Класс ***cExcelEvents.cls***
- :grey_question: Процедура `App_WorkbookBeforeClose`: отменить удаление объекта `App`
- :fire: Процедура `App_SheetActivate`: `Sh` заменить => на `ActiveSheet`; очистить массив **SuppDiff**
- :grey_question: Процедура `App_SheetBeforeDoubleClick`: отключать кнопки фильтров на листе `ARCH_`; курсор на первую ячейку
- :star: Процедура `App_SheetChange`: сообщение с предложением перенести переходящие материалы в другой лист

:exclamation: Модуль ***AutoModuleRibbon.bas***
- :exclamation: Процедура `GetEnabledMacro`: активировать кнопку для просмотра цен поставщика
- :exclamation: Процедура `ShowCosts`: сообщение с ценами поставщика

### r380

:exclamation: Переименовать колонки "*НУМ*" => "*Всего НУМ*", "*ИТОГО Финансист*" => "*ИТОГО КФ*"

:exclamation: Создать массив **Get_Supp** для отслеживания изменений данных поставщика

:exclamation: Модуль ***Statistics.bas***
- :exclamation: Функция `GetSuppRow`: поиск строки о поставщике по данным из массива **Get_Supp**
- :star: Процедура `CostUpdate`: создать формулы в строке с поставщиком на листах `SF_` и `SB_`
- :grey_question: Функция `SetFormula`: удалить, методы делегированы процедуре `CostUpdate`
- :fire: Процедура `SpecificationSheets`: небольшие изменения в форматировании ячеек
- :star2: Функция `GetCosts`: добавить параметры; использовать массив **Get_Supp** для выборки данных о текущем поставщике
- :grey_question: Процедура `GetSuppRow`: удалить, методы делегированы функции `GetSuppRow`

:fire: Модуль ***Frame.bas***
- :fire: Процедура `SendKeyEnter`: объект `Wb` заменить => на `ActiveWorkbook`
- :star: Функция `GetSheetList`: добавить проверку присутствия объекта `ThisWb`; добавить в коллекцию индекс листа с типом "байт"
- :star2: Процедура `SettingsStatistics`: добавить в коллекцию тип даты в местном формате

:fire: Класс ***cExcelEvents.cls***
- :grey_question: Процедура `App_WorkbookBeforeClose`: удалить процедуру `SpecificationSheets`
- :fire: Процедура `App_SheetSelectionChange`: удалить процедуру `GetSuppRow`; удалить функцию `SetFormula`; присвоить переменной `PartNumRow` номер строки до определения номера текущей колонки

### r370

:exclamation: Глобальную переменную `App_Wb` переименовать => в `ThisWb`

:fire: Модуль ***Statistics.bas***
- :fire: Процедура `SpecificationSheets`: исправить маску "*ИНН*"; проверка нового поставщика, запреть ввод существующего имени
- :grey_question: Процедура `SendKeyEnter`: переместить в модуль ***Frame.bas*** (аналогично процедура `SendKeysCtrlV`)

:exclamation: Модуль ***Frame.bas***
- :exclamation: Процедура `SendKeyEnter`: выполнить нажатие клавиши <kbd>Enter</kbd> только для текущей книги
- :exclamation: Процедура `SendKeysCtrlV`: перехват клавиш <kbd>Ctrl+V</kbd> для вставки неформатированного текста только для текущей книги
- :star: Свойство `Quit`: прятать "Параметры вставки" только для текущей книги
- :star: Процедура `ErrCollection`: сообщение об исключении в формуле проверки данных

:fire: Класс ***cExcelEvents.cls***
- :fire: Процедура `App_WorkbookBeforeClose`: прятать "Параметры вставки" только для текущей книги
- :fire: Процедура `App_WorkbookDeactivate`: переменная `CopyMode` контролирует скопированный диапазон ячеек; восстановить "Параметры вставки"

:fire: Модуль ***AutoModuleRibbon.bas***
- :fire: Процедура `SetFilter`: использовать активную ячейку вместо диапазона ячеек

### r360

:exclamation: В список "*Тип организации*" добавить позицию "*Ведомство (без подп.)*"

:star2: Перемесить колонку "*Дата актуальности*" <= перед "*Категория цены*"

:fire: Модуль ***Statistics.bas***
- :star: Процедура `SpecificationSheets`: переменной `LastRow` присвоить значение последней строки на листе; проверка дат на листах `SF_` и `SB_`; небольшие изменения в форматировании ячеек
- :fire: Процедура `RecordCells`: изменения в массиве **SuppDiff** и параметрах процедуры `SortSupplier` из-за перестановки колонок
- :fire: Функция `CheckSupplier`: изменения в массиве **SuppDiff** из-за перестановки колонок
- :fire: Функция `ChangedBeforeSave`: изменения в массиве **SuppDiff** из-за перестановки колонок
- :fire: Процедура `ListCost`: небольшие изменения из-за перестановки колонок (аналогично процедура `SuppNumRow`)
- :fire: Функция `GetCosts`: небольшие изменения из-за перестановки колонок
- :star2: Процедура `SendKeysCtrlV`: проверка наличия неформатированного текста в буфере

:star: Модуль ***Frame.bas***
- :star: Свойство `Quit`: отображать *[Только для чтения]* в заголовке
- :star: Процедура `ErrCollection`: сообщение об исключении в формуле условного форматирования

:fire: Класс ***cExcelEvents.cls***
- :fire: Процедура `App_SheetBeforeRightClick`: небольшие изменения из-за перестановки колонок (аналогично процедура `App_SheetSelectionChange`)
- :star: Процедура `App_SheetChange`: удалить все символы, кроме натуральных чисел; автопростановка "*не оплач.*" в колонке "*Дата перечислений*"

### r350

:fire: Модуль ***Statistics.bas***
- :grey_question: Функция `SetFormula`: создать формулы в строке с поставщиком на листах `SF_` и `SB_`
- :star2: Процедура `SpecificationSheets`: выполнить функцию `ErrCollection` в случае появления исключения; очистить границы ячеек; изменения в форматировании и группировки ячеек, переместить курсор на последнюю строку

:star: Модуль ***Frame.bas***
- :star: Процедура `ErrCollection`: сообщение о невозможности создания условного форматирования

:fire: Класс ***cExcelEvents.cls***
- :grey_question: Процедура `App_SheetChange`: *отдельно для каждого листа*
- :star2: Процедура `App_SheetSelectionChange`: выполнить функцию `SetFormula`; добавить выпадающий список

### r340

:exclamation: Модуль ***Statistics.bas***
- :exclamation: Функция `CostChanged`: проверить изменения файла с ценами
- :exclamation: Процедура `CostUpdate`: пересчитать формулы для поставщика
- :star: Процедура `Auto_Open`: цены "*Бухонлайн*" объединить с ценами "*Кодекс*"; добавить свойство `Quit`
- :fire: Процедура `SpecificationSheets`: небольшие изменения в форматировании ячеек
- :star2: Процедура `RecordCells`: выполнить процедуру `CostUpdate`; добавить свойство `Quit`
- :grey_question: Функция `GetCosts`: переменную `OrgBody` вынести из параметров функции в локальную
- :star2: Процедура `GetSuppRow`: удалить проверку с сообщением об исключении

:exclamation: Модуль ***Frame.bas***
- :exclamation: Свойство `Quit`: изменить "Параметры вставки" для текущей книги
- :star: Процедура `ErrCollection`: сообщение о изменении в файле с ценами; добавить свойство `Quit`
- :star2: Функция `GetSheetList`: добавить свойство `Quit`

:star: Класс ***cExcelEvents.cls***
- :star: Процедура `App_SheetActivate`: на листах кроме `SUPP_` и `ARCH_` присвоить `PartNumRow` 
- :star: Процедура `App_SheetSelectionChange`: на листах `SF_` и `SB_` изменить условия выпадающих списков
- :star: Процедура `App_SheetSelectionChange`: выполнить функцию `CostChanged`
- :star2: Процедура `App_WorkbookActivate`: добавить свойство `Quit`
- :star2: Процедура `App_WorkbookBeforeClose`: добавить свойство `Quit`
- :star2: Процедура `App_WorkbookBeforeSave`: добавить свойство `Quit`
- :star2: Процедура `App_WorkbookDeactivate`: добавить свойство `Quit`

### r330

:exclamation: Модуль ***Statistics.bas***
- :exclamation: Процедура `SendKeysCtrlV`: перехват клавиш <kbd>Ctrl+V</kbd>
- :fire: Процедура `SpecificationSheets`: небольшие изменения в форматировании ячеек
- :star2: Процедура `Auto_Open`: проверка существования пути файла с ценами

:exclamation: Модуль ***Frame.bas***
- :exclamation: Процедура `SettingsStatistics`: сетевой путь в коллекцию с настройками
- :star: Процедура `ErrCollection`: сообщение о необходимости выбрать поставщика

:star: Класс ***cExcelEvents.cls***
- :star: Процедура `Class_Initialize`: задать горячие клавиши процедурой `SendKeysCtrlV`
- :star2: Процедура `App_WorkbookDeactivate`: копировать выделенный диапазон
- :grey_question: Процедура `App_SheetSelectionChange`: на листах `SF_` и `SB_` изменить выпадающий список

:exclamation: Модуль ***AutoModuleRibbon.bas***
- :exclamation: Процедура `GetVisibleMenu`: отображать рабочую вкладку меню только для текущей книги
- :exclamation: Процедура `SetFilter`: управлять кнопками фильтров на вкладке меню; удалить процедуру `AddFilter`

### r320

:exclamation: Модуль управления меню ***AutoModuleRibbon.bas***

:grey_question: Файл ленточного меню ***customUI14.xml***

:star: Колонки "*Дата материала*", "*Форма договора*", "*Кодекс*" на листах `SF_` и `SB_`

:star2: Переставить колонки "*Дата акта*" <=> "*Номер акта*", "*Дата договора*" <=> "*Номер договора*"

### r310

:star: Модуль ***Statistics.bas***
- :star: Функция `CheckSupplier`: обновить массив **SuppDiff**

:star: Класс ***cExcelEvents.cls***
- :star: Процедура `App_SheetActivate`: обновить массив **SuppDiff**
- :star: Процедура `App_SheetSelectionChange`: для листа `SUPP_` создать массив **SuppDiff**

### r300

:grey_question: Шаблон книги ***blank r300.xlsx***: тестирование производится на первых 5 листах

:exclamation: Основной модуль ***Statistics.bas***
- :exclamation: Процедура `Auto_Open` (автозапуск): создать системную таблицу и загрузить файл с ценами через `ADODB`
- :grey_question: Процедура `SpecificationSheets`: восстановить форматирование таблиц
- :exclamation: Процедура `RecordCells`: записать на лист `ARCH_` данные о поставщике из массива **SuppDiff**
- :exclamation: Функция `CheckSupplier`: проверить изменения на листе `SUPP_` в массиве **SuppDiff**
- :exclamation: Функция `ChangedBeforeSave`: для класса ***cExcelEvents.cls***
- :exclamation: Процедура `ListCost`: создать список "*Категория цен*"
- :exclamation: Функция `GetCosts`: вернуть цены на актуальную дату
- :exclamation: Процедура `GetSuppRow`: поиск строки на листе `ARCH_`
- :grey_question: Процедура `SendKeyEnter`: выполнить нажатие клавиши <kbd>Enter</kbd>

:exclamation: Дополнительный модуль ***Frame.bas***
- :exclamation: Свойство `GetUserName`: читать имя активного пользователя
- :exclamation: Процедура `SettingsStatistics`: создать коллекцию с настройками
- :exclamation: Функция `GetSheetList`: обновить коллекцию с индексами листов и вернуть индекс листа по имени
- :exclamation: Процедура `ProtectSheet`: защитить лист от изменений
- :exclamation: Функция `UnprotectSheet`: снять защиту с листа и вернуть сам объект
- :exclamation: Процедура `SortSupplier`: выполнить сортировку по возрастанию по номеру колонки
- :exclamation: Процедура `RemoveCollection`: удалить все строки в коллекции
- :exclamation: Функция `MultidimArr`: заполнить одномерный массив из двумерного
- :exclamation: Процедура `ErrCollection`: добавить сообщения об исключении по номеру и маркеру

:exclamation: Класс событий книги ***cExcelEvents.cls***
- :exclamation: Процедура `Class_Initialize`: объявить приложение `App`; задать горячие клавиши процедурой `SendKeyEnter`
- :exclamation: Процедура `App_WorkbookOpen`: не используется
- :exclamation: Процедура `App_WorkbookActivate`: направить перемещение курсора "*вправо*"
- :exclamation: Процедура `App_WorkbookBeforeClose`: выполнить процедуру `RecordCells`
- :exclamation: Процедура `App_WorkbookBeforeSave`: выполнить процедуры `RecordCells` и `SpecificationSheets`
- :exclamation: Процедура `App_WorkbookDeactivate`: направить перемещение курсора "*вниз*" и выполнить процедуру `RecordCells`
- :exclamation: Процедура `App_SheetDeactivate`: *отдельно для каждого листа*
- :exclamation: Процедура `App_SheetActivate`: на лист `ARCH_`
- :grey_question: Процедура `App_SheetBeforeDoubleClick`: переключить с листа `SUPP_` на лист `ARCH_`
- :grey_question: Процедура `App_SheetBeforeRightClick`: запретить удаление строк
- :exclamation: Процедура `App_SheetSelectionChange`: *отдельно для каждого листа*

### r200

:exclamation: Модуль ***DBCreateMDWSystem.bas***: создаёт системную таблицу ***System.mdw*** если не установлен **Access**

### r100

:grey_question: Разработана структура файла с ценами ***Cost.accdb***
