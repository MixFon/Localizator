// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftParser
import Translation

final class LocalizationService {
	
	private let prefix: String
	private let rootPath: String
	private let filePath: String
	
	init(prefix: String, rootPath: String, filePath: String) {
		self.prefix = prefix
		self.rootPath = rootPath
		self.filePath = filePath
	}
	
	func run() async throws {
		let keyGenerator = KeyGenerator(prefix: self.prefix)
		let manager = LocalizationManager(prefix: self.prefix, keyGenerator: keyGenerator)
		
		let projectRoot = URL(fileURLWithPath: self.filePath)
		let translationsFile = projectRoot
			.appendingPathComponent("Sources/MMTranslation/Resources/metro_mobile_translations.json")
		manager.load(filePath: translationsFile.path)
		
		print(translationsFile.path)
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
	}
}

