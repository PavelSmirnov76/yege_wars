"""Выдача следующего id: команда `next`.

Номер — на единицу больше наибольшего в рабочем дереве, считая похороненные
и лежащие не на месте; у требований — наибольшего в PRD, считая устаревшие и
строки требований с ошибкой формата. Отказ — `model.Refusal` с кодом 2
(«неверный вызов» README): неизвестный тип, лишний или недостающий
владелец, нет задания (у `RESULT`), нет сдачи или у неё уже есть приёмка
(у `ACC`).
"""

from __future__ import annotations

from typing import Optional

from . import model

USAGE_CODE = 2


def _refuse(message: str) -> model.Refusal:
    return model.Refusal(message, code=USAGE_CODE)


def next_id(repo: model.Repo, kind: str, owner: Optional[str] = None) -> str:
    """Следующий id типа `kind`; у `RESULT` владелец — `TASK-{n}`, у `ACC` —
    `RESULT-TASK-{n}-{NN}`."""
    if kind not in model.ID_TYPES:
        raise _refuse(f'неизвестный тип {kind}: нужен один из {" ".join(model.ID_TYPES)}')
    if kind == 'RESULT':
        return _next_result(repo, owner)
    if kind == 'ACC':
        return _next_acceptance(repo, owner)
    if owner is not None:
        raise _refuse(f'у {kind} владельца нет: python3 -m sdlc_tool next {kind}')
    if kind == model.REQUIREMENT:
        return f'R{max(repo.requirement_numbers, default=0) + 1}'
    top = max((item.number for item in repo.of_type(kind)), default=0)
    return f'{kind}-{top + 1}'


def _next_result(repo: model.Repo, owner: Optional[str]) -> str:
    ref = model.parse_id(owner) if owner else None
    if ref is None or ref.type != 'TASK':
        raise _refuse('у RESULT владелец — задание: python3 -m sdlc_tool next RESULT TASK-{n}')
    if repo.get(ref.text) is None:
        raise _refuse(f'задания {ref.text} нет')
    top = max((item.seq for item in repo.of_type('RESULT') if item.number == ref.number),
              default=0)
    return f'RESULT-TASK-{ref.number}-{model.format_nn(top + 1)}'


def _next_acceptance(repo: model.Repo, owner: Optional[str]) -> str:
    ref = model.parse_id(owner) if owner else None
    if ref is None or ref.type != 'RESULT':
        raise _refuse('у ACC владелец — сдача: '
                      'python3 -m sdlc_tool next ACC RESULT-TASK-{n}-{NN}')
    if repo.get(ref.text) is None:
        raise _refuse(f'сдачи {ref.text} нет')
    acceptance = f'ACC-TASK-{ref.number}-{ref.nn}'
    if repo.get(acceptance) is not None:
        raise _refuse(f'у сдачи {ref.text} уже есть приёмка {acceptance}')
    return acceptance
