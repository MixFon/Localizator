//
//  StringLocalizer.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//

import SwiftSyntax
import SwiftParser

final class StringLocalizer: SyntaxRewriter {
	
	private var manager: _LocalizationManager
	
	init(namaget: _LocalizationManager) {
		self.manager = namaget
	}
	
	override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
		
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
		
		// Проверяем наличие русского текста
		guard rawText.range(of: "[А-Яа-я]", options: .regularExpression) != nil else {
			return super.visit(node)
		}
		
		let key = self.manager.key(for: rawText)
		
		// Формируем новый вызов
		let newExpr: String
		if numberArgs.isEmpty {
			newExpr = "MMTranslation.text(.\(key))"
		} else {
			let args = numberArgs.joined(separator: ", ")
			newExpr = "MMTranslation.text(.\(key), numbers: \(args))"
		}
		let parsed = Parser.parse(source: newExpr)
		if let stmt = parsed.statements.first, let expr = stmt.item.as(ExprSyntax.self) {
			return expr
		}
		return super.visit(node)
	}
	
}
