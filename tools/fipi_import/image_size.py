# -*- coding: utf-8 -*-
"""Размер картинки в пикселях по заголовку файла.

Внешних пакетов в импорте нет (Python 3.9 без зависимостей), а знать
размер нужно: значок интерфейса банка отличается от иллюстрации задания
именно размером, а не именем файла и не числом повторов.
"""
from __future__ import unicode_literals

import struct

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
GIF_SIGNATURES = (b'GIF87a', b'GIF89a')
JPEG_SIGNATURE = b'\xff\xd8'

# Маркеры JPEG, за которыми идёт размер кадра. 0xC4, 0xC8 и 0xCC — это
# таблицы Хаффмана и арифметического кодирования, размера в них нет.
_JPEG_FRAME_MARKERS = frozenset(
    set(range(0xC0, 0xD0)) - {0xC4, 0xC8, 0xCC})


def image_size(path):
    """Пара «ширина, высота» или None, если формат незнаком."""
    try:
        with open(path, 'rb') as handle:
            head = handle.read(32)
            if head[:8] == PNG_SIGNATURE:
                return struct.unpack(str('>II'), head[16:24])
            if head[:6] in GIF_SIGNATURES:
                return struct.unpack(str('<HH'), head[6:10])
            if head[:2] == JPEG_SIGNATURE:
                return _jpeg_size(handle)
    except (IOError, OSError, struct.error):
        return None
    return None


def _jpeg_size(handle):
    """Размер кадра JPEG: сегменты идут цепочкой, размер лежит в SOF."""
    handle.seek(2)
    while True:
        byte = handle.read(1)
        if not byte:
            return None
        if byte != b'\xff':
            continue
        marker = handle.read(1)
        while marker == b'\xff':
            marker = handle.read(1)
        if not marker:
            return None
        if marker[0] in _JPEG_FRAME_MARKERS:
            handle.read(3)
            height, width = struct.unpack(str('>HH'), handle.read(4))
            return (width, height)
        length = handle.read(2)
        if len(length) < 2:
            return None
        handle.seek(struct.unpack(str('>H'), length)[0] - 2, 1)
