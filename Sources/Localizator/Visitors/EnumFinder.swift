//
//  EnumFinder.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax

final class EnumFinder: SyntaxVisitor {

    var targetEnum: EnumDeclSyntax?

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.text == "MMTranslationKeys" {
            targetEnum = node
            return .skipChildren
        }
        return .visitChildren
    }
}
