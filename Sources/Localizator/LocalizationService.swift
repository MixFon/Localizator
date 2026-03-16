// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftParser
import SwiftSyntax
import Translation

final class LocalizationService {
	
	private let prefix: String
	private let rootPath: String
	private let filePath: String
	
	private let pathToJSON: String = "Sources/MMTranslation/Resources/metro_mobile_translations.json"
	private let pathToKeys: String = "Sources/MMTranslation/Models/ServicesKeys/MMTranslationKeys.swift"

	init(prefix: String, rootPath: String, filePath: String) {
		self.prefix = prefix
		self.rootPath = rootPath
		self.filePath = filePath
	}
	
	func run() async throws {
		let keyGenerator = KeyGenerator(prefix: self.prefix)
		let manager = LocalizationManager(prefix: self.prefix, keyGenerator: keyGenerator)
		
		let projectRoot = URL(fileURLWithPath: self.filePath)
		let translationsFile = projectRoot.appendingPathComponent(self.pathToJSON)
		manager.load(filePath: translationsFile.path(percentEncoded: true))

		let fileScaner = FileScanner()
		let files = fileScaner.collectSwiftFiles(from: rootPath)
		let worker = StringLiteralWorker()
		let prepareRewriter = PrepareStringLocalizer(manager: manager, worker: worker)
		for file in files {
			do {
				let source = try String(contentsOf: file, encoding: .utf8)
				let syntaxTree = Parser.parse(source: source)
				_ = prepareRewriter.visit(syntaxTree)
				print("File processed")
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
		
		await manager.translating()
		
		let rewriter = StringLocalizer(manager: manager, worker: worker)
		for file in files {
			do {
				let source = try String(contentsOf: file, encoding: .utf8)
				let syntaxTree = Parser.parse(source: source)
				let result = rewriter.visit(syntaxTree)
				try "\(result)".write(to: file, atomically: true, encoding: .utf8)
				print("File processed")
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
		
		let keysFile = projectRoot.appendingPathComponent(self.pathToKeys)
		let source = try String(contentsOfFile: keysFile.path(percentEncoded: true), encoding: .utf8)
		let tree = Parser.parse(source: source)
		
		let finder = EnumFinder(viewMode: .sourceAccurate)
		finder.walk(tree)

		guard let enumNode = finder.targetEnum else {
			fatalError("Enum not found")
		}
		
		let members = enumNode.memberBlock.members

		guard let insertIndex = lastCaseIndex(in: members, prefix: "mm_metro_") else {
			fatalError("Prefix cases not found")
		}
		
		var newMembers = members

		let newKeys = [
			"mm_metro_new_key1",
			"mm_metro_new_key2"
		]

		let newCases = newKeys.map { makeCase($0) }
		var insertPosition = newMembers.index(newMembers.startIndex, offsetBy: insertIndex + 1)

		for newCase in newCases {
			newMembers.insert(newCase, at: insertPosition)
			insertPosition = newMembers.index(after: insertPosition)
		}
		
		let newEnum = enumNode.with(\.memberBlock.members, newMembers)
		let rewriterEnum = EnumRewriter(newEnum: newEnum)
		let result = rewriterEnum.visit(tree)

		try "\(result)".write(toFile: filePath, atomically: true, encoding: .utf8)
	}
	
	func lastCaseIndex(in members: MemberBlockItemListSyntax, prefix: String) -> Int? {

		var index: Int?
		
		for (i, item) in members.enumerated() {
			guard let caseDecl = item.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}

			for element in caseDecl.elements {
				if element.name.text.hasPrefix(prefix) {
					index = i
				}
			}
		}

		return index
	}
	
	func makeCase(_ name: String) -> MemberBlockItemSyntax {
		let caseDecl = EnumCaseDeclSyntax(
			caseKeyword: .keyword(.case),
			elements: EnumCaseElementListSyntax([
				EnumCaseElementSyntax(
					name: .identifier(name)
				)
			])
		)

		return MemberBlockItemSyntax(
			decl: DeclSyntax(caseDecl)
		)
	}
}

