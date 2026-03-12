// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftParser
import Translation

final class LocalizationService {
	
	let rootPath: String
	let filePath: String
	
	init(rootPath: String, filePath: String) {
		self.rootPath = rootPath
		self.filePath = filePath
	}
	
	func run() async throws {
		let filePath = "metro_mobile_translations.json" // Файл в корне проекта
		let keyGenerator = KeyGenerator(prefix: "mm_velo")
		let manager = LocalizationManager(keyGenerator: keyGenerator)
		manager.load(filePath: filePath)
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
				print(result)
				print("File processed")
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}
}

