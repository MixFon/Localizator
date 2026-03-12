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

	init() {
		let source = Locale.Language(identifier: "ru")
		let target = Locale.Language(identifier: "en")
		
		self.session = TranslationSession(installedSource: source, target: target)
	}
	
	func key(for string: String) async -> String {
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Keep only letters and spaces
        let allowed = CharacterSet.letters.union(CharacterSet.whitespaces)
        let filteredScalars = normalized.unicodeScalars.filter { allowed.contains($0) }
        let result = String(String.UnicodeScalarView(filteredScalars))
		
		var translated: [String] = []
		for word in result.split(separator: " ").prefix(5).map( String.init ) {
			do {
				try await self.session.prepareTranslation()
				let response = try await session.translate(word)
				translated.append(response.targetText)
			} catch { }
		}
		return "mm_" + translated.joined(separator: "_")
	}
}
