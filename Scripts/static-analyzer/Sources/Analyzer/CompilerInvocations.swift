public struct CompilerInvocations {

    var invocations: [String: [[String]]]

    public init(xcodebuildLogPath: String) throws {
        let xcodebuildLog = try String(contentsOfFile: xcodebuildLogPath)

        invocations = CompilerArgumentsExtractor.allCompilerInvocations(compilerLogs: xcodebuildLog)
            .reduce(into: [:]) { partialResult, arguments in
                arguments.forEach {
                    partialResult[$0, default: []].append(arguments)
                }
            }
    }

    func compilerArguments(forFileAt path: String) -> [String] {
        invocations[path]?.first ?? []
    }

}
