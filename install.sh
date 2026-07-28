#!/usr/bin/env bash
#
# install.sh — сборка и установка CLI Localizator
#
# Собирает release-бинарник (swift build -c release) и копирует его
# в каталог из PATH, чтобы вызывать `localizator` из любой точки системы.
#
# Использование:
#   ./install.sh
#
# Установка в другую папку (по умолчанию — ~/.local/bin):
#   INSTALL_DIR=/usr/local/bin ./install.sh
#
# После установки:
#   localizator --help
#
# Если команда не находится, добавьте каталог в PATH, например в ~/.zshrc:
#   export PATH="$HOME/.local/bin:$PATH"
#

set -euo pipefail

# Корень репозитория (рядом со скриптом)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Куда кладём бинарник; можно переопределить через INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BINARY_NAME="localizator"
BUILD_PRODUCT="$SCRIPT_DIR/.build/release/Localizator"

cd "$SCRIPT_DIR"

echo "→ Building Localizator (release)…"
swift build -c release

mkdir -p "$INSTALL_DIR"
cp "$BUILD_PRODUCT" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

echo "✓ Installed to $INSTALL_DIR/$BINARY_NAME"

# Проверяем, что каталог установки доступен через PATH
if ! command -v "$BINARY_NAME" >/dev/null 2>&1; then
	echo
	echo "⚠  $INSTALL_DIR is not in your PATH."
	echo "   Add this to your shell config (~/.zshrc or ~/.bashrc):"
	echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
else
	echo "  Run: $BINARY_NAME --help"
fi
