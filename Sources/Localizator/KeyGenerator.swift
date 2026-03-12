//
//  File.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//

import Foundation
import Translation

protocol _KeyGenerator {
	func key(for string: String) async -> String
}

final class KeyGenerator: _KeyGenerator {
	
	private let session: TranslationSession
	private let prefix: String

	init(prefix: String) {
		let source = Locale.Language(identifier: "ru")
		let target = Locale.Language(identifier: "en")
		
		self.prefix = prefix
		self.session = TranslationSession(installedSource: source, target: target)
	}
	
	func key(for string: String) async -> String {
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
				translated.append(translatedWord)
			} catch {
				debugPrint(error.localizedDescription)
			}
		}
		let result = "\(self.prefix)_\(translated.joined(separator: "_"))"
		debugPrint(normalized, "->", result)
		return result
	}
}
