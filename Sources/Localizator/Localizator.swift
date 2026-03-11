// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftSyntax
import SwiftParser

final class StringLocalizer: SyntaxRewriter {
	
	override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {

		guard node.segments.count == 1,
			  let segment = node.segments.first?.as(StringSegmentSyntax.self)
		else {
			return super.visit(node)
		}

		let text = segment.content.text

		if text.range(of: "[А-Яа-я]", options: .regularExpression) == nil {
			return super.visit(node)
		}

		let key = generateKey(from: text)

		let newExpr = "L(\"\(key)\")"

		// парсим новое выражение
		let parsed = Parser.parse(source: newExpr)

		if let stmt = parsed.statements.first,
		   let expr = stmt.item.as(ExprSyntax.self) {
			return expr
		}

		return super.visit(node)
	}

	private func generateKey(from text: String) -> String {
		text
			.lowercased()
			.replacingOccurrences(of: " ", with: "_")
			.replacingOccurrences(of: "[^a-zа-я0-9_]", with: "", options: .regularExpression)
	}
}


class SwiftFileScanner {
	
    func swiftFiles(at path: String) -> [String] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: path) else { return [] }
        var files: [String] = []
        for case let file as String in enumerator {
            if file.hasSuffix(".swift") {
                files.append((path as NSString).appendingPathComponent(file))
            }
        }
        return files
    }
	
    func scan(file: String) {
        guard let content = try? String(contentsOfFile: file) else { return }
        let regex = try! NSRegularExpression(pattern: "\"[^\"]*[А-Яа-яЁё][^\"]*\"", options: [])
        let lines = content.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.utf16.count)
            if regex.firstMatch(in: line, options: [], range: range) != nil {
                print("\(file):\(index + 1)")
                print("   \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
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
        let files = fileScaner.swiftFiles(at: rootPath)
        for file in files {
			//fileScaner.scan(file: file)
			do {
				let url = URL(fileURLWithPath: file)
				print(url.absoluteString)
				let source = try String(contentsOf: url)
				let syntax = Parser.parse(source: source)

				let rewriter = StringLocalizer()
				let result = rewriter.visit(syntax)

				try "\(result)".write(to: url, atomically: true, encoding: .utf8)

				print("File processed")

			} catch {
				print("Error: \(error.localizedDescription)")
			}
        }

    }
}

