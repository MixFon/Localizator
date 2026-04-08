import Foundation

/// Загрузка JSON локализации и обход текстовых записей `ru-RU`.
protocol _JsonLoader {
	/// Читает файл, декодирует `LocalizationFile`, для первой `item` и локали `ru-RU` обходит пары ключ/значение.
	/// Для каждого `TranslationValue.text` вызывает замыкание с **ключом** и **русским текстом** (plural пропускаются).
	/// Ошибки чтения файла или декодирования JSON пробрасываются наружу.
	func load(filePath: String, onTextEntry: @escaping (_ key: String, _ text: String) -> Void) throws
	/// Все ключи переводов для локали `ru-RU` (включая plural и text).
	func allTranslationKeys(filePath: String) throws -> Set<String>
}

final class JsonLoader: _JsonLoader {
	
	func load(filePath: String, onTextEntry: @escaping (_ key: String, _ text: String) -> Void) throws {
		let url = URL(fileURLWithPath: filePath)
		let data = try Data(contentsOf: url)
		let localization = try JSONDecoder().decode(LocalizationFile.self, from: data)
		
		if let ruTranslations = localization.items.first?.translates.first(where: { $0.code == "ru-RU" })?.translations {
			for (key, value) in ruTranslations.values {
				switch value {
				case .plural:
					continue
				case .text(let text):
					onTextEntry(key, text)
				}
			}
		}
	}

	func allTranslationKeys(filePath: String) throws -> Set<String> {
		let url = URL(fileURLWithPath: filePath)
		let data = try Data(contentsOf: url)
		let localization = try JSONDecoder().decode(LocalizationFile.self, from: data)
		guard let ruTranslations = localization.items.first?.translates.first(where: { $0.code == "ru-RU" })?.translations else {
			return []
		}
		return Set(ruTranslations.values.keys)
	}
}
