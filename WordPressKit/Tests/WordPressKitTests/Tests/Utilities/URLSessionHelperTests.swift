import Foundation
import CryptoKit
import XCTest
import OHHTTPStubs

@testable import WordPressKit

class URLSessionHelperTests: XCTestCase {

    var session: URLSession!

    override func setUp() {
        super.setUp()
        session = .shared
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        XCTAssertEqual(session.debugNumberOfTaskData, 0)
    }

    func testConnectionError() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(error: URLError(.serverCertificateUntrusted))
        }

        let result = await session.perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), errorType: TestError.self)
        do {
            _ = try result.get()
            XCTFail("The above call should throw")
        } catch let WordPressAPIError<TestError>.connection(error) {
            XCTAssertEqual(error.code, URLError.Code.serverCertificateUntrusted)
        } catch {
            XCTFail("Unknown error: \(error)")
        }
    }

    func test200() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let result = await session.perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), errorType: TestError.self)

        // The result is a successful result. This line should not throw
        let response = try result.get()

        XCTAssertEqual(String(data: response.body, encoding: .utf8), "success")
    }

    func testUnacceptable500() async {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "Internal server error".data(using: .utf8)!, statusCode: 500, headers: nil)
        }

        let result = await session
            .perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), errorType: TestError.self)

        switch result {
        case let .failure(.unacceptableStatusCode(response, _)):
            XCTAssertEqual(response.statusCode, 500)
        default:
            XCTFail("Got an unexpected result: \(result)")
        }
    }

    func testAcceptable404() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "Not found".data(using: .utf8)!, statusCode: 404, headers: nil)
        }

        let result = await session
            .perform(
                request: .init(url: URL(string: "https://wordpress.org/hello")!),
                acceptableStatusCodes: [200...299, 400...499], errorType: TestError.self
            )

        // The result is a successful result. This line should not throw
        let response = try result.get()
        XCTAssertEqual(String(data: response.body, encoding: .utf8), "Not found")
    }

    func testParseError() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "Not found".data(using: .utf8)!, statusCode: 404, headers: nil)
        }

        let result = await session
            .perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), errorType: TestError.self)
            .mapUnacceptableStatusCodeError { response, _ in
                XCTAssertEqual(response.statusCode, 404)
                return .postNotFound
            }

        if case .failure(WordPressAPIError<TestError>.endpointError(.postNotFound)) = result {
            // DO nothing
        } else {
            XCTFail("Unexpected result: \(result)")
        }
    }

    func testParseSuccessAsJSON() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(jsonObject: ["title": "Hello Post"], statusCode: 200, headers: nil)
        }

        struct Post: Decodable {
            var title: String
        }

        let result: WordPressAPIResult<Post, TestError> = await session
            .perform(request: .init(url: URL(string: "https://wordpress.org/hello")!))
            .decodeSuccess()

        try XCTAssertEqual(result.get().title, "Hello Post")
    }

    func testProgressTracking() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let progress = Progress.discreteProgress(totalUnitCount: 20)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertEqual(progress.fractionCompleted, 0)

        let _ = await session.perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), fulfilling: progress, errorType: TestError.self)
        XCTAssertEqual(progress.completedUnitCount, 20)
        XCTAssertEqual(progress.fractionCompleted, 1)
    }

    func testProgressUpdateOnMainThread() async throws {
        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let progressReported = expectation(description: "Progress has been updated")
        progressReported.assertForOverFulfill = false
        let progress = Progress.discreteProgress(totalUnitCount: 20)
        let observer = progress.observe(\.fractionCompleted, options: .new) { _, _ in
            XCTAssertTrue(Thread.isMainThread)
            progressReported.fulfill()
        }

        let _ = await session.perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), fulfilling: progress, errorType: TestError.self)
        await fulfillment(of: [progressReported], timeout: 0.3)
        observer.invalidate()
    }

    func testCancellation() async throws {
        // Give a slow HTTP request that takes 0.5 second to complete
        stub(condition: isPath("/hello")) { _ in
            let response = HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
            response.responseTime = 0.5
            return response
        }

        // and cancelling it (in 0.1 second) before it completes
        let progress = Progress.discreteProgress(totalUnitCount: 20)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            progress.cancel()
        }

        // The result should be an cancellation result
        let result = await session.perform(request: .init(url: URL(string: "https://wordpress.org/hello")!), fulfilling: progress, errorType: TestError.self)
        if case let .failure(.connection(urlError)) = result, urlError.code == .cancelled {
            // Do nothing
        } else {
            XCTFail("Unexpected result: \(result)")
        }
    }

    func testEncodingError() async {
        let underlyingError = NSError(domain: "test", code: 123)
        let builder = HTTPRequestBuilder(url: URL(string: "https://wordpress.org")!)
            .method(.post)
            .body(json: { throw underlyingError })
        let result = await session.perform(request: builder, errorType: TestError.self)

        if case let .failure(.requestEncodingFailure(underlyingError: error)) = result {
            XCTAssertEqual(error as NSError, underlyingError)
        } else {
            XCTFail("Unexpected result: \(result)")
        }
    }

    func testParsingError() async {
        struct Model: Decodable {
            var success: Bool
        }

        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let result: WordPressAPIResult<Model, TestError> = await session
            .perform(request: .init(url: URL(string: "https://wordpress.org/hello")!))
            .decodeSuccess()

        if case let .failure(.unparsableResponse(_, _, error)) = result {
            XCTAssertTrue(error is DecodingError)
        } else {
            XCTFail("Unexpected result: \(result)")
        }
    }

    func testMultipartForm() async throws {
        var req: URLRequest?
        stub(condition: isPath("/hello")) {
            req = $0
            return HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let builder = HTTPRequestBuilder(url: URL(string: "https://wordpress.org/hello")!)
            .method(.post)
            .body(form: [MultipartFormField(text: "value", name: "name", filename: nil)])

        let _ = await session.perform(request: builder, errorType: TestError.self)

        let request = try XCTUnwrap(req)
        let boundary = try XCTUnwrap(
            request
                .value(forHTTPHeaderField: "Content-Type")?.split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .reduce(into: [String: String]()) {
                    let pair = $1.split(separator: "=")
                    if pair.count == 2 {
                        $0[String(pair[0])] = String(pair[1])
                    }
                }["boundary"]
            )

        let requestBody = try XCTUnwrap(request.httpBody ?? request.httpBodyStream?.readToEnd())

        let expectedBody = "--\(boundary)\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nvalue\r\n--\(boundary)--\r\n"
        XCTAssertEqual(String(data: requestBody, encoding: .utf8), expectedBody)
    }

    func testGetLargeData() async throws {
        let file = try self.createLargeFile(megaBytes: 100)
        defer {
            try? FileManager.default.removeItem(at: file)
        }

        stub(condition: isPath("/hello")) { _ in
            HTTPStubsResponse(fileURL: file, statusCode: 200, headers: nil)
        }

        let builder = HTTPRequestBuilder(url: URL(string: "https://wordpress.org/hello")!)
        let response = try await session.perform(request: builder, errorType: TestError.self).get()

        try XCTAssertEqual(
            sha256(XCTUnwrap(InputStream(url: file))),
            sha256(InputStream(data: response.body))
        )
    }

    func testTempFileRemovedAfterMultipartUpload() async throws {
        stub(condition: isPath("/upload")) { _ in
            HTTPStubsResponse(data: "success".data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        // Create a large file which will be uploaded. The file size needs to be larger than the hardcoded threshold of
        // creating a temporary file for upload.
        let file = try self.createLargeFile(megaBytes: 30)
        defer {
            try? FileManager.default.removeItem(at: file)
        }

        // Capture a list of files in temp dirs, before calling the upload function.
        let tempFilesBeforeUpload = try existingMultipartFormTempFiles()

        // Perform upload HTTP request
        let builder = try HTTPRequestBuilder(url: URL(string: "https://wordpress.org/upload")!)
            .method(.post)
            .body(form: [MultipartFormField(fileAtPath: file.path, name: "file", filename: "file.txt", mimeType: "text/plain")])
        let _ = await session.perform(request: builder, errorType: TestError.self)

        // Capture a list of files in the temp dirs, after calling the upload function.
        let tempFilesAfterUpload = try existingMultipartFormTempFiles()

        // There should be no new files after the HTTP request returns. This assertion relies on an implementation detail
        // where the multipart form content is put into a file in temp dirs.
        let newFiles = tempFilesAfterUpload.subtracting(tempFilesBeforeUpload)
        XCTAssertEqual(newFiles.count, 0)
    }

    func testTempFileRemovedAfterMultipartUploadError() async throws {
        stub(condition: isPath("/upload")) { _ in
            HTTPStubsResponse(error: URLError(.networkConnectionLost))
        }

        // Create a large file which will be uploaded. The file size needs to be larger than the hardcoded threshold of
        // creating a temporary file for upload.
        let file = try self.createLargeFile(megaBytes: 30)
        defer {
            try? FileManager.default.removeItem(at: file)
        }

        // Capture a list of files in temp dirs, before calling the upload function.
        let tempFilesBeforeUpload = try existingMultipartFormTempFiles()

        // Perform upload HTTP request
        let builder = try HTTPRequestBuilder(url: URL(string: "https://wordpress.org/upload")!)
            .method(.post)
            .body(form: [MultipartFormField(fileAtPath: file.path, name: "file", filename: "file.txt", mimeType: "text/plain")])
        let _ = await session.perform(request: builder, errorType: TestError.self)

        // Capture a list of files in the temp dirs, after calling the upload function.
        let tempFilesAfterUpload = try existingMultipartFormTempFiles()

        // There should be no new files after the HTTP request returns. This assertion relies on an implementation detail
        // where the multipart form content is put into a file in temp dirs.
        let newFiles = tempFilesAfterUpload.subtracting(tempFilesBeforeUpload)
        XCTAssertEqual(newFiles.count, 0)
    }

    // This functions finds temp files that are used for uploading multipart form.
    // The implementation relies on an internal implementation detail of building multipart form content.
    private func existingMultipartFormTempFiles() throws -> Set<String> {
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(atPath: fm.temporaryDirectory.path)
            .filter { UUID(uuidString: $0) != nil }
        return Set(files)
    }

    private func createLargeFile(megaBytes: Int) throws -> URL {
        let file = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("large-file-\(UUID().uuidString).txt")

        try Data(repeating: 46, count: 1024 * 1000 * megaBytes).write(to: file)

        return file
    }

    private func sha256(_ stream: InputStream) -> SHA256Digest {
        stream.open()
        defer { stream.close() }

        var hash = SHA256()
        let maxLength = 50 * 1024
        var buffer = [UInt8](repeating: 0, count: maxLength)
        while stream.hasBytesAvailable {
            let bytes = stream.read(&buffer, maxLength: maxLength)
            let data = Data(bytesNoCopy: &buffer, count: bytes, deallocator: .none)
            hash.update(data: data)
        }
        return hash.finalize()
    }
}

class BackgroundURLSessionHelperTests: URLSessionHelperTests {

    // swiftlint:disable weak_delegate
    private var delegate: TestBackgroundURLSessionDelegate!
    // swiftlint:enable weak_delegate

    override func setUp() {
        super.setUp()

        delegate = TestBackgroundURLSessionDelegate()
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    override func tearDown() {
        super.tearDown()

        if delegate.startedReceivingResponse {
            XCTAssertTrue(delegate.completionCalled)
        }
    }

}

private class TestBackgroundURLSessionDelegate: BackgroundURLSessionDelegate {
    var startedReceivingResponse = false
    var completionCalled = false

    override func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        startedReceivingResponse = true
        super.urlSession(session, dataTask: dataTask, didReceive: data)
    }

    override func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completionCalled = true
        super.urlSession(session, task: task, didCompleteWithError: error)
    }
}

private enum TestError: LocalizedError, Equatable {
    case postNotFound
    case serverFailure
}
