// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftSyntax
import SwiftParser

final class StringLocalizer: SyntaxRewriter {
	
	var countKeys: Int = 0
	
	override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
		
		let segments = node.segments
		
		// Проверяем наличие русских символов в любом сегменте
		var hasRussian = false
		for segment in segments {
			if let s = segment.as(StringSegmentSyntax.self),
			   s.content.text.range(of: "[А-Яа-я]", options: .regularExpression) != nil {
				hasRussian = true
				break
			}
		}
		
		if !hasRussian {
			return super.visit(node)
		}
		
		// Генерация читаемого ключа из текста
		let key = generateKey()
		
		// Собираем список аргументов интерполяции
		var interpolationArgs: [String] = []
		for segment in segments {
			if let s = segment.as(StringSegmentSyntax.self) {
				// сегмент текста, используем для генерации ключа
				continue
			}
			if let exprSegment = segment.as(ExpressionSegmentSyntax.self) {
				// сегмент интерполяции
				let exprText = exprSegment.expressions.description.trimmingCharacters(in: .whitespacesAndNewlines)
				interpolationArgs.append(exprText)
			}
		}
		
		// Собираем строку для парсинга
		let argsString = interpolationArgs.joined(separator: ", ")
		let newExpr: String
		if interpolationArgs.isEmpty {
			newExpr = "L(\"\(key)\")"
		} else {
			newExpr = "L(\"\(key)\", \(argsString))"
		}
		
		// Парсим новое выражение через Parser
		let parsed = Parser.parse(source: newExpr)
		if let stmt = parsed.statements.first,
		   let expr = stmt.item.as(ExprSyntax.self) {
			return expr
		}
		
		return super.visit(node)
	}

	private func generateKey() -> String {
		self.countKeys += 1
		return "mm_key_\(countKeys)"
	}
}


class SwiftFileScanner {
	
	func collectSwiftFiles(from path: String) -> [URL] {

		let fileManager = FileManager.default
		var result: [URL] = []

		var isDir: ObjCBool = false

		guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
			return []
		}

		// Если передали один Swift файл
		if !isDir.boolValue {
			if path.hasSuffix(".swift") {
				result.append(URL(fileURLWithPath: path))
			}
			return result
		}

		// Папки которые нужно игнорировать
		let ignoredDirectories: Set<String> = [
			".git",
			".build",
			"DerivedData",
			"Pods",
			"Carthage",
			".swiftpm",
			"build",
			"node_modules"
		]

		let rootURL = URL(fileURLWithPath: path)

		guard let enumerator = fileManager.enumerator(
			at: rootURL,
			includingPropertiesForKeys: [.isDirectoryKey],
			options: [.skipsHiddenFiles]
		) else {
			return []
		}

		for case let fileURL as URL in enumerator {

			let name = fileURL.lastPathComponent

			// Пропускаем ненужные директории
			if ignoredDirectories.contains(name) {
				enumerator.skipDescendants()
				continue
			}

			if fileURL.pathExtension == "swift" {
				result.append(fileURL)
			}
		}

		return result
	}
}

@main
struct Localizator {
	static func main() {
		print("Hello, world!")
		let rootPath = CommandLine.arguments.count > 1
			? CommandLine.arguments[1]
			: FileManager.default.currentDirectoryPath
		let fileScaner = SwiftFileScanner()
		let files = fileScaner.collectSwiftFiles(from: rootPath)
		let rewriter = StringLocalizer()
		for file in files {
			do {
				let source = try String(contentsOf: file)
				let syntaxTree = Parser.parse(source: source)
				print(syntaxTree.debugDescription)
				let result = rewriter.visit(syntaxTree)
				print(result)
				try "\(result)".write(to: file, atomically: true, encoding: .utf8)
				print("File processed")
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}

	}
}

