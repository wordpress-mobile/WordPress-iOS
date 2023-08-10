import Foundation
import TSCBasic
import XCTest
import IndexStoreDB

@testable import Analyzer

final class TestSupport {

    let projectName = "SPMProject"

    let home: AbsolutePath
    let projectDir: AbsolutePath

    var targetDir: AbsolutePath {
        projectDir.appending(components: ["Sources", projectName])
    }

    var sourceFile: AbsolutePath {
        let file = try! localFileSystem.getDirectoryContents(targetDir).first { $0.hasSuffix(".swift") }
        return targetDir.appending(component: file!)
    }

    init() {
        let uuid = UUID().uuidString
        home = localFileSystem.cachesDirectory!.appending(components: ["wordpress-static-analyzer", uuid])
        projectDir = home.appending(component: projectName)
    }

    deinit {
        try? localFileSystem.removeFileTree(home)
    }

    func build(testDataFile file: String) throws -> (derivedDataPath: AbsolutePath, xcodebuildLogPath: AbsolutePath) {
        let sourceFile = try XCTUnwrap(Bundle.module.path(forResource: "TestData/\(file)", ofType: nil))
        return try build(sourceCode: String(contentsOfFile: sourceFile))
    }

    func build(sourceCode: String, verbose: Bool = false) throws -> (derivedDataPath: AbsolutePath, xcodebuildLogPath: AbsolutePath) {
        try localFileSystem.removeFileTree(projectDir)

        try localFileSystem.createDirectory(targetDir, recursive: true)

        let package = """
        // swift-tools-version: 5.8

        import PackageDescription

        let name = "\(projectName)"

        let package = Package(
            name: name,
            platforms: [.macOS(.v13)],
            products: [
                .library(name: name, targets: [name]),
            ],
            targets: [
                .target(name: name)
            ]
        )
        """
        try package.write(toFile: projectDir.appending(component: "Package.swift").pathString, atomically: true, encoding: .utf8)
        try sourceCode.write(toFile: targetDir.appending(component: "code.swift").pathString, atomically: true, encoding: .utf8)

        let derivedDataPath = projectDir.appending(component: "derived-data")
        let xcodebuildLogPath = projectDir.appending(component: "xcodebuild.log")

        let shell = "xcodebuild -scheme \(projectName) -destination platform=macOS -derivedDataPath \(derivedDataPath.pathString) build | tee \(xcodebuildLogPath.pathString)"
        let build = TSCBasic.Process(
            arguments: ["/bin/bash", "-c", shell],
            workingDirectory: projectDir,
            outputRedirection: verbose
                ? .stream(
                    stdout: { try? FileHandle.standardOutput.write(contentsOf: $0) },
                    stderr: { try? FileHandle.standardError.write(contentsOf: $0) }
                )
                : .none,
            loggingHandler: { print("[\(self.projectName)] \($0)") }
        )
        try build.launch()
        let buildResult = try build.waitUntilExit()
        guard buildResult.exitStatus == .terminated(code: 0) else {
            throw ProcessResult.Error.nonZeroExit(buildResult)
        }

        return (derivedDataPath, xcodebuildLogPath)
    }

    func navigator(forTestDataFile file: String) throws -> SourceNavigator {
        let sourceFile = try XCTUnwrap(Bundle.module.path(forResource: "TestData/\(file)", ofType: nil))
        return try navigator(forSourceCode: String(contentsOfFile: sourceFile))
    }

    func navigator(forSourceCode code: String) throws -> SourceNavigator {
        let (derivedDataPath, xcodebuildLogPath) = try build(sourceCode: code)

        let compilerInvocations = try CompilerInvocations(xcodebuildLogPath: xcodebuildLogPath.pathString)
        let indexStore = try IndexStoreDB.from(dataStorePath: derivedDataPath.appending(components: ["Index.noindex", "DataStore"]).pathString)
        return SourceNavigator(compilerInvocations: compilerInvocations, indexStore: indexStore)
    }

}
