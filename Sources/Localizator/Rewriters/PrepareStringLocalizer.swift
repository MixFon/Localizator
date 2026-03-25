//
//  PrepareStringLocalizer.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax
import SwiftParser

final class PrepareStringLocalizer: SyntaxRewriter {
	
	private let worker: _StringLiteralWorker
	private let manager: _LocalizationManager
	
	init(manager: _LocalizationManager, worker: _StringLiteralWorker) {
		self.worker = worker
		self.manager = manager
	}
	
	override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
		if self.worker.shouldSkipStringLiteral(node) {
			return super.visit(node)
		}
		let rawText = self.worker.prepareText(node)
		self.manager.saveForTranslate(rawText)
		return super.visit(node)
	}
	
}
