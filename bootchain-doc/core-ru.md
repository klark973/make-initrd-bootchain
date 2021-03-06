# Фича: bootchain-core

`bootchain-core` - форк и дальнейшее развитие оригинальной фичи `pipeline`.
Производная фича, равно как и `pipeline`, последовательно запускает шаги-скрипты
один за другим. Подробности про `pipeline` см. в ../features/pipeline/README.md.

В процессе форка фича `pipeline` была разделена на три части:

- `bootchain-core` - основной функционал фичи `pipeline`, общий код и демон.
- `bootchain-getimage` - метод загрузки ISO-образов по сети утилитой wget.
- `bootchain-waitdev` - метод загрузки с указанных локальных носителей.

Дальнейшая работа над `bootchain` привела к созданию ещё нескольких модулей.
Их перенос в апстрим ожидается в ближайшее время. Такое разделение на модули
позволяет оптимизировать наполнение образа initramfs только необходимым.

## Основные компоненты bootchain-core

- `/bin/bootchain-sh-functions` - общий код, развитие `pipeline-sh-functions`.
- `/sbin/chaind` - демон, развитие `pipelined`, перезапускаемый процесс.
- `/sbin/bootchain-logvt` - скрипт управления вспомогательным терминалом.
- `/etc/rc.d/init.d/bootchain` - стартовый скрипт sysvinit.

## Причины создания форка и переименования pipeline

- Набор модулей `bootchain` разрабатывался с целью создать в stage1 замену
  программы `propagator`, полностью интегрированную в run-time `make-initrd`.
  В исходном варианте фича `pipeline` не удовлетворяла названной потребности.
  На раннем этапе разработки ещё не было известно, какой функционал окажется
  в конечном итоге у `bootchain`, насколько далеко он уйдёт от форка и сможет
  ли быть с ним полностью совместимым.
- Некоторое время разработка `bootchain` велась независимо от основного проекта
  `make-initrd`. Чтобы собирать и тестировать загрузочные диски с `make-initrd`
  и `bootchain`, чтобы `bootchain` не зависел от версий `make-initrd`, чтобы не
  пересекаться со встроенной в `make-initrd` фичей `pipeline` и чтобы не мешать
  автору `make-initrd`, фичу `pipeline` пришлось скопировать под другим именем,
  дав ей заодно более подходящее название.
- Не всегда результат пройденного шага используется следующим. Шаги-скрипты
  могут использовать результаты не только предыдущего, но и любого ранее
  пройденного шага. Так что это не конвейер в чистом виде, а скорее цепочка
  шагов загрузки, последовательность выполняемых действий.

## Отличия от оригинального pipeline

- Модульность: методы загрузки изначально отделены от общего кода и демона.
- Обеспечена возможность переводить демон на передний план в любое время.
  При этом происходит перезапуск процесса `chaind` на конкретном терминале,
  хотя изначально демон запускается в фоновом режиме.
- Некоторые шаги (действия) встроены непосредственно в код главного цикла
  демона `chaind`, внешние скрипты для их выполнения не вызываются. Такие
  псевдо-шаги позволяют управлять, в основном, внутренним состоянием демона
  и не должны учитываться в загрузочной цепочке, как будто они скрыты.
- Опционально демон может работать совместно с фичей `bootchain-interactive`,
  может перейти на передний план и продолжить работать на конкретном терминале,
  по умолчанию tty2. Совместно фичи `bootchain-core` и `bootchain-interactive`
  закладывают основу для построения простых текстовых инсталляторов в stage1.
- Демон `chaind` позволяет перегружать цепочку новым набором шагов, благодаря
  чему можно менять логику работы "на лету", поддерживать циклы и условные
  переходы, в текстовых диалогах это возможность возвращаться назад.
- Ведёт учёт хотя бы один раз пройденных шагов и позволяет предотвращать их
  повторный запуск.
- `bootchain-sh-functions` расширяет API оригинального `pipeline-sh-functions`,
  см. детали в соответствующем разделе.
