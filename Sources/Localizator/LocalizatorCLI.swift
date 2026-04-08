//
//  LocalizatorCLI.swift
//  Localizator
//
//  Created by Михаил Фокин on 12.03.2026.
//


import ArgumentParser
import Foundation

struct MMTranslationOptions: ParsableArguments {

    @Option(name: .shortAndLong, help: "Путь до пакета MMTranslations, в его ресурсах будет поиск ключей.")
    var file: String = "../mmtranslation"

    @Option(name: .shortAndLong, help: "Префикс ключа по которому будут искаться существующие ключи. С него будут начинаться новые ключи")
    var prefix: String
}

struct LocalizeCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "localize",
        abstract: "Локализация Swift-исходников"
    )

    @OptionGroup var options: MMTranslationOptions

    @Argument(help: "Папка или файл с которой нужно начинать поиск. По умолчанию текущая папка.")
    var path: String?

    func run() async throws {
        let rootPath = path ?? FileManager.default.currentDirectoryPath
        let service = LocalizationService(
            prefix: options.prefix,
            rootPath: rootPath,
            filePath: options.file
        )
        try await service.run()
    }
}

struct DuplicatesCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "duplicates",
        abstract: "Поиск дубликатов ключей"
    )

    @OptionGroup var options: MMTranslationOptions

    func run() throws {
        let dupService = DuplicateService(prefix: options.prefix, filePath: options.file)
        try dupService.run()
    }
}

struct ActualizationCommand: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "actualization",
		abstract: "Добавляет в MMTranslationKeys case для ключей из metro_mobile_translations.json с заданным префиксом, которых ещё нет в enum."
	)

	@OptionGroup var options: MMTranslationOptions

	func run() throws {
		let actualService = ActualizationService(prefix: options.prefix, filePath: options.file)
		try actualService.run()
	}
}

struct LocalizatorCLI: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "localizator",
        abstract: "Swift source code localizer",
        subcommands: [LocalizeCommand.self, DuplicatesCommand.self, ActualizationCommand.self],
        defaultSubcommand: LocalizeCommand.self
    )

    func run() async throws {}
}
