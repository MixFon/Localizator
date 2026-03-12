//
//  StringLiteralWorker.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//

import SwiftSyntax
import SwiftParser

protocol _StringLiteralWorker {
	/// Собирает строку делает из "Ваши имена \(name1), \(name2) сохранены" -> "Ваши имена %1$s, %2$s сохранеты"
	func prepareText(_ node: StringLiteralExprSyntax) -> String
	/// Возвращает интероляцию. "Ваши имена \(name1), \(name2) сохранены" -> ["name1", "name2"]
	func prepareInterpolation(_ node: StringLiteralExprSyntax) -> [String]
	/// Проверяет, находится ли строковый литерал в методе, который нужно игнорировать
	func isInsideIgnoredFunction(_ node: SyntaxProtocol) -> Bool
}

final class StringLiteralWorker: _StringLiteralWorker {
	
	private let ignoredFunctionNames: Set<String> = [
		"print","debugPrint","dump","NSLog",
		"assert","precondition","fatalError",
		"available","objc","warning","error"
	]
	
	func prepareText(_ node: StringLiteralExprSyntax) -> String {
		let segments = node.segments
		
		// Собираем текст для генерации ключа
		var rawText = ""
		var countExprSegment = 1
		var numberArgs: [String] = []
		for segment in segments {
			if let s = segment.as(StringSegmentSyntax.self) {
				rawText += s.content.text
			} else if let exprSegment = segment.as(ExpressionSegmentSyntax.self) {
				// Извлекаем интерполяции
				let exprText = exprSegment.expressions.description.trimmingCharacters(in: .whitespacesAndNewlines)
				numberArgs.append(exprText)
				rawText += "%\(countExprSegment)$s"
				countExprSegment += 1
			}
		}
		return rawText
	}
	
	func prepareInterpolation(_ node: StringLiteralExprSyntax) -> [String] {
		let segments = node.segments
		var numberArgs: [String] = []
		for segment in segments {
			if let exprSegment = segment.as(ExpressionSegmentSyntax.self) {
				// Извлекаем интерполяции
				let exprText = exprSegment.expressions.description.trimmingCharacters(in: .whitespacesAndNewlines)
				numberArgs.append(exprText)
			}
		}
		return numberArgs
		
	}
	
	func isInsideIgnoredFunction(_ node: SyntaxProtocol) -> Bool {
		var current = node.parent
		
		while let parent = current {
			if let call = parent.as(FunctionCallExprSyntax.self),
			   let decl = call.calledExpression.as(DeclReferenceExprSyntax.self) {
				let name = decl.baseName.text
				if ignoredFunctionNames.contains(name) {
					return true
				}
			}
			current = parent.parent
		}
		return false
	}
}
