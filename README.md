# RV32I
[![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&lines=My+first+processor)](https://git.io/typing-svg)

## Цель
Описать на языке Verilog рабочий процессор с архитектурой `RISC-V`, реализовать его тракт данных, используя разработанные блоки, которые рассмотрим ниже, подключить к нему устройство управления. Реализовать поддержку обработки не только слов, но и инструкций связанных с байтами и полусловами: `lh`, `lhu`, `lb`, `lbu`, `sh`, `sb`. Добавить `обработку прерываний`. Использовать САПР Vivado 2019.2.

## Микроархитектура
![image](https://user-images.githubusercontent.com/112335356/212677858-d09f6d2c-967e-4b3c-acea-3bf038ef6aa7.png)

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
  
Также присутствует файл define.v (ссылка на код) и файлы инициализации памяти c машинными кодами инструкций (программ для исполнения) - [example 1](https://github.com/SignComet/RV32I/blob/main/rtl/Example_1_square.txt), [example 2](https://github.com/SignComet/RV32I/blob/main/rtl/Example_2_LSU.txt) и [example 3](https://github.com/SignComet/RV32I/blob/main/rtl/Example_3_Interrupt.txt). 

## Структура модуля [miriscv_top](https://github.com/SignComet/RV32I/blob/main/rtl/miriscv_top.sv)
Топовый файл, в котором объединяется ядро, память и контроллер прерываний.
![image](https://user-images.githubusercontent.com/112335356/212678055-108ab529-203f-406c-bf8c-426b95749d3e.png)

## [PC](https://github.com/SignComet/RV32I/blob/main/rtl/PC.v)
`Program counter`- счётчик команд c синхронным сигналом сброса и синхронным сигналом разрешения. Т.к. адресация побайтовая (слово 32 бита - 4 байта), то прибавляем для перехода pc = pc + 4, чтобы перейти к следующему слову (если это не операция управления).

## [main_decoder](https://github.com/SignComet/RV32I/blob/main/rtl/main_decoder.v)
Комбинационная логика. По полю `opcode` устройство управления понимает, что нужно сделать процессору, что требует от него данная инструкция и каким именно способом она закодирована (`R`, `I`, `S`, `B`, `U` или `J`). Поля `Func3` и `Func7` также уточняют, что конкретно требуется от процессора сейчас. 

![image](https://user-images.githubusercontent.com/112335356/212678108-1b506b08-7c31-4c8e-87ce-e7331d62f17a.png)

![image](https://user-images.githubusercontent.com/112335356/212678162-16dc7455-5ec2-4052-a595-e58a426a220a.png)

![image](https://user-images.githubusercontent.com/112335356/212678200-cbc14997-95a9-483d-a042-3c5309e671a0.png)

Также реализована инструкция NOP.

## [RF](https://github.com/SignComet/RV32I/blob/main/rtl/RF.v)
`Register File`- регистровый файл. Представляет собой трехпортовую ОЗУ с двумя портами на чтение и одним портом на запись. Состоит из 32-х 32-битных регистров, при этом по адресу 0 всегда должен выдаваться 0. Асинхронное чтение.

<img src="https://user-images.githubusercontent.com/112335356/212564444-1b5345be-eb5a-4d0b-97cb-0b2b3e081090.png" width="200" height="200">

## [АЛУ](https://github.com/SignComet/RV32I/blob/main/rtl/ALU.v)
`Арифметико-логическое устройство`. Содержит стандартную комбинационную логику, удовлетворяющую АЛУ RISC-V, сумматор реализован самостоятельно как сумматор с последовательным переносом и добавлен в case.

![image](https://user-images.githubusercontent.com/112335356/212678280-f95323ff-631d-4b1e-abdf-8a284e4f373a.png)

### [fulladder](https://github.com/SignComet/RV32I/blob/main/rtl/fulladder.v)
`Cумматор` с последовательным переносом, реализован с дублированием блока полного сумматора adder(ссылка) с помощью конструкции generate. 

## [LSU](https://github.com/SignComet/RV32I/blob/main/rtl/LSU.v)
`Load/Store Unit`- блок загрузки/сохранения. Прослойка между памятью (внешним устройством) и ядром. Без него процессор работал только со словами, не оптимальное использование памяти. Теперь мы можем читать/записывать слова, полуслова, байты. Знаковое/беззнаковое число имеет значение только для операции LOAD. Знаковое - используется расширение знака (`sign extension`) до 32 бит, беззнаковое - разширяем нулями (`zero extension`).

![image](https://user-images.githubusercontent.com/112335356/212678529-f2351669-9c3f-49c2-b1ad-de3b2aa95eec.png)

![image](https://user-images.githubusercontent.com/112335356/212678581-182b4584-0c8a-45ae-99e1-144161867175.png)

![image](https://user-images.githubusercontent.com/112335356/212678632-1fa66b15-df4e-4f39-b675-061081d4020f.png)

![image](https://user-images.githubusercontent.com/112335356/212678676-8a5626f7-0515-4ba0-b616-a2e041686f10.png)

## [CSR](https://github.com/SignComet/RV32I/blob/main/rtl/CSR.v)
`Control and Status Registrs`. Данные регистры обеспечивают управление элементами процессора и доступ к статусной информации о системе. Для реализации простейшей системы прерываний на процессоре с архитектурой RISC-V нам достаточно 5-ти CSR регистров, работающих в самом привилегированном режиме - `машинном` и 4 инструкции специальные инструкции `SYSTEM`. Часто используют псевдоинструкции для упрощения программирования на языке ассемблера.

![image](https://user-images.githubusercontent.com/112335356/212678761-8f27832a-58f4-4c63-a8ba-8c0e492e7b0c.png)

![image](https://user-images.githubusercontent.com/112335356/212678804-50de24a0-a869-4ce5-9b6b-f73f4c391343.png)

![image](https://user-images.githubusercontent.com/112335356/212678856-008a922c-0205-483b-b8b0-9357712b4ce0.png)

Реализация CSR блока

![image](https://user-images.githubusercontent.com/112335356/212678938-504f6387-b155-4348-b5eb-d381a5fafb53.png)

## [miriscv_ram](https://github.com/SignComet/RV32I/blob/main/rtl/miriscv_ram.sv)
`Общая память для команд и данных`. Изначально, до добавления блока LSU, было две отдельные памяти - память инструкций и память данных. 

## [Interrupt_Controller](https://github.com/SignComet/RV32I/blob/main/rtl/Interrupt_Controller.v)
<img src="https://user-images.githubusercontent.com/112335356/212568124-67df7351-efe2-40a9-b28a-15c6aad6da11.png" width="250" height="200">

В основе `контроллера прерываний с циклическим опросом` лежит счётчик, выход которого одновременно является кодом причины прерывания mcause, подаётся на вход дешифратора. Дешифратор выдаёт 1 только на соответствующем входе. Счётчик работает по кругу до тех пор пока не наткнётся на незамаскированное прерывание. В данной реализации нет приоритетов, нельзя изменить маску.

![image](https://user-images.githubusercontent.com/112335356/212679034-c2d35203-35b9-4f18-bd5a-2b245b9ba452.png)

## Пример выполнения простой программы с вычислительными, условными операциями.
`Задание`: рассчитать площадь круга при заданном радиусе с точностью до целого.

[Код на языке ассемблера](https://github.com/SignComet/RV32I/blob/main/asm/Example_1_asm.txt). [Временная диаграмма](https://github.com/SignComet/RV32I/blob/main/waveforms/Example_1.png) . Результаты работы процессора совпадают с компилятором ассемблерных команд https://venus.cs61c.org.

## Пример выполнения программы с инструкциями загрузки/сохранения байт, слов, полуслов
[Код на языке ассемблера](https://github.com/SignComet/RV32I/blob/main/asm/Example_2_LSU_asm.txt). [Временная диаграмма](https://github.com/SignComet/RV32I/blob/main/waveforms/Example%202.png). Результаты работы процессора совпадают с компилятором ассемблерных команд https://venus.cs61c.org.

## Пример выполнения программы с прерываниями
С проверкой данного задания на компиляторе будут проблемы, т.к. компиляторы `Venus` и `Jupiter` в принципе не имеют раздела с CSR, а `RARS` даёт проверять работу только на CSR в пользовательском режиме, т.е. регистры `uie`, `utvec`, `uscratch`, `uepc`, `ucause`. Но для машинного режима компилятор RARS позволил получить машинные коды. К тому же пришлось имитировать прерывания в коде, т.к. настоящих прерываний у нас нет.
`Задание`: выполнить прерывания mcause = 3 и mcause = 5

[Код на языке ассемблера](https://github.com/SignComet/RV32I/blob/main/asm/Example_3_Interrupt_asm.txt). [Временная диаграмма_1](https://github.com/SignComet/RV32I/blob/main/waveforms/Example_3_interr_3.png), [Временная диаграмма_2](https://github.com/SignComet/RV32I/blob/main/waveforms/Example__interr_5.png). Результаты работы процессора совпадают с логикой работы программы.

## Возможные улучшения 
При имплементации процессора в ПЛИС реализация модуля общей памяти забивает саму ПЛИС, а не использует предоставленные блоки памяти. Такая проблема связана с тем, что наша память асинхронная и САПР не может распознать наш код в специальные блоки памяти, т.к. они синхронные. Также если мы захотим провести тесты на процессоре, например, бенчмарк CoreMark, то следует обратить внимание на то, что конкретно проверяет данный тест. Например, одна из проверок - `умножение` матриц, а у нас нет ни одного умножителя, следовательно, результаты теста можно улучшить добавив данный блок. Существует `расширение M` для RISC-V, которое добавляет инструкции целочисленного умножения и деления.

Конечно, самая весомая возможная оптимизация здесь - сделать из однотактного процессора `конвейерный`.

## Сборка проекта
*Vivado->Tools->Run Tcl Script->build.tcl->ОК*.

Далее *Run Synthesis->ОК*.  Дождитесь окончания синтеза. Затем для проведения симуляции проекта: *Run Simulation->Run Bihavioral Simulation`*


[![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&lines=Все+поставленные+цели+достигнуты+!)](https://git.io/typing-svg)
