import XCTest
@testable import WordPress

class DashboardJetpackSocialCardCellTests: CoreDataTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        super.setUp()

        try? featureFlags.override(RemoteFeatureFlag.jetpackSocialImprovements, withValue: true)
    }

    override func tearDown() {
        super.tearDown()

        try? featureFlags.override(RemoteFeatureFlag.jetpackSocialImprovements,
                                   withValue: RemoteFeatureFlag.jetpackSocialImprovements.defaultValue)
    }

    // MARK: - `shouldShowCard` tests

    func testCardDisplays() {
        // Given, when
        let blog = createTestBlog()

        // Then
        XCTAssertTrue(shouldShowCard(for: blog))
    }

    func testCardDoesNotDisplayWhenFeatureDisabled() throws {
        // Given, when
        let blog = createTestBlog()

        // When
        try featureFlags.override(RemoteFeatureFlag.jetpackSocialImprovements, withValue: false)

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    func testCardNotDisplayWhenPublicizeNotSupported() {
        // Given, when
        let blog = createTestBlog(isPublicizeSupported: false)

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    func testCardNotDisplayWhenPublicizeServicesDoesNotExist() throws {
        // Given, when
        let blog = createTestBlog(hasServices: false)

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    func testCardDoesNotDisplayWithPublicizeConnections() throws {
        // Given, when
        let blog = createTestBlog(hasConnections: true)

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    func testCardDoesNotDisplayWhenViewHidden() throws {
        // Given
        let blog = createTestBlog()
        let dotComID = try XCTUnwrap(blog.dotComID)
        let repository = UserPersistentStoreFactory.instance()
        let key = DashboardJetpackSocialCardCell.Constants.hideNoConnectionViewKey

        // When
        repository.set([dotComID.stringValue: true], forKey: key)
        addTeardownBlock {
            repository.removeObject(forKey: key)
        }

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    // MARK: - Card state tests

    func testInitialCardState() {
        // Given, when
        let subject = DashboardJetpackSocialCardCell()

        // Then
        XCTAssertEqual(subject.displayState, .none)
    }

    func testCardStateWithNoConnections() {
        // Given
        let subject = DashboardJetpackSocialCardCell()
        let blog = createTestBlog()

        // When
        subject.configure(blog: blog, viewController: nil, apiResponse: nil)

        // Then
        XCTAssertEqual(subject.displayState, .noConnections)
    }

    func testCardStateWhenUpdatedWithUnsupportedBlog() {
        // Given
        let subject = DashboardJetpackSocialCardCell()
        let initialBlog = createTestBlog()
        let blog = createTestBlog(isPublicizeSupported: false, hasServices: false, hasConnections: true)
        subject.configure(blog: initialBlog, viewController: nil, apiResponse: nil)

        // When
        subject.configure(blog: blog, viewController: nil, apiResponse: nil)

        // Then
        XCTAssertEqual(subject.displayState, .none)
    }
}

// MARK: - Helpers

private extension DashboardJetpackSocialCardCellTests {

    func shouldShowCard(for blog: Blog) -> Bool {
        return DashboardJetpackSocialCardCell.shouldShowCard(for: blog)
    }

    func createTestBlog(isPublicizeSupported: Bool = true,
                        hasServices: Bool = true,
                        hasConnections: Bool = false) -> Blog {
        var builder = BlogBuilder(mainContext)
            .withAnAccount()
            .with(dotComID: 12345)
            .with(capabilities: [.PublishPosts])

        if isPublicizeSupported {
            builder = builder.with(modules: ["publicize"])
        }

        if hasServices {
            _ = createPublicizeService()
        }

        if hasConnections {
            let connection = PublicizeConnection(context: mainContext)
            builder = builder.with(connections: [connection])
        }
        return builder.build()
    }

    func createPublicizeService() -> PublicizeService {
        return PublicizeService(context: mainContext)
    }

}
