//
//  EnumRewriter.swift
//  Localizator
//
//  Created by Михаил Фокин on 16.03.2026.
//

import SwiftSyntax

final class EnumRewriter: SyntaxRewriter {

    let newEnum: EnumDeclSyntax

    init(newEnum: EnumDeclSyntax) {
        self.newEnum = newEnum
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        if node.name.text == newEnum.name.text {
            return DeclSyntax(newEnum)
        }
        return super.visit(node)
    }
}
