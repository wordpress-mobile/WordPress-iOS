import ArgumentParser
import Foundation
import IndexStoreDB
import Analyzer

@main
struct MainCommand: AsyncParsableCommand {

    @Option(help: "Path to the data store directory, which is typically located at '<derived-data>/Index.noindex/DataStore'")
    var dataStorePath: String

    @Option
    var xcodebuildLogPath: String

    func run() async throws {
        SourceKitHelper.printVersion()

        let indexStore = try IndexStoreDB.from(dataStorePath: dataStorePath)
        let invocations = try CompilerInvocations(xcodebuildLogPath: xcodebuildLogPath)

        let violations = try reportUnsafeCoreDataAPIUsages(indexStore: indexStore, compilerInvocations: invocations)

        print("Found \(violations.count) violations")
        for violation in violations {
            print(violation)
        }

        if !violations.isEmpty {
            throw ExitCode(1)
        }
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
