import Testing
@testable import WordPressData

@Suite("PostMetadataContainer Tests")
struct PostMetadataContainerTests {

    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // MARK: - Initialization Tests

    @Test("Initialization with mock data")
    func initializationWithMockData() throws {
        let metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)

        #expect(!metadata.values.isEmpty)
        #expect(metadata.values.count == 12)
    }

    @Test("Initialization with metadata array")
    func initializationWithMetadataArray() {
        let metadataArray = [
            ["key": "key1", "value": "value1"],
            ["key": "key2", "value": "value2"]
        ]
        let metadata = PostMetadataContainer(metadata: metadataArray)

        #expect(metadata.values.count == 2)
        #expect(metadata.getValue(String.self, forKey: "key1") == "value1")
        #expect(metadata.getValue(String.self, forKey: "key2") == "value2")
    }

    @Test("Empty initialization")
    func emptyInitialization() {
        let metadata = PostMetadataContainer()

        #expect(metadata.values.isEmpty)
        #expect(metadata.values.count == 0)
    }

    // MARK: - CRUD

    @Test("Get value from mock data")
    func getValueFromMockData() throws {
        let metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)

        #expect(metadata.getValue(String.self, forKey: .jetpackNewsletterAccess) == "subscribers")
        #expect(metadata.getValue(String.self, forKey: "wp_jp_foreign_id") == "95199E7F-EEF2-46B0-BC89-898AE817CEAD")
        #expect(metadata.getValue(String.self, forKey: "_wpas_feature_enabled") == "1")

        let nilValue: String? = metadata.getValue(String.self, forKey: "nonexistent_key")
        #expect(nilValue == nil)
    }

    @Test("Get string value from mock data")
    func getStringFromMockData() throws {
        let metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)

        #expect(metadata.getString(for: .jetpackNewsletterAccess) == "subscribers")
        #expect(metadata.getString(for: "wp_jp_foreign_id") == "95199E7F-EEF2-46B0-BC89-898AE817CEAD")
        #expect(metadata.getString(for: "_wpas_feature_enabled") == "1")
        #expect(metadata.getString(for: "nonexistent_key") == nil)
    }

    @Test("Set value")
    func setValue() {
        var metadata = PostMetadataContainer()

        metadata.setValue("test_value", for: "test_key", id: "123")

        #expect(metadata.values.count == 1)
        #expect(metadata.getValue(String.self, forKey: "test_key") == "test_value")
    }

    @Test("Set value with Key type")
    func setValueWithKeyType() {
        var metadata = PostMetadataContainer()

        metadata.setValue("test_value", for: .jetpackNewsletterAccess)

        #expect(metadata.values.count == 1)
        #expect(metadata.getValue(String.self, forKey: .jetpackNewsletterAccess) == "test_value")
    }

    @Test("Set value updates existing")
    func setValueUpdatesExisting() throws {
        var metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)
        let originalCount = metadata.values.count

        metadata.setValue("new_value", for: .jetpackNewsletterAccess)

        #expect(metadata.values.count == originalCount) // Count should remain same
        #expect(metadata.getValue(String.self, forKey: .jetpackNewsletterAccess) == "new_value")
    }

    @Test("Remove value")
    func removeValue() throws {
        var metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)
        let originalCount = metadata.values.count

        let removed = metadata.removeValue(for: .jetpackNewsletterAccess)

        #expect(removed)
        #expect(metadata.values.count == originalCount - 1)
        #expect(metadata.getValue(String.self, forKey: .jetpackNewsletterAccess) == nil)

        // Try to remove non-existent key
        let notRemoved = metadata.removeValue(for: "nonexistent_key")
        #expect(!notRemoved)
    }

    @Test("Clear all metadata")
    func clear() throws {
        var metadata = try PostMetadataContainer(data: Self.mockMetadataJSON)

        metadata.clear()

        #expect(metadata.values.isEmpty)
        #expect(metadata.values.count == 0)
    }

    // MARK: - Encoding Tests

    @Test("Encode and decode round trip")
    func encodeAndDecodeRoundTrip() throws {
        let originalMetadata = try PostMetadataContainer(data: Self.mockMetadataJSON)

        let encodedData = try #require(try originalMetadata.encode(), "Failed to encode metadata")

        let decodedMetadata = try PostMetadataContainer(data: encodedData)

        #expect(originalMetadata.values.count == decodedMetadata.values.count)

        // Verify specific values are preserved
        #expect(originalMetadata.getValue(String.self, forKey: .jetpackNewsletterAccess) ==
                decodedMetadata.getValue(String.self, forKey: .jetpackNewsletterAccess))
        #expect(originalMetadata.getValue(String.self, forKey: "wp_jp_foreign_id") ==
                decodedMetadata.getValue(String.self, forKey: "wp_jp_foreign_id"))
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Invalid JSON handling")
    func invalidJSONHandling() throws {
        let invalidJSON = "invalid json".data(using: .utf8)!

        #expect(throws: Error.self) {
            _ = try try PostMetadataContainer(data: invalidJSON)
        }
    }

    @Test("Malformed metadata item handling")
    func malformedMetadataItemHandling() throws {
        let malformedData: [[String: Any]] = [
            ["key": "valid_key", "value": "valid_value"], // Valid item
            ["value": "missing_key"], // Missing key
            ["id": "123"] // Missing both key and value
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: malformedData, options: [])
        let metadata = try PostMetadataContainer(data: jsonData)

        #expect(metadata.values.count == 1) // Only the valid item should be parsed
        #expect(metadata.getValue(String.self, forKey: "valid_key") == "valid_value")
    }

    @Test("Key type string literal")
    func keyTypeStringLiteral() {
        let key: PostMetadataContainer.Key = "custom_key"
        #expect(key.rawValue == "custom_key")
    }

    @Test("Key type raw value init")
    func keyTypeRawValueInit() {
        let key = PostMetadataContainer.Key(rawValue: "another_key")
        #expect(key.rawValue == "another_key")
    }

    @Test("Mixed key types")
    func mixedKeyTypes() {
        var metadata = PostMetadataContainer()

        // Set using Key type
        metadata.setValue("key_value", for: .jetpackNewsletterAccess)

        // Set using string (for methods that still accept strings)
        metadata.setValue("string_value", for: "string_key")

        // Both should work
        #expect(metadata.getString(for: .jetpackNewsletterAccess) == "key_value")
        #expect(metadata.getValue(String.self, forKey: "string_key") == "string_value")
    }
}
