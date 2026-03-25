import XCTest

@testable import WordPress
@testable import WordPressData

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

    func testCheckPublicizeConnectionDisabled() {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .disabled]
        ])

        // When
        let result = post.publicizeConnectionDisabled(forConnectionID: connectionID)

        // Then
        XCTAssertTrue(result)
    }

    func testCheckPublicizeConnectionNotDisabled() {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .enabled]
        ])

        // When
        let result = post.publicizeConnectionDisabled(forConnectionID: connectionID)

        // Then
        XCTAssertFalse(result)
    }

    func testCheckPublicizeConnectionWithNoEntry() {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost()

        // When
        let result = post.publicizeConnectionDisabled(forConnectionID: connectionID)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Disabling connections

    func testDisableConnectionWithoutAnyEntries() throws {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost()

        // When
        post.disablePublicizeConnection(forConnectionID: connectionID)

        // Then
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(entry[.valueKey], .disabled)
    }

    func testDisableConnectionWithPriorEntry() throws {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .enabled]
        ])

        // When
        post.disablePublicizeConnection(forConnectionID: connectionID)

        // Then
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(entry[.valueKey], .disabled)
    }

    // MARK: - Enabling connections

    func testEnableConnectionWithoutAnyEntries() {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost()

        // When
        post.enablePublicizeConnection(forConnectionID: connectionID)

        // Then
        // Calling the enable method should do nothing.
        XCTAssertNil(post.disabledPublicizeConnections?[connectionID])
    }

    func testEnableConnectionWithLocalEntry() {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .disabled]
        ])

        // When
        post.enablePublicizeConnection(forConnectionID: connectionID)

        // Then
        // If the entry hasn't been synced yet, it will be removed since all connections are enabled by default.
        XCTAssertNil(post.disabledPublicizeConnections?[connectionID])
    }

    func testEnableConnectionWithSyncedEntry() throws {
        // Given
        let connectionID = NSNumber(value: 200)
        let post = makePost(disabledConnections: [
            connectionID: [.valueKey: .disabled, .idKey: "24"] // having an id means the entry exists on backend.
        ])

        // When
        post.enablePublicizeConnection(forConnectionID: connectionID)

        // Then
        let entry = try XCTUnwrap(post.disabledPublicizeConnections?[connectionID])
        XCTAssertEqual(entry[.valueKey], .enabled)
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
