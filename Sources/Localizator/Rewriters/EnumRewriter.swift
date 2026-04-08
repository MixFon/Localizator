//
//  EnumRewriter.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax

/// Обходит Swift-AST и подменяет объявление `enum` с указанным именем на заранее подготовленное дерево.
///
/// Нужен при актуализации файла с ключами (например `MMTranslationKeys`): после вставки новых `case`
/// в `EnumDeclSyntax` rewriter заменяет старый enum целиком, остальной исходник проходит без изменений.
final class EnumRewriter: SyntaxRewriter {

	private let enumName: String
	private let newEnum: EnumDeclSyntax

	/// - Parameters:
	///   - enumName: Имя enum в исходнике (без `enum` и без generic), должно совпадать с `node.name.text`.
	///   - newEnum: Полное новое объявление enum, которым будет заменено совпадение.
	init(enumName: String, newEnum: EnumDeclSyntax) {
		self.enumName = enumName
		self.newEnum = newEnum
	}

	/// Если это объявление нужного enum — возвращает `newEnum`, иначе рекурсивно обрабатывает детей.
	override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {

		if node.name.text == enumName {
			return DeclSyntax(newEnum)
		}

		return super.visit(node)
	}
}
