// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

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
			fileScaner.scan(file: file)
        }

    }
}
