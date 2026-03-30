//
//  File.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//

import Foundation
import Translation

/// Генерация строковых ключей локализации из русского текста и преобразование имён из snake_case.
protocol _KeyGenerator {
	/// Строит уникальный ключ по русской строке: перевод первых слов, суффиксы по плейсхолдерам `%n$s`, при коллизиях — `_v…`.
	func key(for string: String) async -> String
	/// Переводит `snake_case` в lowerCamelCase для сегментов, разделённых `_`.
	func snakeToCamel(_ string: String) -> String
}

/// Ключ вида `prefix_en_words…` через `TranslationSession` (ru→en), с учётом интерполяций и уникальности.
final class KeyGenerator: _KeyGenerator {
	
	private let session: TranslationSession
	private let prefix: String
	/// Базовый ключ (без `_v…`) → сколько раз уже выдан итоговый ключ с этой базой.
	private var keyOccurrences: [String: Int] = [:]

	init(prefix: String) {
		let source = Locale.Language(identifier: "ru")
		let target = Locale.Language(identifier: "en")
		
		self.prefix = prefix
		self.session = TranslationSession(installedSource: source, target: target)
	}
	
	/// Нормализует строку, переводит до пяти первых слов, добавляет `_s1_s2…` по числу `%n$s`, при повторе базы — `_v{k}`.
	func key(for string: String) async -> String {
		let placeholderCount = Self.countPercentDollarSPlaceholders(in: string)
		
		let normalized = string
			.replacingOccurrences(of: "%\\d+\\$s",with: "",options: .regularExpression)
			.replacingOccurrences(of: "\n", with: "")
			.replacingOccurrences(of: "\t", with: "")
			.filter { $0.isLetter || $0.isWhitespace }
		var translated: [String] = []
		for word in normalized.split(separator: " ").prefix(5).map( String.init ) {
			do {
				try await self.session.prepareTranslation()
				let response = try await session.translate(word)
				let translatedWord = response.targetText.lowercased()
					.replacingOccurrences(of: " ", with: "_")
					.replacingOccurrences(of: "-", with: "_")
					.strippingBackticksAndQuotes()
				translated.append(translatedWord)
			} catch {
				debugPrint(error.localizedDescription)
			}
		}
		var baseKey = "\(self.prefix)_\(translated.joined(separator: "_"))"
		if placeholderCount > 0 {
			let sSuffix = (1...placeholderCount).map { "s\($0)" }.joined(separator: "_")
			baseKey += "_\(sSuffix)"
		}
		
		let result: String
		if let used = keyOccurrences[baseKey] {
			result = "\(baseKey)_v\(used)"
			keyOccurrences[baseKey] = used + 1
		} else {
			keyOccurrences[baseKey] = 1
			result = baseKey
		}
		
		debugPrint(normalized, "->", result)
		return result
	}
	
	/// Сколько раз в строке встречается шаблон `%` + цифры + `$s` (как в `prepareText` для интерполяций).
	private static func countPercentDollarSPlaceholders(in string: String) -> Int {
		guard let regex = try? NSRegularExpression(pattern: "%\\d+\\$s") else { return 0 }
		let range = NSRange(string.startIndex..., in: string)
		return regex.numberOfMatches(in: string, options: [], range: range)
	}
	
	/// Первый сегмент без изменений регистра, остальные с заглавной буквы; склеиваются без разделителей.
	func snakeToCamel(_ string: String) -> String {
		let parts = string.split(separator: "_")
		guard let first = parts.first else { return string }
		
		let tail = parts.dropFirst().map { $0.capitalized }
		return ([String(first)] + tail).joined()
	}
}

private extension String {
	/// Удаляет `` ` `` и кавычки (Unicode `Quotation_Mark` и ASCII U+0027).
	func strippingBackticksAndQuotes() -> String {
		replacingOccurrences(
			of: "[`\\p{Quotation_Mark}\\u0027]",
			with: "",
			options: .regularExpression
		)
	}
}
