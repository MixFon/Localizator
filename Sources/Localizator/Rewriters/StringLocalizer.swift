//
//  StringLocalizer.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax
import SwiftParser

final class StringLocalizer: SyntaxRewriter {
	
	private let worker: _StringLiteralWorker
	private let manager: _LocalizationManager
	
	init(manager: _LocalizationManager, worker: _StringLiteralWorker) {
		self.worker = worker
		self.manager = manager
	}
	
	override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
		if self.worker.isInsideIgnoredFunction(node) {
			return super.visit(node)
		}
		let rawText = self.worker.prepareText(node)
		
		// Проверяем наличие русского текста
		guard rawText.range(of: "[А-Яа-я]", options: .regularExpression) != nil else {
			return super.visit(node)
		}
		
		let key = self.manager.key(for: rawText)
		
		let numberArgs = self.worker.prepareInterpolation(node)
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
