# RV32I
[![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&lines=My+first+processor)](https://git.io/typing-svg)

## Цель
Описать на языке Verilog рабочий процессор с архитектурой `RISC-V`, реализовать его тракт данных, используя разработанные блоки, которые рассмотрим ниже, подключить к нему устройство управления. Реализовать поддержку обработки не только слов, но и инструкций связанных с байтами и полусловами: `lh`, `lhu`, `lb`, `lbu`, `sh`, `sb`. Добавить `обработку прерываний`. Использовать САПР Vivado 2019.2. Продумать возможные улучшения.

## Микроархитектура
<img src="https://user-images.githubusercontent.com/112335356/212536013-24666b48-e89a-459a-bd5a-1c3a316976f7.png" width="1000" height="550">

## Иерархия проекта
+ miriscv_top 
  + core: PROCESSSOR
    + PC
    + main_decoder
    + RF
    + CSR
    + ALU
      + fulladder
    + LSU
  + ram:  miriscv_ram
  + IC: Interrupt_Controller
Также присутствует файл с define.v (ссылка на код) и файлы инициализации памяти для загрузки инструкций (программ для исполнения) - example 1, example 2 и example 3. (ссылка на код) 

## Структура модуля miriscv_top (ссылка на код)
Топовый файл, в котором объединяется ядро, память и контроллер прерываний. В коде также добалена ....поступление "реальных" прерываний

<img src="https://user-images.githubusercontent.com/112335356/212535165-4594f483-cd49-4ff4-87fe-28db2cb5715d.png" width="700" height="500">

## PC (ссылка на код)
`Program counter`, счётчик команд c синхронным сигналом сброса и синхронным сигналом разрешения. Т.к. адресация побайтовая (слово 32 бита - 4 байта), то прибавляем для перехода pc = pc + 4, чтобы перейти к следующему слову (если это не операция управления).

## main_decoder (ссылка на код)
Комбинационная логика. По полю `opcode` устройство управления понимает что требуется сделать процессору, что требует сделать инструкциял, каким именно способом закодирована (`R`, `I`, `S`, `B`, `U` или `J`). Поля `Func3` и `Func7` также уточняют, что конкретно требуется от процессора сейчас. 

<img src="https://user-images.githubusercontent.com/112335356/212559956-b66c6589-ad85-4311-a4b3-4a171973b6c6.png" width="800" height="200">

<img src="https://user-images.githubusercontent.com/112335356/212560177-a31c475d-7b22-4997-a957-fc80d0788b79.png" width="1000" height="700">

<img src="https://user-images.githubusercontent.com/112335356/212560097-1ddfa54b-6c66-467e-826c-b3400ac7fabb.png" width="800" height="150">

Также реализована инструкция NOP.

## RF (ссылка на код)
`Register File`, регистровый файл. Представляет собой трехпортовую ОЗУ с двумя портами на чтение и одним портом на запись. Состоит из 32-х 32-битных регистров, при этом по адресу 0 всегда должен выдаваться 0. Асинхронное чтение.

<img src="https://user-images.githubusercontent.com/112335356/212564444-1b5345be-eb5a-4d0b-97cb-0b2b3e081090.png" width="200" height="200">

## АЛУ (ссылка на код)
`Арифметико-логическое устройство`. Содержит стандартную комбинационную логику, удовлетворяющую АЛУ RISC-V, сумматор реализован самостоятельно как сумматор с последовательным переносом и добавлен в case

<img src="https://user-images.githubusercontent.com/112335356/212536705-f9a52a50-636a-4d0d-a99f-c5c3338cd9a3.png" width="600" height="450">

### fulladder (ссылка на код)
`Cумматор` с последовательным переносом, реализован с дублированием блока полного сумматора adder(ссылка) с помощью конструкции generate. 

## LSU (ссылка на код)
`Load/Store Unit`, блок загрузки/сохранения. Прослойка между памятью (внешним устройством) и ядром. Без него процессор работал только со словами, не оптимальное использование памяти. Теперь мы можем читать/записывать слова, полуслова, байты. Знаковое/беззнаковое число имеет значение только для операции LOAD. Знаковое - используется расширение знака (`sign extension`) до 32 бит, беззнаковое - разширяем нулями (`zero extension`).

<img src="https://user-images.githubusercontent.com/112335356/212565977-ef742136-19cc-4263-87d8-b286010e618c.png" width="600" height="350">

<img src="https://user-images.githubusercontent.com/112335356/212565983-da042247-2a14-410b-b709-a185a99f11ab.png" width="600" height="200">

<img src="https://user-images.githubusercontent.com/112335356/212565991-09f2a489-218c-4a0e-9dd2-b997d43f640e.png" width="1000" height="500">

<img src="https://user-images.githubusercontent.com/112335356/212566003-4e5d5af5-0f16-4899-aa10-ca66c65da544.png" width="700" height="500">

## CSR (ссылка на код)
`Control and Status Registrs`. Данные регистры обеспечивают управление элементами процессора и доступ к статусной информации о системе. Их необходимо использовать, чтобы реализовать систему прерываний. Для реализации простейшей системы прерываний на процессоре с архитектурой RISC-V нам достаточно 5-ти CSR регистров, работающих в самом привилегированном режиме - `машинном` и 4 инструкции специальные инструкции `SYSTEM`. Часто используют псевдоинструкции для упрощения программирования на ассемблере.

<img src="https://user-images.githubusercontent.com/112335356/212567805-f89d0c76-9e49-4ee5-a5a4-890478d8e9be.png" width="750" height="150">

<img src="https://user-images.githubusercontent.com/112335356/212567830-bcb09c21-839b-443f-a3db-6bc38762da73.png" width="700" height="150">

<img src="https://user-images.githubusercontent.com/112335356/212567861-e0511c0c-f85f-470e-890d-2dbd1ea82932.png" width="750" height="100">

Реализация CSR блока

<img src="https://user-images.githubusercontent.com/112335356/212568046-e146b323-27a7-46d7-9c4d-357df5560773.png" width="700" height="550">


## miriscv_ram (ссылка на код)
Изначально, до добавления блока LSU, было две памяти - инструкций и данных, теперь они объединены в `одну память`, в модуле miriscv_ram. 

## Interrupt_Controller (ссылка на код)
<img src="https://user-images.githubusercontent.com/112335356/212568124-67df7351-efe2-40a9-b28a-15c6aad6da11.png" width="250" height="200">

В основе `контроллера прерываний с циклическим опросом` лежит счётчик, выход которого одновременно является кодом причины прерывания mcause, подаётся на вход дешифратора. Дешифратор выдаёт 1 только на соответствующем входе. Счётчик работает по кругу до тех пор пока не наткнётся на незамаскированное прерывание. В данной реализации нет приоритетов, нельзя изменить маску.

<img src="https://user-images.githubusercontent.com/112335356/212568133-48ea2b05-8463-4e44-b04d-6d7db60cfed8.png" width="700" height="450">

# Пример выполнения простой программы с вычислительными, условными операциями.
`Задание`: рассчитать площадь круга при заданном радиусе с точностью до целого.

Код на языке ассемблера. Временная диаграмма процессора. Результаты работы процессора совпадают с компилятором ассемблера https://venus.cs61c.org.

## Пример выполнения программы с инструкциями загрузки/сохранения байт, слов, полуслов
Код на языке ассемблера. Временная диаграмма процессора. Результаты работы процессора совпадают с компилятором ассемблера https://venus.cs61c.org.

## Пример выполнения программы с прерываниями
С проверкой данного задания на компиляторе будут проблемы, т.к. компиляторы `Venus` и `Jupiter` в принципе не имеют раздела с CSR, а `RARS` даёт проверять работу только на CSR в пользовательском режиме, т.е. регистры `uie`, `utvec`, `uscratch`, `uepc`, `ucause`. Но для машинного режима компилятор RARS позволил получить машинные коды. К тому же пришлось имитировать прерывания в коде, т.к. настоящих прерываний у нас нет.

Код на языке ассемблера. Временная диаграмма процессора. Результаты работы процессора совпадают с логикой работы программы.

## Частота данного процессора . Оптимизация по частоте 

## Возможные улучшения. 
При имплементации процессора в ПЛИС память забивает саму ПЛИС, а не использует предоставленные блоки памяти. Такая проблема связана с тем, что наша память асинхронная и САПР не может распознать наш код памяти в блоки памяти, т.к. они синхронные. Решение - сделать процессор `двухстацийным`. Если мы захотим провести тесты на процессоре , например, CoreMark, то следует обратить на то, что конкретно проверяет данные тест. Например, одна из проверок - `умножение` матриц, а у нас нет ни одного умножителя, следовательно, результаты теста можно улучшить добавив данный блок. Существует `расширение M` для RISC-V, которое добавляет инструкции целочисленного умножения и деления.
Конечно, самое большая возможная оптимизация здесь - сделать из однотактного `конвейерный процессор`.

[![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&lines=Все+поставленные+цели+достигнуты+!)](https://git.io/typing-svg)
