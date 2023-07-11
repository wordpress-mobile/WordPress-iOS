import XCTest
import WordPress

class DiskCacheTests: XCTestCase {
    var cache: DiskCache!

    override func setUp() async throws {
        try await super.setUp()

        cache = DiskCache(name: UUID().uuidString)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        try FileManager.default.removeItem(at: cache.rootURL)
    }

    // MARK: Init

    func testInitWithName() {
        // Given
        let name = UUID().uuidString

        // When
        let cache = DiskCache(name: name)

        // Then
        XCTAssertEqual(cache.rootURL.lastPathComponent, name)
        XCTAssertNotNil(FileManager.default.fileExists(atPath: cache.rootURL.absoluteString))
    }

    func testInitWithURL() {
        // Given
        let name = UUID().uuidString
        let rootURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(name)

        // When
        let cache = DiskCache(url: rootURL)

        // Then
        XCTAssertEqual(cache.rootURL, rootURL)
        XCTAssertNotNil(FileManager.default.fileExists(atPath: rootURL.absoluteString))
    }

    // MARK: Default Key Encoder

    func testDefaultKeyEncoder() {
        let cache = DiskCache(name: UUID().uuidString)
        let filename = cache.fileURL(for: "http://test.com")?.lastPathComponent
        XCTAssertEqual(filename, "50334ee0b51600df6397ce93ceed4728c37fee4e")
    }

    // MARK: Add

    func testAdd() async {
        // When
        await cache.setData(blob, forKey: "key")

        // Then
        let data = await cache.getData(forKey: "key")
        XCTAssertEqual(data, blob)
    }

    func testReplace() async {
        // Given
        await cache.setData(blob, forKey: "key")

        // When
        await cache.setData(otherBlob, forKey: "key")

        // Then
        let data = await cache.getData(forKey: "key")
        XCTAssertEqual(data, otherBlob)
    }

    // MARK: Remove

    func testRemove() async {
        // Given
        await cache.setData(blob, forKey: "key")

        // When
        await cache.removeData(forKey: "key")

        // Then
        let data = await cache.getData(forKey: "key")
        XCTAssertNil(data)
    }

    func testRemoveAll() async {
        // Given
        await cache.setData(blob, forKey: "key1")
        await cache.setData(blob, forKey: "key2")

        // When
        await cache.removeAll()

        // Then
        let data = await cache.getData(forKey: "key1")
        XCTAssertNil(data)

        let otherData = await cache.getData(forKey: "key2")
        XCTAssertNil(otherData)
    }

    // MARK: Codable

    func testStoreCodable() async {
        // Given
        struct Payload: Codable {
            let value: String
        }

        let payload = Payload(value: "test")

        // When
        await cache.setValue(payload, forKey: "key")
        let cachedPayload = await cache.getValue(Payload.self, forKey: "key")

        // Then
        XCTAssertEqual(cachedPayload?.value, "test")
    }

    func testStoreCodableWithClosures() {
        // Given
        struct Payload: Codable {
            let value: String
        }

        let payload = Payload(value: "test")

        // When
        cache.setValue(payload, forKey: "key")
        let expectation = self.expectation(description: "payload")
        var cachedPayload: Payload?
        cache.getValue(Payload.self, forKey: "key") {
            expectation.fulfill()
            cachedPayload = $0
        }
        wait(for: [expectation], timeout: 1)

        // Then
        XCTAssertEqual(cachedPayload?.value, "test")
    }

    // MARK: Sweep

    func testSweep() async {
        // GIVEN
        let mb = 1024 * 1024 // allocated size is usually about 4 KB on APFS, so use 1 MB just to be sure
        cache = DiskCache(url: cache.rootURL, configuration: .init(sizeLimit: mb * 3))

        await cache.setData(Data(repeating: 1, count: mb), forKey: "key1")
        await cache.setData(Data(repeating: 1, count: mb), forKey: "key2")
        await cache.setData(Data(repeating: 1, count: mb), forKey: "key3")
        await cache.setData(Data(repeating: 1, count: mb), forKey: "key4")

        // WHEN
        await cache.sweep()

        // THEN
        let totalSize = await cache.totalSize
        XCTAssertEqual(totalSize, mb * 2)
    }

    // MARK: Inspection

    func testTotalCount() async {
        await cache.setData(blob, forKey: "key")

        let totalCount = await cache.totalCount
        XCTAssertEqual(totalCount, 1)
    }

    func testTotalSize() async {
        await cache.setData(blob, forKey: "key")

        let totalSize = await cache.totalSize
        XCTAssertTrue(totalSize > 0)
    }

    // MARK: Resilience

    func testWhenDirectoryDeletedCacheAutomaticallyRecreatesIt() async throws {
        // Given
        await cache.setData(blob, forKey: "key")

        // When
        try FileManager.default.removeItem(at: cache.rootURL)

        await cache.setData(blob, forKey: "key")

        // Then
        let data = await cache.getData(forKey: "key")
        XCTAssertEqual(data, blob)
    }
}

private let blob = "123".data(using: .utf8)!
private let otherBlob = "456".data(using: .utf8)!