- Через resolve_target() поддерживает не только прямую, но и обратную адресацию,
  относительно текущего шага. Например, запись вида `step-3/dir1/dev` обработает
  результат `dir1/dev`, сделанный на третьем шаге от текущего. Совместно с
  перегрузкой цепочки шагов прямая адресация безопасна только при сохранении
  номеров пройденных шагов в файлы, тогда как обратная относительная адресация
  безопасна в любом случае и зачастую может оказаться удобней.
- Позволяет работать с более короткими и привычными путями к специальным файлам
  устройств благодаря использованию `DEVNAME` наряду с `dev`.
- Предоставляет возможность связывать <ВХОД> шага с <ВЫХОДОМ> предыдущего шага
  через символические ссылки на точки монтирования внутри initramfs, вне дерева
  результатов шагов, что обеспечивает, при необходимости, механизм монтирования
  внахлёст, свойственный программе `propagator`.
- Наряду с РОДНЫМ режимом работы, демон `chaind` может работать в режиме
  СОВМЕСТИМОСТИ с `pipeline`. В РОДНОМ режиме работы демон навязывает другой
  подход к обработке кода состояния завершённого шага и способу преждевременного
  завершения загрузочной цепочки, см. детали в соответствующем разделе.
- Демон может быть сконфигурирован при сборке initramfs через включаемый файл
  конфигурации `/etc/sysconfig/bootchain`, а не только через параметры загрузки,
  см. детали в соответствующем разделе.
- Демон `chaind` предлагает наглядную и расширенную отладку. По умолчанию журнал
  ведётся в `/var/log/chaind.log` и доступен на tty3, а при включении расширенной
  отладки или функции самотестирования также копируется в stage2. Служебный шаг-
  скрипт `debug` в режиме расширенной отладки запускается перед запуском любого
  другого шага-скрипта и позволяет наглядно отследить получаемые значения на
  каждом <ВХОДЕ>.

Несмотря на отличия, `chaind` обратно совместим с ранее написанными шагами для
демона `pipelined` и не требует изменений для конфигураций с `root=pipeline`.

## Особенности работы демона pipelined

Если скрипт шага завершится кодом состояния 2, оригинальный демон `pipelined`
воспримет это как необходимость прервать цепочку и прекратить работу, полагая,
что система готова к переходу в stage2. Если скрипт шага не обработает данный
код от внешней команды, а stage2 окажется ещё не готов к работе, возникнет
ситуация с преждевременным завершением демона.

Если шаг-скрипт завершится ненулевым кодом состояния, отличным от 2, демон
`pipelined` воспримет это как сбой и будет повторять зафейлившийся шаг с паузой
в одну секунду в бесконечном цикле (до истечения общего таймаута rootdelay=180).
Но зачастую повторять шаги бесполезно, поскольку ситуация неисправима, повтор
приводит лишь к ненужному ожиданию и разрастанию записей в журнале. Однако
демон `pipelined` не знает, как обрабатывать такие ситуации.

## Новый подход в демоне chaind

Шагам-скриптам предлагается перед завершением с кодом состояния 0 вызвать
break_bc_loop(), чтобы сообщить демону о готовности stage2 и необходимости
завершить работу демона сразу после текущего шага. В случае сбоя в скрипте шага
демон может его повторять, но не более четырёх раз с паузой в две секунды. Чтобы
сбой в скрипте шага приводил к немедленному завершению работы демона, необходимо
использовать внутренний шаг `noretry`.

## Режимы работы демона

### РОДНОЙ режим работы

РОДНОЙ режим активируется параметром `root=bootchain`. В этом режиме демон будет
воспринимать код состояния 2 от скрипта шага так же, как и любой другой ненулевой
код и далее действовать согласно внутреннему состоянию: если повторы разрешены,
скрипт шага будет вызван повторно с паузой в 2 секунды, но не более четырёх раз.
Если же повторы запрещены, демон сам немедленно завершится.

