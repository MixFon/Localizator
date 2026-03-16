//
//  TranslationKeysManager.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import Foundation
import SwiftSyntax
import SwiftParser


protocol TranslationKeysManaging {
	func insertKeys(
		into fileURL: URL,
		enumName: String,
		prefix: String,
		keys: [String]
	) throws
}

enum ManagerError: Error {
	case enumNotFound
	case prefixNotFound
}

final class TranslationKeysManager: TranslationKeysManaging {

    func insertKeys(
        into fileURL: URL,
        enumName: String,
        prefix: String,
        keys: [String]
    ) throws {

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
}

private extension TranslationKeysManager {

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
}
