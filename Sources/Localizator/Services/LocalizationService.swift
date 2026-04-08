import Foundation
import SwiftParser
import SwiftSyntax
import Translation

/// Оркестрация локализации: сбор строк, перевод, подмена литералов и обновление enum ключей.
final class LocalizationService {
	
	/// Префикс для новых ключей и поиска существующих в JSON.
	private let prefix: String
	/// Корневая папка рекурсивного поиска `.swift` файлов.
	private let rootPath: String
	/// Путь к корню пакета MMTranslation (ресурсы и ключи относительно него).
	private let filePath: String
	
	/// Относительный путь к JSON с переводами внутри пакета MMTranslation.
	private let pathToJSON: String = "Sources/MMTranslation/Resources/metro_mobile_translations.json"
	/// Относительный путь к файлу enum ключей внутри пакета MMTranslation.
	private let pathToKeys: String = "Sources/MMTranslation/Models/ServicesKeys/MMTranslationKeys.swift"
	/// Имя файла TSV с новыми ключами в каталоге `rootPath`.
	private let newKeysTSVFileName: String = "new_keys.key"

	/// - Parameters:
	///   - prefix: Префикс ключей локализации.
	///   - rootPath: Каталог для сканирования исходников.
	///   - filePath: Каталог пакета MMTranslation.
	init(prefix: String, rootPath: String, filePath: String) {
		self.prefix = prefix
		self.rootPath = rootPath
		self.filePath = filePath
	}
	
	/// Полный цикл: загрузка переводов, подготовка строк, перевод, замена литералов, запись ключей и экспорт TSV новых ключей.
	func run() async throws {
		let manager = makeLocalizationManager()
		loadTranslationsJSON(into: manager)
		
		let files = swiftFilesToScan()
		let worker = StringLiteralWorker()
		
		runPrepareLocalizationPhase(manager: manager, files: files, worker: worker)
		await manager.translating()
		runApplyLocalizationPhase(manager: manager, files: files, worker: worker)
		try writeTranslationKeys(into: manager)
		try writeNewKeysTSV(from: manager)
	}
	
	/// Абсолютный URL корня пакета MMTranslation.
	private var mmPackageRootURL: URL {
		URL(fileURLWithPath: filePath)
	}
	
	/// Создаёт менеджер локализации с генератором ключей.
	private func makeLocalizationManager() -> _LocalizationManager {
		let keyGenerator = KeyGenerator(prefix: prefix)
		let jsonLoader = JsonLoader()
		return LocalizationManager(prefix: prefix, keyGenerator: keyGenerator, jsonLoader: jsonLoader)
	}
	
	/// Загружает существующие переводы из JSON в менеджер.
	private func loadTranslationsJSON(into manager: _LocalizationManager) {
		let url = mmPackageRootURL.appendingPathComponent(pathToJSON)
		manager.load(filePath: url.path(percentEncoded: true))
	}
	
	/// Собирает список `.swift` файлов под `rootPath`.
	private func swiftFilesToScan() -> [URL] {
		FileScanner().collectSwiftFiles(from: rootPath)
	}
	
	/// Читает файл как UTF-8 и разбирает в синтаксическое дерево.
	private func readSourceFileAndParse(_ file: URL) throws -> SourceFileSyntax {
		let source = try String(contentsOf: file, encoding: .utf8)
		return Parser.parse(source: source)
	}
	
	/// Фаза сбора строк для перевода (`PrepareStringLocalizer`), ошибки по файлам только в консоль.
	private func runPrepareLocalizationPhase(manager: _LocalizationManager, files: [URL], worker: StringLiteralWorker) {
		let rewriter = PrepareStringLocalizer(manager: manager, worker: worker)
		for file in files {
			do {
				let syntax = try readSourceFileAndParse(file)
				_ = rewriter.visit(syntax)
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}
	
	/// Фаза замены литералов на вызовы `MMTranslation` и запись файлов, ошибки по файлам только в консоль.
	private func runApplyLocalizationPhase(manager: _LocalizationManager, files: [URL], worker: StringLiteralWorker) {
		let rewriter = StringLocalizer(manager: manager, worker: worker)
		for file in files {
			do {
				let syntax = try readSourceFileAndParse(file)
				let result = rewriter.visit(syntax)
				try result.description.write(to: file, atomically: true, encoding: .utf8)
			} catch {
				print("Error: \(error.localizedDescription)")
			}
		}
	}
	
	/// Дописывает новые ключи в enum `MMTranslationKeys`.
	private func writeTranslationKeys(into manager: _LocalizationManager) throws {
		let keysManager: _EnumManager = EnumManager()
		let keysFile = mmPackageRootURL.appendingPathComponent(pathToKeys)
		try keysManager.insertKeys(
			into: keysFile,
			enumName: "MMTranslationKeys",
			prefix: prefix,
			keys: manager.keys
		)
	}
	
	/// URL файла `new_keys.key` в корне сканирования (`filePath`).
	private func newKeysTSVFileURL() -> URL {
		URL(fileURLWithPath: self.filePath).appendingPathComponent(newKeysTSVFileName)
	}
	
	/// Сохраняет TSV новых ключей (`newKeyValues()`), если они есть; иначе файл не создаётся.
	private func writeNewKeysTSV(from manager: _LocalizationManager) throws {
		guard let tsv = manager.newKeyValues() else { return }
		try tsv.write(to: newKeysTSVFileURL(), atomically: true, encoding: .utf8)
	}
}
