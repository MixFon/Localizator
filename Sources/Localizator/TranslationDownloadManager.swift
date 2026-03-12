import Foundation

// MARK: - Структуры для JSON
struct LocalizationFile: Decodable {
	let items: [LocalizationItem]
}

struct LocalizationItem: Decodable {
	let translates: [MMLanguageTranslates]
}

public struct MMLanguageTranslates: Codable, Sendable {
	let code: String
	let translations: MMTranslationsDictionary
	
	public init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		code = try c.decode(String.self, forKey: .code)
		translations = try c.decode(MMTranslationsDictionary.self, forKey: .translations)
	}
}


// MARK: - MMTranslationsDictionary

public struct MMTranslationsDictionary: Codable, Sendable {
	let values: [String: TranslationValue]

	init(values: [String: TranslationValue]) {
		self.values = values
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		values = try container.decode([String: TranslationValue].self)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(values)
	}

	subscript(key: String) -> TranslationValue? {
		values[key]
	}
}

// MARK: - TranslationValue

public enum TranslationValue: Codable, Sendable {
	case text(String)
	case plural([TranslationPluralForm: String])

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let dict = try? container.decode([String: String].self) {
			let mapped: [TranslationPluralForm: String] = Dictionary(
				uniqueKeysWithValues: dict.compactMap { key, value -> (TranslationPluralForm, String)? in
					guard let form = TranslationPluralForm(rawValue: key) else { return nil }
					return (form, value)
				}
			)
			self = .plural(mapped)
			return
		} else {
			let stringValue = try container.decode(String.self)
			self = .text(stringValue)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .text(let str):
			try container.encode(str)
		case .plural(let dict):
			let stringKeyed: [String: String] = Dictionary(
				uniqueKeysWithValues: dict.map { ($0.key.rawValue, $0.value) }
			)
			try container.encode(stringKeyed)
		}
	}
}

public enum TranslationPluralForm: String, Codable, Sendable {
	case zero   // Форма для 0
	case one    // Форма для 1
	case two    // Форма для 2
	case few    // Форма «несколько»
	case many   // Форма «много»
	case other  // Общая форма
}

protocol _LocalizationManager {
	func key(for russianString: String) -> String
	func load(filePath: String)
	func saveForTranslate(_ russianString: String)
}

final class LocalizationManager: _LocalizationManager {
	
	private let prefix: String
	private var ruToKey: [String: String] = [:]
	private let keyGenerator: _KeyGenerator
	private var russianStrings: [String] = []
	/// Префикс ключа для общих переводов
	private let commonPrefix: String = "mm_metro"
	
	init(prefix: String, keyGenerator: _KeyGenerator) {
		self.prefix = prefix
		self.keyGenerator = keyGenerator
	}
	
	func load(filePath: String) {
		let url = URL(fileURLWithPath: filePath)
		
		do {
			let data = try Data(contentsOf: url)
			let localization = try JSONDecoder().decode(LocalizationFile.self, from: data)
			
			// Берем первую item и русскую локализацию
			if let ruTranslations = localization.items.first?.translates.first(where: { $0.code == "ru-RU" })?.translations {
				for (key, value) in ruTranslations.values {
					switch value {
					case .plural(_):
						continue
					case .text(let text):
						if key.contains(self.prefix) || key.contains(self.commonPrefix) {
							ruToKey[text] = key
						}
					}
				}
			}
		} catch {
			debugPrint("Ошибка при загрузке или декодировании JSON: \(error.localizedDescription)")
		}
	}

	func key(for russianString: String) -> String {
		return ruToKey[russianString] ?? ""
	}
	
	func saveForTranslate(_ russianString: String) {
		self.russianStrings.append(russianString)
	}
	
	func translating() async {
			
		for russianString in self.russianStrings {
			if ruToKey[russianString] == nil {
				ruToKey[russianString] = await self.keyGenerator.key(for: russianString)
			}
		}
	}
}

