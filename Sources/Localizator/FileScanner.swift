//
//  FileScanner.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//

import Foundation

class FileScanner {
	
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
