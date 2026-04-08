//
//  EnumManager.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import Foundation
import SwiftSyntax
import SwiftParser

protocol _EnumManager {
	func insertKeys(into fileURL: URL, enumName: String, prefix: String, keys: [String]) throws
	/// Вставляет подряд новые `case` перед элементом с индексом `insertBeforeMemberIndex` (0 — перед первым членом блока).
	func insertKeys(into fileURL: URL, enumName: String, keys: [String], insertBeforeMemberIndex: Int) throws
	/// Как `insertKeys`, но каждая строка — snake_case: `case mm_foo = "mm_foo"` (для `String` raw enum).
	func insertSnakeCaseRawKeys(into fileURL: URL, enumName: String, keys: [String], insertBeforeMemberIndex: Int) throws
}

enum ManagerError: Error {
	case enumNotFound
	case prefixNotFound
	case invalidMemberIndex
	case snakeCaseProbeParseFailed(key: String)
}

final class EnumManager: _EnumManager {

    func insertKeys(into fileURL: URL, enumName: String, prefix: String, keys: [String]) throws {
        let source = try String(contentsOf: fileURL, encoding: .utf8)
        let tree = Parser.parse(source: source)

        let finder = EnumFinder(enumName: enumName)
        finder.walk(tree)

        guard let enumNode = finder.targetEnum else {
            throw ManagerError.enumNotFound
        }

        let members = enumNode.memberBlock.members
		var newMembers = members

		let insertIndex = lastCaseIndex(in: members, prefix: prefix) ?? -1 // Потом прибавится 1

        let newCases = keys.map(makeCase)

        var insertPosition = newMembers.index(
            newMembers.startIndex,
            offsetBy: insertIndex + 1
        )

        for newCase in newCases {
            newMembers.insert(newCase, at: insertPosition)
            insertPosition = newMembers.index(after: insertPosition)
        }

        let newEnum = enumNode.with(\.memberBlock.members, newMembers)

        let rewriter = EnumRewriter(
            enumName: enumName,
            newEnum: newEnum
        )

        let result = rewriter.visit(tree)

        try "\(result)".write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )
    }

	func insertKeys(into fileURL: URL, enumName: String, keys: [String], insertBeforeMemberIndex: Int) throws {
		guard !keys.isEmpty else { return }

		let source = try String(contentsOf: fileURL, encoding: .utf8)
		let tree = Parser.parse(source: source)

		let finder = EnumFinder(enumName: enumName)
		finder.walk(tree)

		guard let enumNode = finder.targetEnum else {
			throw ManagerError.enumNotFound
		}

		let members = enumNode.memberBlock.members
		let memberCount = members.count
		guard insertBeforeMemberIndex >= 0, insertBeforeMemberIndex <= memberCount else {
			throw ManagerError.invalidMemberIndex
		}

		var newMembers = members
		let newCases = keys.map(makeCase)

		var insertPosition = newMembers.index(newMembers.startIndex, offsetBy: insertBeforeMemberIndex)
		for newCase in newCases {
			newMembers.insert(newCase, at: insertPosition)
			insertPosition = newMembers.index(after: insertPosition)
		}

		let newEnum = enumNode.with(\.memberBlock.members, newMembers)

		let rewriter = EnumRewriter(
			enumName: enumName,
			newEnum: newEnum
		)

		let result = rewriter.visit(tree)

		try "\(result)".write(
			to: fileURL,
			atomically: true,
			encoding: .utf8
		)
	}

	func insertSnakeCaseRawKeys(into fileURL: URL, enumName: String, keys: [String], insertBeforeMemberIndex: Int) throws {
		guard !keys.isEmpty else { return }

		let source = try String(contentsOf: fileURL, encoding: .utf8)
		let tree = Parser.parse(source: source)

		let finder = EnumFinder(enumName: enumName)
		finder.walk(tree)

		guard let enumNode = finder.targetEnum else {
			throw ManagerError.enumNotFound
		}

		let members = enumNode.memberBlock.members
		let memberCount = members.count
		guard insertBeforeMemberIndex >= 0, insertBeforeMemberIndex <= memberCount else {
			throw ManagerError.invalidMemberIndex
		}

		var newMembers = members
		let newCases = try keys.map { try makeSnakeCaseRawMemberItem(snakeKey: $0) }

		var insertPosition = newMembers.index(newMembers.startIndex, offsetBy: insertBeforeMemberIndex)
		for newCase in newCases {
			newMembers.insert(newCase, at: insertPosition)
			insertPosition = newMembers.index(after: insertPosition)
		}

		let newEnum = enumNode.with(\.memberBlock.members, newMembers)

		let rewriter = EnumRewriter(
			enumName: enumName,
			newEnum: newEnum
		)

		let result = rewriter.visit(tree)

		try "\(result)".write(
			to: fileURL,
			atomically: true,
			encoding: .utf8
		)
	}
}

private extension EnumManager {

	func lastCaseIndex(in members: MemberBlockItemListSyntax, prefix: String) -> Int? {

		for (i, item) in members.enumerated() {

			guard let caseDecl = item.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}

			for element in caseDecl.elements {
				if element.name.text.hasPrefix(prefix) {
					return i
				}
			}
		}
		return nil
	}

	func makeCase(_ name: String) -> MemberBlockItemSyntax {

		var caseKeyword = TokenSyntax.keyword(.case)
		caseKeyword.leadingTrivia = .newline + .tab
		caseKeyword.trailingTrivia = .space

		let element = EnumCaseElementSyntax(name: .identifier(name))

		let caseDecl = EnumCaseDeclSyntax(
			caseKeyword: caseKeyword,
			elements: EnumCaseElementListSyntax([element])
		)

		return MemberBlockItemSyntax(
			decl: DeclSyntax(caseDecl),
			trailingTrivia: .tab
		)
	}

	/// `case snake_key` с оформлением как у `makeCase`.
	func makeSnakeCaseRawMemberItem(snakeKey: String) throws -> MemberBlockItemSyntax {
		let probeSource = """
		enum __LocalizatorProbe {
		\tcase \(snakeKey)
		}
		"""

		let probeTree = Parser.parse(source: probeSource)
		guard
			let firstStmt = probeTree.statements.first,
			let probeEnum = firstStmt.item.as(EnumDeclSyntax.self),
			let firstMember = probeEnum.memberBlock.members.first,
			var caseDecl = firstMember.decl.as(EnumCaseDeclSyntax.self)
		else {
			throw ManagerError.snakeCaseProbeParseFailed(key: snakeKey)
		}

		var caseKeyword = caseDecl.caseKeyword
		caseKeyword.leadingTrivia = .newline + .tab
		caseKeyword.trailingTrivia = .space
		caseDecl = caseDecl.with(\.caseKeyword, caseKeyword)

		let item = firstMember
			.with(\.decl, DeclSyntax(caseDecl))
			.with(\.trailingTrivia, .tab)

		return item
	}
}
