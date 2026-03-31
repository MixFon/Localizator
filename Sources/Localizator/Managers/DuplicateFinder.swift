//
//  DuplicateFinder.swift
//  Localizator
//
//  Created by Михаил Фокин on 30.03.2026.
//

import Foundation

/// Поиск дубликатов и почти совпадающих русских строк среди ключей с заданным префиксом.
final class DuplicateFinder {
	private let prefix: String
	private let jsonLoader: _JsonLoader
	/// Все пары ключ → русский текст из JSON (ru-RU, `.text`).
	private var keyToText: [String: String] = [:]
	
	init(prefix: String, jsonLoader: _JsonLoader) {
		self.prefix = prefix
		self.jsonLoader = jsonLoader
	}
	
	func load(filePath: String) throws {
		try jsonLoader.load(filePath: filePath) { [weak self] key, text in
			guard let self else { return }
			self.keyToText[key] = text
		}
	}
	
	// MARK: - Дубликаты (одинаковый текст у разных ключей)
	
	/// Ключи с префиксом `prefix` и их тексты.
	private var prefixedEntries: [(key: String, text: String)] {
		keyToText
			.filter { $0.key.hasPrefix(prefix) }
			.map { ($0.key, $0.value) }
			.sorted { $0.key < $1.key }
	}
	
	/// Строки вида `"key" -> "value"` только для ключей с префиксом, у которых **один и тот же** русский текст встречается у нескольких ключей.
	func duplicateKeyValueLines() -> [String] {
		var textToKeys: [String: [String]] = [:]
		for (key, text) in prefixedEntries {
			textToKeys[text, default: []].append(key)
		}
		let groups = textToKeys.filter { $0.value.count > 1 }.sorted(by: { $0.key < $1.key })
		var lines: [String] = []
		for (idx, (text, keys)) in groups.enumerated() {
			for key in keys.sorted() {
				lines.append(#""\#(key)" -> "\#(text)""#)
			}
			if idx < groups.count - 1 {
				lines.append("")
			}
		}
		return lines
	}
	
	func printDuplicateKeyValues() {
		let lines = duplicateKeyValueLines()
		guard !lines.isEmpty else {
			print("Дубликатов текста среди ключей с префиксом «\(prefix)» не найдено.")
			return
		}
		print("Дубликаты (одинаковый текст, разные ключи), префикс «\(prefix)»:")
		for line in lines {
			print(line)
		}
	}
	
	// MARK: - Похожие строки (несколько отличающихся символов)
	
	/// Пары ключей с префиксом, у которых русские тексты различаются на `1...maxEditDistance` правок (Левенштейн).
	func similarKeyValuePairs(maxEditDistance: Int = 2) -> [(key1: String, text1: String, key2: String, text2: String, distance: Int)] {
		let entries = prefixedEntries
		var result: [(key1: String, text1: String, key2: String, text2: String, distance: Int)] = []
		for i in entries.indices {
			for j in (i + 1)..<entries.count {
				let (k1, t1) = entries[i]
				let (k2, t2) = entries[j]
				guard t1 != t2 else { continue }
				let d = Self.levenshtein(t1, t2)
				if d > 0, d <= maxEditDistance {
					result.append((key1: k1, text1: t1, key2: k2, text2: t2, distance: d))
				}
			}
		}
		return result
	}
	
	func similarKeyValueLines(maxEditDistance: Int = 2) -> [String] {
		similarKeyValuePairs(maxEditDistance: maxEditDistance).map(Self.similarLine)
	}
	
	func printSimilarKeyValues(maxEditDistance: Int = 2) {
		let pairs = similarKeyValuePairs(maxEditDistance: maxEditDistance)
		guard !pairs.isEmpty else {
			print("Похожих строк (правок ≤ \(maxEditDistance)) среди ключей с префиксом «\(prefix)» не найдено.")
			return
		}
		print("Похожие строки (Левенштейн 1…\(maxEditDistance)), префикс «\(prefix)»:")
		for line in pairs.map(Self.similarLine) {
			print(line)
		}
	}
	
	private static func similarLine(
		_ pair: (key1: String, text1: String, key2: String, text2: String, distance: Int)
	) -> String {
		"Δ\(pair.distance)\t\"\(pair.key1)\" -> \"\(pair.text1)\"  \n\t\"\(pair.key2)\" -> \"\(pair.text2)\"\n"
	}
	
	private static func levenshtein(_ a: String, _ b: String) -> Int {
		let a = Array(a)
		let b = Array(b)
		var dp = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
		for i in 0...a.count { dp[i][0] = i }
		for j in 0...b.count { dp[0][j] = j }
		for i in 1...a.count {
			for j in 1...b.count {
				let cost = a[i - 1] == b[j - 1] ? 0 : 1
				dp[i][j] = min(
					dp[i - 1][j] + 1,
					dp[i][j - 1] + 1,
					dp[i - 1][j - 1] + cost
				)
			}
		}
		return dp[a.count][b.count]
	}
}
