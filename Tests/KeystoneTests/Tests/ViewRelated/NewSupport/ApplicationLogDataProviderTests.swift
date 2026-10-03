import Foundation
import Support
import Testing

/// `readFiles(in:)` is a default implementation on `ApplicationLogDataProvider`. The `Support`
/// module has no test target of its own, so its tests live here.
struct ApplicationLogDataProviderTests {

    /// The minimum conformance needed to reach the default `readFiles(in:)`.
    private actor TestLogDataProvider: ApplicationLogDataProvider {
        func fetchApplicationLogs() async throws -> [ApplicationLog] { [] }
        func deleteApplicationLogs(in logs: [ApplicationLog]) async throws {}
        func deleteAllApplicationLogs() async throws {}
    }

    private func makeDirectory(containing filenames: [String]) throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: "ApplicationLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for filename in filenames {
            try Data("log contents".utf8).write(to: directory.appendingPathComponent(filename))
        }

        return directory
    }

    /// `contentsOfDirectory(atPath:)` returns bare filenames, so the old implementation asked the
    /// filesystem about `"a.log"` rather than `"<directory>/a.log"` and threw on the first entry.
    @Test func readsEveryLogInTheDirectory() async throws {
        let directory = try makeDirectory(containing: ["a.log", "b.log"])
        defer { try? FileManager.default.removeItem(at: directory) }

        let logs = try await TestLogDataProvider().readFiles(in: directory)

        #expect(Set(logs.map(\.path.lastPathComponent)) == ["a.log", "b.log"])
    }

    /// Each log has to carry the full path, not the bare name, or reading and deleting it fails.
    @Test func resolvesEachLogPathAgainstTheDirectory() async throws {
        let directory = try makeDirectory(containing: ["a.log"])
        defer { try? FileManager.default.removeItem(at: directory) }

        let log = try #require(try await TestLogDataProvider().readFiles(in: directory).first)

        // Compare paths rather than URLs: `deletingLastPathComponent()` yields a directory URL
        // with a trailing slash, which `appending(path:)` doesn't produce.
        #expect(log.path.deletingLastPathComponent().path == directory.path)
        #expect(FileManager.default.fileExists(atPath: log.path.path))
    }

    /// The resolved path has to survive a name that would need percent-encoding as a URL.
    @Test func handlesAFilenameThatNeedsPercentEncoding() async throws {
        let directory = try makeDirectory(containing: ["extensive logging 1.log"])
        defer { try? FileManager.default.removeItem(at: directory) }

        let log = try #require(try await TestLogDataProvider().readFiles(in: directory).first)

        #expect(log.path.lastPathComponent == "extensive logging 1.log")
        #expect(FileManager.default.fileExists(atPath: log.path.path))
    }

    /// A log the provider can read has to round-trip through the default `readApplicationLog`.
    @Test func readsBackTheContentsOfADiscoveredLog() async throws {
        let directory = try makeDirectory(containing: ["a.log"])
        defer { try? FileManager.default.removeItem(at: directory) }

        let provider = TestLogDataProvider()
        let log = try #require(try await provider.readFiles(in: directory).first)

        #expect(try await provider.readApplicationLog(log) == "log contents")
    }

    @Test func returnsNothingForAnEmptyDirectory() async throws {
        let directory = try makeDirectory(containing: [])
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(try await TestLogDataProvider().readFiles(in: directory).isEmpty)
    }
}
