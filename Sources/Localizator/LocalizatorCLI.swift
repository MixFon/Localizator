//
//  LocalizatorCLI.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//


import ArgumentParser
import Foundation

struct LocalizatorCLI: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "localizator",
        abstract: "Swift source code localizer"
    )

    @Argument(help: "Root folder with Swift files")
    var path: String?

    @Option(name: .shortAndLong, help: "Translations JSON file")
    var file: String = "metro_mobile_translations.json"

    func run() async throws {

        let rootPath = path ?? FileManager.default.currentDirectoryPath

        let service = LocalizationService(
            rootPath: rootPath,
            filePath: file
        )

        try await service.run()
    }
}
