import XCTest

@testable import WordPress

class Post_JetpackSocialTests: CoreDataTestCase {

    private let keyringAndConnectionIDPairs = [
        (100, 200),
        (101, 201),
        (102, 202)
    ]

    private lazy var connections: Set<PublicizeConnection> = {
        let connectionsArray = keyringAndConnectionIDPairs.map { keyringID, connectionID in
            let connection = PublicizeConnection(context: mainContext)
            connection.keyringConnectionID = NSNumber(value: keyringID)
            connection.connectionID = NSNumber(value: connectionID)
            return connection
        }
        return Set(connectionsArray)
    }()

    private lazy var blog: Blog = {
        BlogBuilder(mainContext).with(connections: connections).build()
    }()

    // MARK: - Checking for PublicizeConnection state

    func testCheckPublicizeConnectionHavingOnlyKeyringIDEntry() {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled]
        ])

        // When
        let result = post.publicizeConnectionDisabledForKeyringID(keyringID)

        // Then
        XCTAssertTrue(result)
    }

    func testCheckPublicizeConnectionHavingOnlyConnectionIDEntry() {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .disabled]
        ])

        // When
        let result = post.publicizeConnectionDisabledForKeyringID(keyringID)

        // Then
        XCTAssertTrue(result)
    }

    func testCheckPublicizeConnectionHavingDifferentKeyringAndConnectionEntries() {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .enabled],
            connectionID: [.valueKey: .disabled]
        ])
        let post2 = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled],
            connectionID: [.valueKey: .enabled]
        ])

        // When
        let result1 = post.publicizeConnectionDisabledForKeyringID(keyringID)
        let result2 = post2.publicizeConnectionDisabledForKeyringID(keyringID)

        // Then
        // if either one of the value is true, then the method should return true. See: pctCYC-XT-p2#comment-1000
        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
    }

    // MARK: - Disabling connections

    func testDisableConnectionWithoutAnyEntries() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost()

        // When
        post.disablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(entry[.valueKey], .disabled)
    }

    func testDisableConnectionWithPriorKeyringEntry() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .enabled]
        ])

        // When
        post.disablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(entry[.valueKey], .disabled)
    }

    func testDisableConnectionWithPriorKeyringAndConnectionEntries() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .enabled],
            connectionID: [.valueKey: .enabled]
        ])

        // When
        post.disablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // both entries' values should be updated.
        let keyringEntry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(keyringEntry[.valueKey], .disabled)

        let connectionEntry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(connectionEntry[.valueKey], .disabled)
    }

    func testDisableConnectionHavingOnlyConnectionIDEntry() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .enabled]
        ])

        // When
        post.disablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // if the keyring entry doesn't exist, the dictionary key should be updated to the keyringID.
        let keyringEntry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(keyringEntry[.valueKey], .disabled)

        // the connection entry should be deleted.
        XCTAssertNil(post.disabledPublicizeConnections?[connectionID])
    }

    // MARK: - Enabling connections

    // Note: unlikely case since there must be an entry in the `disabledPublicizeConnections` for the switch to be on.
    func testEnableConnectionWithoutAnyEntries() {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost()

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // Calling the enable method should do nothing.
        XCTAssertNil(post.disabledPublicizeConnections?[keyringID])
    }

    func testEnableConnectionWithLocalKeyringEntry() {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled]
        ])

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // if the entry hasn't been synced yet, the entry will be deleted since all connections are enabled by default.
        XCTAssertNil(post.disabledPublicizeConnections?[keyringID])
    }

    func testEnableConnectionWithSyncedKeyringEntry() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled, .idKey: "24"] // having an id means the entry exists on backend.
        ])

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        let keyringEntry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(keyringEntry[.valueKey], .enabled)
    }

    // both keyring entry and connection entry are synced
    func testEnableConnectionWithPriorSyncedKeyringAndConnectionEntries() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled, .idKey: "24"], // having an id means the entry exists on backend.
            connectionID: [.valueKey: .disabled, .idKey: "26"]
        ])

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // both entries should be updated.
        let keyringEntry = try XCTUnwrap(post.disabledPublicizeConnections?[keyringID])
        XCTAssertEqual(keyringEntry[.valueKey], .enabled)

        let connectionEntry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(connectionEntry[.valueKey], .enabled)
    }

    // the keyring entry is local, but the connection entry is synced.
    func testEnableConnectionWithPriorLocalKeyringAndSyncedConnectionEntries() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            keyringID: [.valueKey: .disabled],
            connectionID: [.valueKey: .disabled, .idKey: "26"]
        ])

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)

        // Then
        // the local entry should be removed.
        XCTAssertNil(post.disabledPublicizeConnections?[keyringID])

        // but the synced entry should be updated.
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(entry[.valueKey], .enabled)
    }

    func testEnableConnectionHavingOnlyConnectionEntry() throws {
        // Given
        let keyringID = NSNumber(value: 100)
        let connectionID = NSNumber(value: 200)
        let keyringID2 = NSNumber(value: 101)
        let connectionID2 = NSNumber(value: 201)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .disabled, .idKey: "26"],
            connectionID2: [.valueKey: .disabled]
        ])

        // When
        post.enablePublicizeConnectionWithKeyringID(keyringID)
        post.enablePublicizeConnectionWithKeyringID(keyringID2)

        // Then
        // there shouldn't be any entries keyed by the keyringIDs.
        XCTAssertNil(post.disabledPublicizeConnections?[keyringID])
        XCTAssertNil(post.disabledPublicizeConnections?[keyringID2])

        // the entry with connectionID should be updated.
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(entry[.valueKey], .enabled)

        // and if the entry isn't synced, it should be deleted.
        XCTAssertNil(post.disabledPublicizeConnections?[connectionID2])
    }

    // MARK: - Helpers

    private func makePost(disabledConnections: [NSNumber: [String: String]] = [:]) -> Post {
        PostBuilder(mainContext, blog: blog)
            .with(disabledConnections: disabledConnections)
            .build()
    }
}

private extension String {
    static let idKey = Post.Constants.publicizeIdKey
    static let valueKey = Post.Constants.publicizeValueKey
    static let disabled = Post.Constants.publicizeDisabledValue
    static let enabled = Post.Constants.publicizeEnabledValue
}
