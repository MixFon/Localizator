# Localizator

CLI для автоматизации локализации Swift-кода в связке с пакетом **MMTranslation**: разбор исходников через SwiftSyntax, работа с `metro_mobile_translations.json`, enum `MMTranslationKeys` и генерация ключей с заданным префиксом.

## Принцип работы

1. **Контекст MMTranslation** — указывается путь к корню пакета (`-f` / `--file`). Относительно него читаются:
   - `Sources/MMTranslation/Resources/metro_mobile_translations.json` — существующие переводы;
   - `Sources/MMTranslation/Models/ServicesKeys/MMTranslationKeys.swift` — enum ключей (для локализации и актуализации).

2. **Префикс** (`-p` / `--prefix`) — общий для всех подкоманд: по нему ищутся и создаются ключи в snake_case.

3. **Режим `localize` (по умолчанию)** — рекурсивно обходит `.swift` в указанной папке (или одном файле), готовит строки к переводу, затем подставляет локализацию, обновляет enum и при необходимости пишет TSV новых ключей (`new_keys.key` в корне сканирования).

4. **Режим `duplicates`** — только анализ JSON на дубликаты и похожие ключи (без переписывания исходников).

5. **Режим `actualization`** — добавляет в `MMTranslationKeys` case’ы для ключей из JSON с вашим префиксом, которых ещё нет в enum.

Интерфейс построен на [swift-argument-parser](https://github.com/apple/swift-argument-parser): справка — `--help` у корня и у каждой подкоманды.

## Требования

- macOS 26+ (см. `Package.swift`)
- Swift 6.2+

## Сборка и установка

Скрипт `install.sh` собирает release-бинарник и копирует его в каталог из `PATH`, чтобы вызывать `localizator` из любой точки системы:

```bash
./install.sh
```

По умолчанию бинарник ставится в `~/.local/bin/localizator`. Другая папка:

```bash
INSTALL_DIR=/usr/local/bin ./install.sh
```

После установки:

```bash
localizator --help
```

Если команда не находится, добавьте каталог в `PATH` (например в `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Сборка вручную

```bash
swift build -c release
```

Готовый бинарник: `.build/release/Localizator`. Отладочная сборка: `swift build` → `.build/debug/Localizator`.

### Запуск без установки

```bash
swift run Localizator --help
swift run Localizator localize --prefix <префикс> [путь]
```

`путь` — необязательный аргумент: каталог или файл для сканирования; если не указан, используется текущая рабочая директория.

## Использование

Общие опции для подкоманд, которые работают с MMTranslation:

| Опция | Описание |
|--------|----------|
| `-f`, `--file` | Путь к корню пакета MMTranslation (по умолчанию в коде: `../mmtranslation`) |
| `-p`, `--prefix` | Префикс ключей локализации (обязателен) |

Примеры:

```bash
# Локализация: сканировать текущую папку
localizator --prefix my_prefix

# Явно подкоманда и свой каталог исходников
localizator localize --prefix my_prefix --file /path/to/MMTranslation /path/to/Sources

# Поиск дубликатов в JSON
localizator duplicates --prefix my_prefix --file /path/to/MMTranslation

# Актуализация enum по ключам из JSON
localizator actualization --prefix my_prefix --file /path/to/MMTranslation
```