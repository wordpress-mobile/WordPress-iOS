import Foundation
import Testing
import WordPressShared

struct URLIncrementalFilenameTests {

    private let tempTestDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
        "URLIncrementalFilenameTests-\(UUID().uuidString)"
    )

    @Test func testThatIncrementalFilenameURLWorks() throws {
        try FileManager.default.createDirectory(
            at: tempTestDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        defer { try? FileManager.default.removeItem(at: tempTestDirectory) }

        let sampleData = "{\"sample\": \"yes\"}"
        let filename = "sample.json"

        let url = tempTestDirectory.appendingPathComponent(filename, isDirectory: false).incrementalFilename()
        // Check that the first file name is unchanged, in the case that there no existing files of the same name
        #expect(url.lastPathComponent == filename, "Error: initial URL filename did not match original filename")

        // Write the first sample file
        try sampleData.write(to: url, atomically: true, encoding: .utf8)
        let firstIncrement = url.incrementalFilename()
        // Check that the increment matches what is expected when there is an existing file
        #expect(
            firstIncrement.lastPathComponent == "sample-1.json",
            "Error: incremented URL filename was not incremented as expected"
        )
        try sampleData.write(to: firstIncrement, atomically: true, encoding: .utf8)
        let secondIncrement = url.incrementalFilename()
        #expect(
            secondIncrement.lastPathComponent == "sample-2.json",
            "Error: incremented URL filename was not incremented as expected"
        )
    }
}
