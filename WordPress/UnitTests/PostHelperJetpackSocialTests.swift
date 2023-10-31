import XCTest

@testable import WordPress

class PostHelperJetpackSocialTests: CoreDataTestCase {
    let connectionId = 123
    let keyringId = 456

    // MARK: - RemotePost -> Post tests

    func testMetadataWithConnectionIDKey() {
        // Given
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog)
        let metadataEntry: [String: String] = [
            "id": "10",
            "key": "_wpas_skip_publicize_123",
            "value": "1"
        ]

        // When
        let result = PostHelper.disabledPublicizeConnections(for: post, metadata: [metadataEntry])

        // Then
        // the keyring ID should be used as the key, while keeping the entry intact.
        XCTAssertEqual(result[NSNumber(value: keyringId)], metadataEntry)
    }

    func testMetadataWithKeyringIDKey() {
        // Given
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog)
        let metadataEntry: [String: String] = [
            "id": "10",
            "key": "_wpas_skip_456",
            "value": "1"
        ]

        // When
        let result = PostHelper.disabledPublicizeConnections(for: post, metadata: [metadataEntry])

        // Then
        // the keyring ID should be used as the key, while keeping the entry intact.
        XCTAssertEqual(result[NSNumber(value: keyringId)], metadataEntry)
    }

    func testMetadataWithConnectionIDKeyNotMatchingAnyPublicizeConnections() {
        // Given
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog)
        let metadataEntry: [String: String] = [
            "id": "10",
            "key": "_wpas_skip_publicize_500", // connectionId different from the one in local.
            "value": "1"
        ]

        // When
        let result = PostHelper.disabledPublicizeConnections(for: post, metadata: [metadataEntry])

        // Then
        // the connection ID should be used as key.
        XCTAssertEqual(result[NSNumber(value: 500)], metadataEntry)
    }

    func testMetadataEntriesWithNonStringValues() {
        // Given
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog)
        let metadataEntry: [String: Any] = [
            "id": "10",
            "key": "sharing_disabled",
            "value": [123]
        ]

        // When
        let result = PostHelper.disabledPublicizeConnections(for: post, metadata: [metadataEntry])

        // Then
        // invalid entries should be ignored.
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Post -> RemotePost tests

    func testDisabledConnectionsWithId() throws {
        // Given
        let connectionId2 = 234
        let keyringId2 = 567
        let presetDisabledConnections: [NSNumber: [String: String]] = [
            NSNumber(value: keyringId): ["id": "10", "value": "1"],
            NSNumber(value: keyringId2): ["id": "11", "key": "_wpas_skip_\(keyringId2)", "value": "0"]
        ]
        let connections = makeConnections(with: [(connectionId, keyringId), (connectionId2, keyringId2)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog, disabledConnections: presetDisabledConnections)

        // When
        let entries = PostHelper.publicizeMetadataEntries(for: post)

        // Then
        XCTAssertEqual(entries.count, 2)

        // keyless entries with id should default to the _wpas_skip_ format, despite having a matching connection.
        let _ = try XCTUnwrap(entries.first(where: { $0["key"] == "_wpas_skip_\(keyringId)" }))

        // entries with keys should be passed as is.
        let _ = try XCTUnwrap(entries.first(where: { $0["key"] == "_wpas_skip_\(keyringId2)" }))
    }

    // should convert to publicize format.
    func testKeylessDisabledConnectionsWithoutId() throws {
        // Given
        let connectionId2 = 234
        let keyringId2 = 567
        let presetDisabledConnections: [NSNumber: [String: String]] = [
            NSNumber(value: keyringId): ["value": "1"],
            NSNumber(value: keyringId2): ["key": "_wpas_skip_\(keyringId2)", "value": "0"]
        ]
        let connections = makeConnections(with: [(connectionId, keyringId), (connectionId2, keyringId2)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog, disabledConnections: presetDisabledConnections)

        // When
        let entries = PostHelper.publicizeMetadataEntries(for: post)

        // Then
        XCTAssertEqual(entries.count, 2)

        // local entries should be updated to the _wpas_skip_publicize format.
        let _ = try XCTUnwrap(entries.first(where: { $0["key"] == "_wpas_skip_publicize_\(connectionId)" }))

        // it's unlikely for a no-id entry to have a key, since it's assigned by the PostService when syncing.
        // but in this unlikely case, the key should be sent as is.
        let _ = try XCTUnwrap(entries.first(where: { $0["key"] == "_wpas_skip_\(keyringId2)" }))
    }

    func testDisabledConnectionsWithoutIdAndNoMatchingPublicizeConnection() {
        let nonExistentKeyringId = 3942
        let presetDisabledConnections = [NSNumber(value: nonExistentKeyringId): ["value": "1"]]
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog, disabledConnections: presetDisabledConnections)

        // When
        let entries = PostHelper.publicizeMetadataEntries(for: post)

        // Then
        XCTAssertEqual(entries.count, 1)

        // local entries with no matching PublicizeConnection should default to _wpas_skip format.
        XCTAssertEqual(entries.first?["key"], "_wpas_skip_\(nonExistentKeyringId)")
    }

    func testInvalidDisabledConnectionEntry() {
        let presetDisabledConnections = [NSNumber(value: 0): ["value": "1"]]
        let connections = makeConnections(with: [(connectionId, keyringId)])
        let blog = makeBlog(connections: connections)
        let post = makePost(for: blog, disabledConnections: presetDisabledConnections)

        // When
        let entries = PostHelper.publicizeMetadataEntries(for: post)

        // Then
        // Dictionary entries keyed by 0 should be ignored. This is a bug from previous implementation.
        XCTAssertEqual(entries.count, 0)
    }

    // MARK: - Test Helpers

    private func makeConnections(with pairs: [(connectionID: Int, keyringID: Int)]) -> Set<PublicizeConnection> {
        return Set(pairs.map {
            let connection = PublicizeConnection(context: mainContext)
            connection.connectionID = NSNumber(value: $0.connectionID)
            connection.keyringConnectionID = NSNumber(value: $0.keyringID)

            return connection
        })
    }

    private func makeBlog(connections: Set<PublicizeConnection>? = nil) -> Blog {
        var builder = BlogBuilder(mainContext)

        if let connections {
            builder = builder.with(connections: connections)
        }

        return builder.build()
    }

    private func makePost(for blog: Blog, disabledConnections: [NSNumber: [String: String]]? = nil) -> Post {
        var builder = PostBuilder(mainContext, blog: blog)

        if let disabledConnections {
            builder = builder.with(disabledConnections: disabledConnections)
        }

        return builder.build()
    }
}
