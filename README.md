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

## Сборка

Из корня репозитория:

```bash
swift build -c release
```

Готовый бинарник:

```text
.build/release/Localizator
```

Отладочная сборка: `swift build` → `.build/debug/Localizator`.

## Запуск без установки

Из каталога пакета:

```bash
swift run Localizator --help
```

С явной подкомандой (эквивалентно вызову по умолчанию):

```bash
swift run Localizator localize --prefix <префикс> [путь]
```

`путь` — необязательный аргумент: каталог или файл для сканирования; если не указан, используется текущая рабочая директория.

## Использование собранного бинарника

Общие опции для подкоманд, которые работают с MMTranslation:

| Опция | Описание |
|--------|----------|
| `-f`, `--file` | Путь к корню пакета MMTranslation (по умолчанию в коде: `../mmtranslation`) |
| `-p`, `--prefix` | Префикс ключей локализации (обязателен) |

Примеры:

```bash
# Локализация: сканировать текущую папку
./.build/release/Localizator --prefix my_prefix

# Явно подкоманда и свой каталог исходников
./.build/release/Localizator localize --prefix my_prefix --file /path/to/MMTranslation /path/to/Sources

# Поиск дубликатов в JSON
./.build/release/Localizator duplicates --prefix my_prefix --file /path/to/MMTranslation

# Актуализация enum по ключам из JSON
./.build/release/Localizator actualization --prefix my_prefix --file /path/to/MMTranslation
```

## Куда положить бинарник для быстрого доступа

Удобные варианты на macOS:

1. **`~/bin` или `~/.local/bin`** — создайте каталог при необходимости, скопируйте бинарник и добавьте путь в `PATH` в `~/.zshrc`:
   ```bash
   mkdir -p ~/bin
   cp .build/release/Localizator ~/bin/
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
   ```
   После перезапуска оболочки команда доступна как `Localizator`.

2. **`/usr/local/bin`** (нужны права администратора) — один раз скопировать туда; каталог часто уже в `PATH`.

3. **Симлинк** на бинарник в уже существующем каталоге из `PATH` — удобно, если не хотите дублировать файл при пересборке:
   ```bash
   ln -sf /полный/путь/к/Localizator ~/bin/Localizator
   ```

Для постоянного использования в разных проектах предпочтительны **отдельный каталог в домашней директории + `PATH`** или **симлинк**: обновление сводится к пересборке и копированию/перезаписи одного файла.