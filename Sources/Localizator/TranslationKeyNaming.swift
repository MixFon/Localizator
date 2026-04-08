import Foundation

/// Общие правила имён ключей: `snake_case` ↔ lowerCamelCase и групповой префикс для актуализации enum.
enum TranslationKeyNaming {

	/// Первый сегмент без изменения регистра, остальные с заглавной буквы; склеиваются без разделителей (как в `KeyGenerator`).
	static func snakeToCamel(_ string: String) -> String {
		let parts = string.split(separator: "_")
		guard let first = parts.first else { return string }
		let tail = parts.dropFirst().map { $0.capitalized }
		return ([String(first)] + tail).joined()
	}

	/// Обратное к `snakeToCamel`: вставка `_` перед заглавными буквами (кроме первого символа), нижний регистр.
	static func camelToSnake(_ string: String) -> String {
		var result = ""
		for (i, c) in string.enumerated() {
			if c.isUppercase {
				if i > 0 { result.append("_") }
				result.append(contentsOf: c.lowercased())
			} else {
				result.append(c)
			}
		}
		return result
	}

	/// Группа для группировки вставок: первые два сегмента `a_b` или весь ключ, если сегментов ≤ 2.
	static func groupPrefix(ofSnakeKey snakeKey: String) -> String {
		let parts = snakeKey.split(separator: "_").map(String.init)
		switch parts.count {
		case 0: return snakeKey
		case 1: return parts[0]
		case 2: return parts[0] + "_" + parts[1]
		default: return parts[0] + "_" + parts[1]
		}
	}
}
