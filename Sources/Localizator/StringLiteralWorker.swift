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
	/// Нужно ли не трогать литерал: отладочные контексты (`print`, `#Preview`, …), `#if DEBUG`, мок-строки (`Mock`), или в собранном тексте нет кириллицы.
	func shouldSkipStringLiteral(_ node: StringLiteralExprSyntax) -> Bool
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
	
	func shouldSkipStringLiteral(_ node: StringLiteralExprSyntax) -> Bool {
		if isInsidePreviewMacro(node) {
			return true
		}
		if isInsidePreviewProviderContext(node) {
			return true
		}
		if isInsidePlainIfConfigDebugBranch(node) {
			return true
		}
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
		let rawText = prepareText(node)
		if preparedTextContainsMockSubstring(rawText) {
			return true
		}
		if !preparedTextContainsCyrillic(rawText) {
			return true
		}
		return false
	}
	
	private func preparedTextContainsMockSubstring(_ text: String) -> Bool {
		text.range(of: "Mock", options: .caseInsensitive) != nil
	}
	
	private func preparedTextContainsCyrillic(_ text: String) -> Bool {
		text.range(of: "[А-Яа-я]", options: .regularExpression) != nil
	}
	
	/// Литерал внутри ветки `#if DEBUG` / `#elseif DEBUG` (включая вложенные блоки и `#if` внутри выражения).
	private func isInsidePlainIfConfigDebugBranch(_ node: SyntaxProtocol) -> Bool {
		var current: Syntax? = Syntax(fromProtocol: node)
		while let c = current {
			if let clause = c.as(IfConfigClauseSyntax.self),
			   let condition = clause.condition,
			   ifConfigConditionIsPlainDebug(condition) {
				return true
			}
			current = c.parent
		}
		return false
	}
	
	private func ifConfigConditionIsPlainDebug(_ expr: ExprSyntax) -> Bool {
		if let ref = expr.as(DeclReferenceExprSyntax.self) {
			return ref.baseName.text == "DEBUG"
		}
		return false
	}
	
	/// Литерал внутри макроса `#Preview { … }` / `#Preview("…") { … }`.
	private func isInsidePreviewMacro(_ node: SyntaxProtocol) -> Bool {
		var current: Syntax? = Syntax(fromProtocol: node)
		while let parent = current {
			if let decl = parent.as(MacroExpansionDeclSyntax.self), decl.macroName.text == "Preview" {
				return true
			}
			if let expr = parent.as(MacroExpansionExprSyntax.self), expr.macroName.text == "Preview" {
				return true
			}
			current = parent.parent
		}
		return false
	}
	
	/// Литерал внутри типа или `extension`, объявленных с наследованием от `PreviewProvider` (в т.ч. `SwiftUI.PreviewProvider`).
	private func isInsidePreviewProviderContext(_ node: SyntaxProtocol) -> Bool {
		var current: Syntax? = Syntax(fromProtocol: node)
		while let parent = current {
			if let s = parent.as(StructDeclSyntax.self), inheritsPreviewProvider(s.inheritanceClause) {
				return true
			}
			if let c = parent.as(ClassDeclSyntax.self), inheritsPreviewProvider(c.inheritanceClause) {
				return true
			}
			if let e = parent.as(EnumDeclSyntax.self), inheritsPreviewProvider(e.inheritanceClause) {
				return true
			}
			if let a = parent.as(ActorDeclSyntax.self), inheritsPreviewProvider(a.inheritanceClause) {
				return true
			}
			if let x = parent.as(ExtensionDeclSyntax.self), inheritsPreviewProvider(x.inheritanceClause) {
				return true
			}
			current = parent.parent
		}
		return false
	}
	
	private func inheritsPreviewProvider(_ clause: InheritanceClauseSyntax?) -> Bool {
		guard let clause else { return false }
		for inherited in clause.inheritedTypes {
			if typeRefersToPreviewProvider(inherited.type) {
				return true
			}
		}
		return false
	}
	
	private func typeRefersToPreviewProvider(_ type: TypeSyntax) -> Bool {
		let base = typeWithoutAttributes(type)
		if let id = base.as(IdentifierTypeSyntax.self) {
			return id.name.text == "PreviewProvider"
		}
		if let member = base.as(MemberTypeSyntax.self) {
			return member.name.text == "PreviewProvider"
		}
		if let comp = base.as(CompositionTypeSyntax.self) {
			return comp.elements.contains { element in
				typeRefersToPreviewProvider(element.type)
			}
		}
		return false
	}
	
	private func typeWithoutAttributes(_ type: TypeSyntax) -> TypeSyntax {
		if let attr = type.as(AttributedTypeSyntax.self) {
			return typeWithoutAttributes(attr.baseType)
		}
		return type
	}
}