### Режим СОВМЕСТИМОСТИ с pipeline

Режим СОВМЕСТИМОСТИ активируется параметром `root=pipeline`. В этом режиме демон
ведёт себя так же, как и оригинальный `pipelined`, разве что ограничивает число
повторных запусков зафейлившегося шага. Он воспринимает код состояния 2 не как
сбой, а как команду завершить главный цикл демона.

## Конфигурация

Конфигурация определяется в файле `/etc/sysconfig/bootchain` при сборке образа
initramfs, необязательна и может содержать следующие параметры:

- `BC_LOG_VT` - номер виртуального терминала, на который в фоновом режиме должен
  выводиться отладочный журнал. По умолчанию значение равно 3, соответственно
  журнал выводится на tty3. Пустое значение позволяет отключить вывод журнала
  на какой-либо терминал.
- `BC_FGVT_ACTIVATE` - задержка в секуднах перед активацией интерактивного
  терминала, по умолчанию tty2 активируется через 2 секунды в режиме отладки
  или через 8 секунд в обычном режиме. Пустое значение предписывает активировать
  интерактивный терминал немедленно. Данная опция конфигурации работает только
  вместе с включенной в initramfs фичей `bootchain-interactive`.
- `BC_LOGFILE` - полный путь к файлу журнала либо имя специального устройства,
  на который будут выводиться отладочные сообщения. В РОДНОМ режиме значение по
  умолчанию равно `/var/log/chaind.log`, в режиме СОВМЕСТИМОСТИ с `pipeline`
  значение по умолчанию равно `/var/log/pipelined.log`.
- `mntdir` - где создавать подкаталоги шагов загрузочной цепочки. В РОДНОМ
  режиме значение по умолчанию равно `/dev/bootchain`, в режиме СОВМЕСТИМОСТИ
  с `pipeline` значение по умолчанию равно `/dev/pipeline`.

Другие модули `bootchain-*` также могут использовать этот файл конфигурации для
собственных потребностей.

## Встроенные псевдо-шаги

Все ниже перечисленные шаги являются расширением `pipeline`. Они встроены в
код главного цикла демона `chaind`, не нуждаются в дополнительных параметрах
и не должны учитываться при адресации, как будто они скрыты.

- `fg` - обеспечивает перевод демона в интерактивный режим при сборке initramfs
  с фичей `bootchain-interactive`. Самому `bootchain-core` интерактивность не
  требуется, но в ней могут нуждаться некоторые другие шаги, такие как `altboot`.
- `noop` - не выполняет никаких действий и предназначен для отрыва результатов на
  <ВЫХОДЕ> предыдущего шага от <ВХОДА> следующего шага, что может быть полезно,
  например, когда мы не хотим, чтобы результаты шага `waitdev` были использованы
  в следующем шаге `localdev`, который в первую очередь смотрит именно на них.
- `noretry` - запрещает следующим шагам завершаться с ненулевым кодом возврата,
  что приведёт к немедленному завершению работы демона в случае сбоя в скрипте
  любого следующего шага. По умолчанию шагам разрешено фейлиться, демон будет
  пытаться перезапускать их повторно четыре раза с паузой в две секунды.
- `retry` - разрешает всем последующим шагам завершаться с ненулевым кодом
  возврата, что приведёт к их пятикратному запуску, в общей сложности. Такой
  режим работы демона действует по умолчанию.

## Внешние элементы загрузочной цепочки (шаги-скрипты)

- `mountfs` - монтирует файл или устройство из результата предыдущего либо
  другого указанного шага.
- `overlayfs` - объединяет один или несколько элементов загрузочной цепочки
  с помощью overlayfs.
- `rootfs` - заставляет демон использовать результат предыдущего элемента как
  найденный корень stage2.

## Параметры загрузки

- `bootchain=name1[,name2][,name3]` - определяет начальное состояние загрузочной
  цепочки, т.е. шаги, которые должен пройти демон один за другим. Это могут быть
  как встроенные псевдо-шаги, так и реальные скрипты выполняемых действий. Имена
  этих шагов перечисляются через запятую.
