#!/usr/bin/env python3
"""Переводит ключи локализации внутри MMTranslation.text(.key) из camelCase в snake_case."""

import argparse
import re
import sys
from pathlib import Path

CALL_PATTERN = re.compile(r"(MMTranslation\.text\(\.)([A-Za-z_][A-Za-z0-9_]*)")


def camel_to_snake(name: str) -> str:
	result = []
	for i, ch in enumerate(name):
		if ch.isupper():
			if i > 0:
				result.append("_")
			result.append(ch.lower())
		else:
			result.append(ch)
	return "".join(result)


def process_file(path: Path) -> list[tuple[str, str]]:
	original = path.read_text(encoding="utf-8")
	changes: list[tuple[str, str]] = []

	def replace(match: re.Match) -> str:
		prefix, key = match.group(1), match.group(2)
		snake_key = camel_to_snake(key)
		if snake_key != key:
			changes.append((key, snake_key))
		return prefix + snake_key

	updated = CALL_PATTERN.sub(replace, original)
	if changes:
		path.write_text(updated, encoding="utf-8")
	return changes


def main() -> None:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("path", nargs="?", default=".", help="Файл или папка для сканирования (по умолчанию текущая директория)")
	args = parser.parse_args()

	root = Path(args.path).resolve()
	if not root.exists():
		print(f"Путь не найден: {root}", file=sys.stderr)
		sys.exit(1)

	swift_files = [root] if root.is_file() else sorted(root.rglob("*.swift"))

	total_changes = 0
	for file in swift_files:
		if ".build" in file.parts:
			continue
		changes = process_file(file)
		if changes:
			total_changes += len(changes)
			print(f"{file.relative_to(root) if root.is_dir() else file.name}:")
			for old, new in changes:
				print(f"  .{old} -> .{new}")

	print(f"\nВсего заменено ключей: {total_changes}")


if __name__ == "__main__":
	main()
