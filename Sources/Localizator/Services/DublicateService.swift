//
//  DublicateService.swift
//  Localizator
//
//  Created by Михаил Фокин on 30.03.2026.
//

import Foundation

final class DublicateService {
	/// Префикс для новых ключей и поиска существующих в JSON.
	private let prefix: String
	/// Путь к корню пакета MMTranslation (ресурсы и ключи относительно него).
	private let filePath: String
	
	/// Относительный путь к JSON с переводами внутри пакета MMTranslation.
	private let pathToJSON: String = "Sources/MMTranslation/Resources/metro_mobile_translations.json"
	
	/// - Parameters:
	///   - prefix: Префикс ключей локализации.
	///   - filePath: Каталог пакета MMTranslation.
	init(prefix: String, filePath: String) {
		self.prefix = prefix
		self.filePath = filePath
	}
	
	func run() throws {
		let jsonLoader = JsonLoader()
		let finder = DublicateFinder(prefix: prefix, jsonLoader: jsonLoader)
		let jsonURL = URL(fileURLWithPath: filePath).appendingPathComponent(pathToJSON)
		try finder.load(filePath: jsonURL.path(percentEncoded: true))
		finder.printDuplicateKeyValues()
		finder.printSimilarKeyValues()
	}
}