- `pipeline=name1[,name2][,name3]` - синоним для `bootchain=...`.
- `mountfs=target` - определяет монтируемый файл или устройство.
- `overlayfs=list` - определяет список элементов для объединения.
- `bc_debug` - булевый параметр, включающий расширенную отладку и заставляющий
  в случае успешного завершения демона скопировать журнал загрузки в stage2.
- `bc_test=name` - определяет название текущего тест-кейса в процессе полностью
  автоматизированного самотестирования, заставляющий в случае успешного
  завершения демона скопировать журнал загрузки в stage2 и рядом с ним
  создать файл BC-TEST.passed с указанным названием тест-кейса.

## Расширенное API bootchain-sh-functions

- check_parameter() - проверяет, чтобы обязательный параметр был не пуст,
  иначе завершает работу через fatal().
- get_parameter() - вывод значения параметра текущего шага по индексу $callnum.
- resolve_target() - вывод пути к файлу, каталогу или устройству, в зависимости
  от параметра.
- resolve_devname() - вывод пути к специальному файлу устройства по указанному
  каталогу. Обычно каталог шага содержит файл DEVNAME или dev, если устройство
  было результатом шага, тогда функция вернёт читаемый `/dev/узел`.
- debug() - вывод текстового сообщения при расширенной отладке.
- enter() - трассировка при расширенной отладке: вход в указанную функцию.
- leave() - трассировка при расширенной отладке: выход из указанной функции.
- run() - запуск внешней команды. При расширенной отладке выполняемая команда
  попадёт в журнал.
- fdump() - вывод содержимого указанного файла при расширенной отладке.
- assign() - присвоение переменной указанного значения, попадающее в журнал
  при расширенной отладке. Левостороннее выражение также является вычисляемым.
- next_bootchain() - команда демону на смену последовательности следующих шагов.
- is_step_passed() - возвращает 0, если текущий шаг был пройден хотя бы один раз.
- launch_step_once() - если текущий шаг уже был пройден, завершает работу через
  вызов fatal().
- break_bc_loop() - сообщает демону о том, что текущий шаг последний и после
  его успешного завершения можно переходить в stage2. Скрипт этого шага, тем
  не менее, должен отработать до конца и завершиться с нулевым кодом состояния,
  чтобы демон обработал полученный сигнал.
- bc_reboot() - выполняет журналируемый перезапуск компьютера.
- bypass_results() - просит демон связать <ВЫХОД> предыдущего шага со <ВХОДОМ>
  следующего шага. Также используется для сообщения демону о результате
  (смонтированном каталоге) внутри текущего корня initramfs, вне дерева $mntdir.
- initrd_version() - вывод текущей версии make-initrd. Предлагается перенести
  в make-initrd/data/bin/initrd-sh-functions вслед за has_module().

## Примеры

Cmdline: root=bootchain bootchain=waitdev,mountfs,mountfs,overlayfs,rootfs waitdev=CDROM:LABEL=ALT_regular-rescue/x86_64 mountfs=DEVNANE mountfs=rescue

Следуя этим параметрам, демон дожидается локального устройства с файловой
системой ISO-9660 и меткой тома "ALT_regular-rescue/x86_64", монтирует этот
носитель, монтирует с него файл "rescue" как squashfs корневой системы, делает
его доступным для записи с помощью overlayfs и пытается загрузиться с него.

Cmdline: root=pipeline pipeline=getimage,mountfs,overlayfs,rootfs getimage=http://ftp.altlinux.org/pub/people/mike/iso/misc/vi-20140918-i586.iso mountfs=rescue

Следуя этим параметрам, демон загружает образ "vi-20140918-i586.iso", монтирует
его через устройство loop, монтирует с него файл "rescue" как squashfs корневой
системы, делает его доступным для записи с помощью overlayfs и пытается
загрузиться с него.
