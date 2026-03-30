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
	/// Ключи которых нет в файле
	var keys: [String] { get }
	func key(for russianString: String) -> String
	func load(filePath: String)
	func translating() async
	func saveForTranslate(_ russianString: String)
	/// Ключи и значение, которых не было в файле. В формате TSV (tab-separated values)
	func newKeyValues() -> String?
}

final class LocalizationManager: _LocalizationManager {
	
	var keys: [String] {
		self.newKeys.values.map({$0})
	}
	
	private let prefix: String
	private var ruToKey: [String: String] = [:]
	private var commonRuToKey: [String: String] = [:]
	/// Ключи, которых
	private var newKeys: [String: String] = [:]
	private let keyGenerator: _KeyGenerator
	private let jsonLoader: _JsonLoader
	private var russianStrings: [String] = []
	/// Префикс ключа для общих переводов
	private let commonPrefix: String = "mm_metro"
	
	init(prefix: String, keyGenerator: _KeyGenerator, jsonLoader: _JsonLoader) {
		self.prefix = prefix
		self.keyGenerator = keyGenerator
		self.jsonLoader = jsonLoader
	}
	
	func load(filePath: String) {
		do {
			try jsonLoader.load(filePath: filePath) { [weak self] key, text in
				guard let self else { return }
				if key.contains(self.commonPrefix) {
					self.commonRuToKey[text] = key
				} else if key.contains(self.prefix) {
					self.ruToKey[text] = key
				}
			}
		} catch {
			debugPrint("Ошибка при загрузке или декодировании JSON: \(error.localizedDescription)")
		}
	}

	func key(for russianString: String) -> String {
		// По русскому тексту отправляем ключ
		return ruToKey[russianString] ?? commonRuToKey[russianString] ?? ""
	}
	
	func saveForTranslate(_ russianString: String) {
		self.russianStrings.append(russianString)
	}
	
	func translating() async {
		for russianString in self.russianStrings {
			if let commonKey = self.commonRuToKey[russianString] {
				// Насшли общие ключи переводим ключ в кемелкейс (общие ключи mm_metro в камел кейсе)
				self.commonRuToKey[russianString] = self.keyGenerator.snakeToCamel(commonKey)
			} else if self.ruToKey[russianString] == nil {
				// Нет ключа с префиксом сервиса. Значит нам нужно создать новый ключ
				// Переводим строку на англиский и превращаем в снеккейс
				let newKey = await self.keyGenerator.key(for: russianString)
				self.ruToKey[russianString] = newKey
				self.newKeys[russianString] = newKey
			}
		}
	}
	
	func newKeyValues() -> String? {
		guard !newKeys.isEmpty else { return nil }
		var lines: [String] = ["key\tsource_ru"]
		for (russianText, key) in newKeys.sorted(by: { $0.value < $1.value }) {
			lines.append("\(Self.tsvEscapedField(key))\t\(Self.tsvEscapedField(russianText))")
		}
		return lines.joined(separator: "\n")
	}
	
	/// Убирает табы и переводы строк из ячейки TSV, чтобы строка оставалась одной записью.
	private static func tsvEscapedField(_ string: String) -> String {
		string
			.replacingOccurrences(of: "\t", with: " ")
			.replacingOccurrences(of: "\r\n", with: " ")
			.replacingOccurrences(of: "\n", with: " ")
			.replacingOccurrences(of: "\r", with: " ")
	}
}

