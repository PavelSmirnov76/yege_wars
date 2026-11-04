# TC-18 — дополнение 01 (2026-11-04)

Дополнены pending/disabled, точные bounds кнопок и Retry. Основные сценарии из
[исходного журнала](transcript.md) не повторялись. Использован замороженный
initScript TC-17, только синтетические маркеры, попытки и REST writes
перехвачены (`blockedWrites=0`).

**Сборка:** существующий `build/web`; provenance исходного прогона — release
web от main `f09639a32f5a05294b88a0baa1d080b0f6e1a1d4`. Текущий checkout
`bc2b853`; после сборки менялись только docs/sdlc. Сборку не пересобирал.

## Mobile 360×800

Платформа: touch, Android UA, `navigator.platform=Linux armv8l`.
Для pending `submitMode='wrong'`, `delayMs=15000`. DOM input перед отправкой
содержал точно `tc_wrong`. Один реальный submit дал один вызов и одну попытку;
пока RPC ожидался, semantics snapshot содержал:

```text
button "Отправляю…" disableable disabled
```

[Viewport кадр pending](screenshots/followup-01-360-pending.png) сохранён и
просмотрен. Позднейший DOM probe сделан после 15-секундного завершения; он уже
показывал итоговый результат, поэтому disabled подтверждён snapshot во время
pending и кадром. Send bounds: `x=16, y=596, w=328, h=48`.

Отдельный адресный submit `tc_correct`, `delayMs=0`, разрешён только для
измерения offer controls; до действия DOM value проверен. Получен один
correct-result, `submit=1`, `attempts=1`, `blockedWrites=0`. Bounds: Send
`328×48`; «Опубликовать решение» `x=16, y=798, w=210.25, h=48`; «Не сейчас»
`x=234.26, y=798, w=102.88, h=48`. Offer bounds начинаются у нижней границы
viewport; screenshot показывает вердикт, а видимые текст/кнопки offer остаются
в прежних кадрах основного прогона. Ничего не опубликовано и «Не сейчас» не
нажималось. Новый кадр:
[mobile correct result](screenshots/followup-01-360-correct-result.png).

В отдельной загрузке `attempts-error` на 360 Retry bounds были
`x=119.60, y=959, w=120.80, h=48`; это ниже viewport из-за расположения списка
под редактором. Смена mode на good и реальный Retry дала `attempts=4→5`, пустой
список и `blockedWrites=0`. Новый error screenshot в этой папке не сохранён;
состояние и функциональный recovery есть в основном журнале, mobile [кадр
основного прогона](screenshots/28-mobile-attempts-error.png).

## Desktop 1440×900

Платформа: MacIntel. Для pending `submitMode='correct'`, `delayMs=15000`.
Перед единственным отправлением DOM input содержал `tc_correct`; один submit,
`blockedWrites=0`, после задержки — один correct attempt. [Viewport кадр
pending](screenshots/followup-01-1440-pending.png) сохранён и просмотрен.
Ожидание «Отправляю…» и disabled-оформление видны на кадре. Отдельный AX
snapshot с disabled на desktop не сохранён. Постановщик проверил связь в
SubmitPanel: `submit.isSubmitting` одновременно задаёт подпись ожидания и
`onPressed=null`; сочетание кода и [кадра pending](screenshots/followup-01-1440-pending.png)
достаточно подтверждает disabled на desktop, без нового прогона.

Bounds из runtime semantics: Send `x=983.20, y=755, w=440.80, h=48`;
«Опубликовать решение» `x=983.20, y=941, w=210.25, h=48`; «Не сейчас»
`x=1201.46, y=941, w=102.88, h=48`. Две последние цели находятся ниже
начального viewport y=900; клик по ним не выполнялся.

В отдельной загрузке `attempts-error` bounds Retry: `x=788.10, y=180,
w=120.80, h=48`; screenshot:
[desktop attempts error](screenshots/followup-01-1440-attempts-error.png).

**Итог:** transient кадры, мобильный snapshot disabled, desktop disabled по
кадру и исходнику SubmitPanel, bounds Send/offer/Retry получены. Основной
функциональный журнал и ссылки в
[исходном transcript](transcript.md) сохранены; текущий итог вынесен
в его заключительный раздел с прямой ссылкой на это дополнение.
