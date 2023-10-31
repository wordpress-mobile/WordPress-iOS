import XCTest
@testable import WordPress

class URLIncrementalFilenameTests: XCTestCase {

    fileprivate lazy var tempTestDirectory: URL = {
        return FileManager.default.temporaryDirectory.appendingPathComponent("URLIncrementalFilenameTests-\(UUID().uuidString)")
    }()

    override func setUp() {
        super.setUp()
        do {
            try FileManager.default.createDirectory(at: tempTestDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Error on setup writing test directory: \(error.localizedDescription)")
        }
    }

    override func tearDown() {
        super.tearDown()
        removeTemporaryTestDirectoryIfNeeded()
    }

    fileprivate func removeTemporaryTestDirectoryIfNeeded() {
        let directory = tempTestDirectory
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }
        do {
            try fileManager.removeItem(at: directory)
        } catch {
            XCTFail("Error on removing test directory: \(error.localizedDescription)")
        }
    }

    func testThatIncrementalFilenameURLWorks() {

        let sampleData = "{\"sample\": \"yes\"}"
        let filename = "sample.json"

        let url = tempTestDirectory.appendingPathComponent(filename, isDirectory: false).incrementalFilename()
        // Check that the first file name is unchanged, in the case that there no existing files of the same name
        XCTAssertTrue(url.lastPathComponent == filename, "Error: initial URL filename did not match original filename")
        do {
            // Write the first sample file
            try sampleData.write(to: url, atomically: true, encoding: .utf8)
            let firstIncrement = url.incrementalFilename()
            // Check that the increment matches what is expected when there is an existing file
            XCTAssertTrue(firstIncrement.lastPathComponent == "sample-1.json", "Error: incremented URL filename was not incremented as expected")
            try sampleData.write(to: firstIncrement, atomically: true, encoding: .utf8)
            let secondIncrement = url.incrementalFilename()
            XCTAssertTrue(secondIncrement.lastPathComponent == "sample-2.json", "Error: incremented URL filename was not incremented as expected")
        } catch {
            XCTFail("Error testing sample data: \(error.localizedDescription)")
        }
    }
}
