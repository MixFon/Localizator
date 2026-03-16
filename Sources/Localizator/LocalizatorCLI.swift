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

    @Argument(help: "Папка или файл с которой нужно начинать поиск. По умолчанию текущая папка.")
    var path: String?

    @Option(name: .shortAndLong, help: "Путь до пакета MMTranslations, в его ресурсах будет поиск ключей.")
    var file: String = "../mmtranslation"
	
	@Option(name: .shortAndLong, help: "Префикс ключа по которому будут искаться существующие ключи. С него будут начинаться новые ключи")
	var prefix: String

    func run() async throws {

        let rootPath = path ?? FileManager.default.currentDirectoryPath

        let service = LocalizationService(
			prefix: prefix,
            rootPath: rootPath,
            filePath: file
        )

        try await service.run()
    }
}
