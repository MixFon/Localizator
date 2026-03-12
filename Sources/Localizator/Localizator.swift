// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@main
struct Localizator {
	
	static func main() async {
		let rootPath = CommandLine.arguments.count > 1
		? CommandLine.arguments[1]
		: FileManager.default.currentDirectoryPath
		let filePath = "metro_mobile_translations.json" // Файл в корне проекта
		let manager = LocalizationManager(filePath: filePath)
		
		// Проверим работу
		if let key = manager.key(for: "Пополнить") {
			print("Ключ для 'Пополнить': \(key)") // mm_metro_replenish
		}
		
		print("Все маппинги:")
		for (russian, key) in manager.allMappings() {
			print("\(russian) -> \(key)")
		}
//		let fileScaner = FileScanner()
//		let files = fileScaner.collectSwiftFiles(from: rootPath)
//		let rewriter = StringLocalizer()
//		for file in files {
//			do {
//				let source = try String(contentsOf: file)
//				let syntaxTree = Parser.parse(source: source)
//				print(syntaxTree.debugDescription)
//				let result = rewriter.visit(syntaxTree)
//				print(result)
//				try "\(result)".write(to: file, atomically: true, encoding: .utf8)
//				print("File processed")
//			} catch {
//				print("Error: \(error.localizedDescription)")
//			}
//		}
		
	}
}

