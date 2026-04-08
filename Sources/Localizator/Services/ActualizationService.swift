//
//  ActualizationService.swift
//  Localizator
//
//  Created by Михаил Фокин on 07.04.2026.
//

import Foundation

final class ActualizationService {

	private let pathToJSON = "Sources/MMTranslation/Resources/metro_mobile_translations.json"
	private let pathToKeys = "Sources/MMTranslation/Models/ServicesKeys/MMTranslationKeys.swift"

	/// Префикс snake-ключей из JSON; обрабатываются только ключи с `hasPrefix(prefix)`.
	private let prefix: String
	private let filePath: String
	private let jsonLoader: _JsonLoader
	private let enumManager: _EnumManager

	init(
		prefix: String,
		filePath: String,
		jsonLoader: _JsonLoader = JsonLoader(),
		enumManager: _EnumManager = EnumManager()
	) {
		self.prefix = prefix
		self.filePath = filePath
		self.jsonLoader = jsonLoader
		self.enumManager = enumManager
	}

	func run() throws {
		let root = URL(fileURLWithPath: filePath)
		let jsonURL = root.appendingPathComponent(pathToJSON)
		let keysURL = root.appendingPathComponent(pathToKeys)

		let jsonKeys = try jsonLoader.allTranslationKeys(filePath: jsonURL.path)
		let keysForRun = jsonKeys.filter { $0.hasPrefix(prefix) }
		if keysForRun.isEmpty {
			print("Актуализация: в JSON нет ключей с префиксом «\(prefix)».")
			return
		}

		let orderedCases = try EnumCaseOrderReader.orderedCases(in: keysURL, enumName: "MMTranslationKeys")
		let covered = EnumCaseOrderReader.coveredSnakeKeys(entries: orderedCases)

		var missingByGroup: [String: [String]] = [:]
		for snake in keysForRun where !covered.contains(snake) {
			let group = TranslationKeyNaming.groupPrefix(ofSnakeKey: snake)
			missingByGroup[group, default: []].append(snake)
		}
		for g in missingByGroup.keys {
			missingByGroup[g]?.sort()
		}

		guard !missingByGroup.isEmpty else {
			print("Актуализация: новых ключей нет.")
			return
		}

		var indexToKeys: [Int: [String]] = [:]
		for groupPrefix in missingByGroup.keys.sorted() {
			guard let snakes = missingByGroup[groupPrefix] else { continue }
			let insertBefore = insertBeforeMemberIndex(forGroupPrefix: groupPrefix, orderedCases: orderedCases)
			indexToKeys[insertBefore, default: []].append(contentsOf: snakes)
		}

		let keysURLPath = keysURL.path
		for insertIndex in indexToKeys.keys.sorted(by: >) {
			guard let keys = indexToKeys[insertIndex], !keys.isEmpty else { continue }
			try enumManager.insertSnakeCaseRawKeys(
				into: URL(fileURLWithPath: keysURLPath),
				enumName: "MMTranslationKeys",
				keys: keys,
				insertBeforeMemberIndex: insertIndex
			)
		}

		let total = missingByGroup.values.reduce(0) { $0 + $1.count }
		print("Актуализация: добавлено \(total) case (\(missingByGroup.count) групп) в \(pathToKeys).")
	}

	/// Индекс члена `memberBlock`, перед которым нужно вставить новые кейсы группы `group`.
	private func insertBeforeMemberIndex(forGroupPrefix group: String, orderedCases: [EnumCaseEntry]) -> Int {
		for entry in orderedCases {
			let snake = EnumCaseOrderReader.canonicalSnakeKey(for: entry)
			let g = TranslationKeyNaming.groupPrefix(ofSnakeKey: snake)
			if g == group {
				return entry.memberIndex
			}
		}
		return orderedCases.first?.memberIndex ?? 0
	}
}
