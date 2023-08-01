import ArgumentParser
import Foundation
import IndexStoreDB
import System
import TSCBasic

@main
struct MainCommand: AsyncParsableCommand {

    @Option
    var derivedDataPath: String

    @Option
    var xcodebuildLogPath: String

    func run() async throws {
        guard let xcodebuildLogData = FileManager.default.contents(atPath: xcodebuildLogPath),
              let xcodebuildLog = String(data: xcodebuildLogData, encoding: .utf8)
        else {
            throw ValidationError("Can't read the xcodebuild log at \(xcodebuildLogPath)")
        }
        let indexStore = try createIndexStoreDB()
        let invocations = CompilerArgumentsExtractor.allCompilerInvocations(compilerLogs: xcodebuildLog)
            .reduce(into: [:]) { partialResult, arguments in
                arguments.forEach {
                    partialResult[$0, default: []].append(arguments)
                }
            }

        let violations = try await analyzePerformQueryReturnType(indexStore: indexStore, compilerInvocations: invocations)

        print("Found \(violations.count) violations")
        for violation in violations {
            print(violation)
        }

        if !violations.isEmpty {
            throw ExitCode(1)
        }
    }

    private func createIndexStoreDB() throws -> IndexStoreDB {
        let path = FilePath.resolveAbsolutePath(derivedDataPath)
        let storePath = path.appending("Index.noindex/DataStore")
        let databasePath = path.appending("sa-index-store.db/")

        let process = TSCBasic.Process(args: "/usr/bin/xcrun", "--find", "swift")
        try process.launch()
        let result = try process.waitUntilExit()
        let libPath = try AbsolutePath(validating: "../../lib/libIndexStore.dylib", relativeTo: AbsolutePath(validating: result.utf8Output()))
        let lib = try IndexStoreLibrary(dylibPath: libPath.pathString)

        return try IndexStoreDB(
            storePath: storePath.string,
            databasePath: databasePath.string,
            library: lib,
            waitUntilDoneInitializing: true,
            listenToUnitEvents: false
        )
    }
}

struct Violation: CustomStringConvertible {
    var message: String
    var file: URL
    var line: Int
    var column: Int

    var description: String {
        "\(message). \(file.path):\(line):\(column)"
    }
}

extension FilePath {
    static func resolveAbsolutePath(_ path: String) -> FilePath {
        if path.hasPrefix("/") {
            return FilePath(path)
        }

        return path
            .split(separator: "/")
            .reduce(into: FilePath(FileManager.default.currentDirectoryPath)) { filePath, comp in
                if let component = FilePath.Component(String(comp)) {
                    filePath.append(component)
                }
            }
            .lexicallyNormalized()
    }
}
