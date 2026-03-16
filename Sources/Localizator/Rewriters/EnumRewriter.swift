//
//  EnumRewriter.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax

final class EnumRewriter: SyntaxRewriter {

	private let enumName: String
	private let newEnum: EnumDeclSyntax

	init(enumName: String, newEnum: EnumDeclSyntax) {
		self.enumName = enumName
		self.newEnum = newEnum
	}

	override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {

		if node.name.text == enumName {
			return DeclSyntax(newEnum)
		}

		return super.visit(node)
	}
}
