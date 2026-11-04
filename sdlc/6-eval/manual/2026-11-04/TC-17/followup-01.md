# TC-17 — дополнение 01 (2026-11-04)

Дополнены только точные runtime bounds Retry и программные пределы UI preview;
функциональные матрицы повторно не выполнялись. Исходный
[журнал](transcript.md) сохраняет описание первого прохода и содержит
ссылку на дополнение с консолидированным итогом.

**Сборка:** существующий `build/web`, provenance исходного прогона — release
web от main `f09639a32f5a05294b88a0baa1d080b0f6e1a1d4`. Текущий checkout
`bc2b853`; после сборки менялись только docs/sdlc. Сборку не пересобирал.

**Retry (files-error → good):** замороженный initScript TC-17, синтетические
данные, writes перехвачены; `blockedWrites=0`. На desktop 1440×900 кнопка
имеет bounds `x=788.10, y=472, w=120.80, h=48`; на mobile 360×800,
touch/Android UA/`Linux armv8l`: `x=119.60, y=392, w=120.80, h=48`.
В обоих состояниях `calls.files=4`; после изменения только `mode='good'` и
реального клика Retry — `calls.files=5`, fixture восстановлен. Ошибка видна
на кадрах [desktop](screenshots/followup-01-1440-files-error.png) и
[mobile](screenshots/followup-01-360-files-error.png).

**Good fixture, `a-long.txt`:** на desktop и mobile semantics preview состоит из
10 содержательных строк и строки многоточия. Программный замер каждого
viewport: 10 000 `x` в первой строке + `…` (длина первой строки 10 001),
строки `row-2`…`row-10`, отдельная строка `…`; total 10 058 символов,
11 строк с разделителями. Это измерение UI preview синтетической страницы,
не длина реального файла. `blockedWrites=0`.
Кадры: [desktop](screenshots/followup-01-1440-long-preview.png),
[mobile](screenshots/followup-01-360-long-preview.png).

**Вердикт дополнения:** Retry bounds и программные пределы preview закрыты на
обеих ширинах. Старые ссылки на functional good/empty/errors/retry и прочие
уже принятые шаги — в [исходном журнале](transcript.md); они не повторялись.
