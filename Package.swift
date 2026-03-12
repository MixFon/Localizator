// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Localizator
import PackageDescription

let package = Package(
	name: "Localizator",
	platforms: [
		.macOS(.v26)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
	],
	targets: [
		.executableTarget(
			name: "Localizator",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		)
	]
)
