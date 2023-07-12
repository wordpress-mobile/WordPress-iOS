import XCTest
@testable import WordPress

class DiskCacheTests: XCTestCase {
    var cacheURL: URL!
    var cache: DiskCache!

    override func setUp() async throws {
        try await super.setUp()

        cacheURL = try XCTUnwrap(FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        cache = DiskCache(url: cacheURL)
    }

    override func tearDown() async throws {
        try await super.tearDown()

        try FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: Add

    func testAdd() {
        // When
        cache.setData(blob, forKey: "key")

        // Then
        XCTAssertEqual(cache.getData(forKey: "key"), blob)
    }

    func testReplace() {
        // Given
        cache.setData(blob, forKey: "key")

        // When
        cache.setData(otherBlob, forKey: "key")

        // Then
        XCTAssertEqual(cache.getData(forKey: "key"), otherBlob)
    }

    // MARK: Remove

    func testRemove() {
        // Given
        cache.setData(blob, forKey: "key")

        // When
        cache.removeData(forKey: "key")

        // Then
        XCTAssertNil(cache.getData(forKey: "key"))
    }

    func testRemoveAll() throws {
        // Given
        cache.setData(blob, forKey: "key1")
        cache.setData(blob, forKey: "key2")

        // When
        try cache.removeAll()

        // Then
        XCTAssertNil(cache.getData(forKey: "key1"))
        XCTAssertNil(cache.getData(forKey: "key2"))
    }

    // MARK: Codable

    private struct Payload: Codable {
        let value: String
    }

    func testStoreCodable() {
        // Given
        let payload = Payload(value: "test")

        // When
        cache.setValue(payload, forKey: "key")
        let cachedPayload = cache.getValue(Payload.self, forKey: "key")

        // Then
        XCTAssertEqual(cachedPayload?.value, "test")
    }

    func testRemoveCodable() {
        // Given
        let payload = Payload(value: "test")
        cache.setValue(payload, forKey: "key")

        // When
        cache.removeValue(forKey: "key")

        // Then
        XCTAssertNil(cache.getValue(Payload.self, forKey: "key"))
    }

    func testStoreCodableAsync() async {
        // Given
        let payload = Payload(value: "test")

        // When
        await cache.setValue(payload, forKey: "key")
        let cachedPayload = await cache.getValue(Payload.self, forKey: "key")

        // Then
        XCTAssertEqual(cachedPayload?.value, "test")
    }

    func testRemoveCodableAsync() async {
        // Given
        let payload = Payload(value: "test")
        await cache.setValue(payload, forKey: "key")

        // When
        await cache.removeValue(forKey: "key")

        // Then
        let value = await cache.getValue(Payload.self, forKey: "key")
        XCTAssertNil(value)
    }

    // MARK: Sweep

    func testSweep() throws {
        // GIVEN
        let mb = 1024 * 1024 // allocated size is usually about 4 KB on APFS, so use 1 MB just to be sure
        cache = DiskCache(url: cacheURL, sizeLimit: mb * 3)

        cache.setData(Data(repeating: 1, count: mb), forKey: "key1")
        cache.setData(Data(repeating: 1, count: mb), forKey: "key2")
        cache.setData(Data(repeating: 1, count: mb), forKey: "key3")
        cache.setData(Data(repeating: 1, count: mb), forKey: "key4")

        // WHEN
        try cache.sweep()

        // THEN
        XCTAssertEqual(try cache.getTotalCount(), 1)
    }

    // MARK: Resilience

    func testWhenDirectoryDeletedCacheAutomaticallyRecreatesIt() throws {
        // Given
        cache.setData(blob, forKey: "key")

        // When
        try FileManager.default.removeItem(at: cacheURL)

        cache.setData(blob, forKey: "key")

        // Then
        XCTAssertEqual(cache.getData(forKey: "key"), blob)
    }

    // MARK: Private

    private let blob = "123".data(using: .utf8)!
    private let otherBlob = "456".data(using: .utf8)!
}
