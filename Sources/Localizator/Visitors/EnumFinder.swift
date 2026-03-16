//
//  EnumFinder.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax

final class EnumFinder: SyntaxVisitor {

	private let enumName: String
	var targetEnum: EnumDeclSyntax?

	init(enumName: String) {
		self.enumName = enumName
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {

		if node.name.text == enumName {
			targetEnum = node
			return .skipChildren
		}

		return .visitChildren
	}
}
