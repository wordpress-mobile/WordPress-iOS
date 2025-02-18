// swift-tools-version:6.0
import Foundation
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v10_13)],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: loadSwiftLintVersion()),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)

func loadSwiftLintVersion() -> Version {
    let swiftLintConfigURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("..")
        .appendingPathComponent(".swiftlint.yml")

    guard let yamlString = try? String(contentsOf: swiftLintConfigURL) else {
        fatalError("Failed to read SwiftLint config file at \(swiftLintConfigURL).")
    }

    guard let versionLine = yamlString.components(separatedBy: .newlines)
        .first(where: { $0.contains("swiftlint_version") }) else {
        fatalError("SwiftLint version not found in YAML file.")
    }

    // Assumes the format `swiftlint_version: <version>`
    guard let version = Version(versionLine.components(separatedBy: ":")
        .last?
        .trimmingCharacters(in: .whitespaces) ?? "") else {
        fatalError("Failed to extract SwiftLint version.")
    }

    return version
}
