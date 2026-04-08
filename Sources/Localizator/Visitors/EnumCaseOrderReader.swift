import Foundation
import SwiftParser
import SwiftSyntax

/// Одна строка `case name` или `case name = "raw"` в enum и индекс её `MemberBlockItem` в `memberBlock.members`.
struct EnumCaseEntry {
	let memberIndex: Int
	/// Имя case (идентификатор).
	let caseName: String
	/// Значение строкового литерала для `case foo = "bar"`, если есть.
	let rawStringValue: String?
}

enum EnumCaseOrderReaderError: Error {
	case enumNotFound
}

enum EnumCaseOrderReader {

	/// Все элементы `case` в порядке объявления в файле (с индексом члена блока enum).
	static func orderedCases(in fileURL: URL, enumName: String) throws -> [EnumCaseEntry] {
		let source = try String(contentsOf: fileURL, encoding: .utf8)
		let tree = Parser.parse(source: source)
		let finder = EnumFinder(enumName: enumName)
		finder.walk(tree)
		guard let enumNode = finder.targetEnum else {
			throw EnumCaseOrderReaderError.enumNotFound
		}
		var entries: [EnumCaseEntry] = []
		for (memberIndex, item) in enumNode.memberBlock.members.enumerated() {
			guard let caseDecl = item.decl.as(EnumCaseDeclSyntax.self) else { continue }
			for element in caseDecl.elements {
				let raw = Self.rawStringValue(from: element)
				entries.append(EnumCaseEntry(memberIndex: memberIndex, caseName: element.name.text, rawStringValue: raw))
			}
		}
		return entries
	}

	/// Ключи из JSON, которые уже «заняты»: имя case в snake_case и/или строковый raw value.
	static func coveredSnakeKeys(entries: [EnumCaseEntry]) -> Set<String> {
		var set = Set<String>()
		for e in entries {
			if let raw = e.rawStringValue {
				set.insert(raw)
			}
			if Self.looksLikeSnakeCaseIdentifier(e.caseName) {
				set.insert(e.caseName)
			}
			set.insert(TranslationKeyNaming.camelToSnake(e.caseName))
		}
		return set
	}

	/// Канонический snake-ключ для группировки и поиска блока (как в JSON).
	static func canonicalSnakeKey(for entry: EnumCaseEntry) -> String {
		if let raw = entry.rawStringValue {
			return raw
		}
		if Self.looksLikeSnakeCaseIdentifier(entry.caseName) {
			return entry.caseName
		}
		return TranslationKeyNaming.camelToSnake(entry.caseName)
	}

	private static func looksLikeSnakeCaseIdentifier(_ name: String) -> Bool {
		name.contains("_")
			&& name == name.lowercased()
			&& name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
	}

	private static func rawStringValue(from element: EnumCaseElementSyntax) -> String? {
		guard let initClause = element.rawValue else { return nil }
		let expr = initClause.value
		guard let strLit = expr.as(StringLiteralExprSyntax.self) else { return nil }
		return simpleStringLiteralContent(strLit)
	}

	/// Только простой `"..."` без интерполяции.
	private static func simpleStringLiteralContent(_ node: StringLiteralExprSyntax) -> String? {
		var result = ""
		for segment in node.segments {
			if let s = segment.as(StringSegmentSyntax.self) {
				result += s.content.text
			} else {
				return nil
			}
		}
		return result
	}
}
