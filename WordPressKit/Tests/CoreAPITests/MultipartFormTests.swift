import Foundation
import XCTest
import CryptoKit
#if SWIFT_PACKAGE
@testable import CoreAPI
#else
@testable import WordPressKit
#endif

class MutliparFormDataTests: XCTestCase {
    struct Form: Codable {
        struct Field: Codable {
            var name: String
            var content: String
        }

        var fields: [Field]

        static func random(numberOfFields: Int = 10) -> Form {
            let randomText: () -> String = { String(format: "%08x", Int.random(in: Int.min...Int.max)) }
            let fields = (1...numberOfFields).map { _ in
                Field(name: randomText(), content: randomText())
            }
            return Form(fields: fields)
        }

        func formData() throws -> Data {
            try fields
                .map {
                    MultipartFormField(text: $0.content, name: $0.name)
                }
                .multipartFormDataStream(boundary: "testboundary")
                .readToEnd()
        }
    }

    func testRandomForm() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testData = tempDir.appendingPathComponent("test-form.json")
        let wpOutput = tempDir.appendingPathComponent("test-form.wp.txt")

        let form = Form(fields: [
            .init(name: "key-1", content: "a"),
            .init(name: "key-2", content: "b"),
        ])
        try JSONEncoder().encode(form).write(to: testData)

        let encoded = try form.formData()
        try encoded.write(to: wpOutput)

        add(XCTAttachment(contentsOfFile: testData))
        add(XCTAttachment(contentsOfFile: wpOutput))

        let expected = "--testboundary\r\nContent-Disposition: form-data; name=\"key-1\"\r\n\r\na\r\n--testboundary\r\nContent-Disposition: form-data; name=\"key-2\"\r\n\r\nb\r\n--testboundary--\r\n".data(using: .utf8)
        XCTAssertEqual(expected, encoded)
    }

    func testPlainText() throws {
        let fields = [
            MultipartFormField(text: "hello", name: "world"),
            MultipartFormField(text: "foo", name: "bar"),
            MultipartFormField(text: "the", name: "end"),
        ]
        let encoded = try fields.multipartFormDataStream(boundary: "wpkit.boundary.9d4adfc909a08bfa").readToEnd()
        let expected = "--wpkit.boundary.9d4adfc909a08bfa\r\nContent-Disposition: form-data; name=\"world\"\r\n\r\nhello\r\n--wpkit.boundary.9d4adfc909a08bfa\r\nContent-Disposition: form-data; name=\"bar\"\r\n\r\nfoo\r\n--wpkit.boundary.9d4adfc909a08bfa\r\nContent-Disposition: form-data; name=\"end\"\r\n\r\nthe\r\n--wpkit.boundary.9d4adfc909a08bfa--\r\n".data(using: .utf8)
        XCTAssertEqual(expected, encoded)
    }

    func testEmptyForm() throws {
        let formData = try [].multipartFormDataStream(boundary: "test").readToEnd()
        XCTAssertTrue(formData.isEmpty)
    }

    func testOneField() throws {
        let formData = try [MultipartFormField(text: "hello", name: "world")]
            .multipartFormDataStream(boundary: "wpkit.boundary.9d4adfc909a08bfa")
            .readToEnd()

        let expected = "--wpkit.boundary.9d4adfc909a08bfa\r\nContent-Disposition: form-data; name=\"world\"\r\n\r\nhello\r\n--wpkit.boundary.9d4adfc909a08bfa--\r\n".data(using: .utf8)!
        XCTAssertEqual(expected, formData)
    }

    func testUploadSmallFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileContent = Data(repeating: Character("a").asciiValue!, count: 20_000_000)
        let filePath = tempDir.appendingPathComponent("file.png")
        let resultPath = tempDir.appendingPathComponent("result.txt")
        try fileContent.write(to: filePath)
        defer {
            try? FileManager.default.removeItem(at: filePath)
            try? FileManager.default.removeItem(at: resultPath)
        }

        let fields = [
            MultipartFormField(text: "123456", name: "site"),
            try MultipartFormField(fileAtPath: filePath.path, name: "media", filename: "file.png", mimeType: "image/png"),
        ]
        let formData = try fields.multipartFormDataStream(boundary: "testboundary").readToEnd()
        try formData.write(to: resultPath)

        // Reminder: Check the multipart form file before updating this assertion
        XCTAssertTrue(SHA256.hash(data: formData).description.contains("8c985fdc03e75389b85a74996504aa10e0b054b1b5f771bd1ba0db155281bb53"))
    }

    func testUploadLargeFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileContent = Data(repeating: Character("a").asciiValue!, count: 50_000_000)
        let filePath = tempDir.appendingPathComponent("file.png")
        let resultPath = tempDir.appendingPathComponent("result.txt")
        try fileContent.write(to: filePath)
        defer {
            try? FileManager.default.removeItem(at: filePath)
            try? FileManager.default.removeItem(at: resultPath)
        }

        let fields = [
            MultipartFormField(text: "123456", name: "site"),
            try MultipartFormField(fileAtPath: filePath.path, name: "media", filename: "file.png", mimeType: "image/png"),
        ]
        let formData = try fields.multipartFormDataStream(boundary: "testboundary").readToEnd()
        try formData.write(to: resultPath)

        // Reminder: Check the multipart form file before updating this assertion
        XCTAssertTrue(SHA256.hash(data: formData).description.contains("2cedb35673a6982453a6e8e5ca901feabf92250630cdfabb961a03467f28bc8e"))
    }

}

extension Either<Data, URL> {
    func readToEnd() -> Data {
        map(
            left: { $0 },
            right: { InputStream(url: $0)?.readToEnd() ?? Data() }
        )
    }
}

extension InputStream {
    func readToEnd() -> Data {
        open()
        defer { close() }

        var data = Data()
        let maxLength = 1024
        var buffer = [UInt8](repeating: 0, count: maxLength)
        while hasBytesAvailable {
            let bytes = read(&buffer, maxLength: maxLength)
            data.append(buffer, count: bytes)
        }
        return data
    }
}
