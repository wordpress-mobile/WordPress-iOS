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

    // MARK: Atomic Site Tests

    // In some cases, atomic sites could sometimes get limited sharing from the API.
    // We'll need to ignore any sharing limit information if it's a Simple or Atomic site.
    // Refs: p9F6qB-dLk-p2#comment-56603
    func testCardOutOfSharesDoesNotDisplayForAtomicSites() throws {
        // Given, when
        let blog = createTestBlog(isAtomic: true, hasConnections: true, publicizeInfoState: .exceedingLimit)

        // Then
        XCTAssertFalse(shouldShowCard(for: blog))
    }

    func testCardNoConnectionDisplaysForAtomicSites() throws {
        // Given, when
        let blog = createTestBlog(isAtomic: true)

        // Then
        XCTAssertTrue(shouldShowCard(for: blog))
    }
}

// MARK: - Helpers

private extension DashboardJetpackSocialCardCellTests {

    func shouldShowCard(for blog: Blog) -> Bool {
        return DashboardJetpackSocialCardCell.shouldShowCard(for: blog)
    }

    enum PublicizeInfoState {
        case none
        case belowLimit
        case exceedingLimit
    }

    func createTestBlog(isPublicizeSupported: Bool = true,
                        isAtomic: Bool = false,
                        hasServices: Bool = true,
                        hasConnections: Bool = false,
                        publicizeInfoState: PublicizeInfoState = .none) -> Blog {
        var builder = BlogBuilder(mainContext)
            .withAnAccount()
            .with(dotComID: 12345)
            .with(capabilities: [.PublishPosts])
            .with(atomic: isAtomic)

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

        let blog = builder.build()

        switch publicizeInfoState {
        case .belowLimit:
            let publicizeInfo = PublicizeInfo(context: mainContext)
            publicizeInfo.shareLimit = 30
            publicizeInfo.sharesRemaining = 25
            blog.publicizeInfo = publicizeInfo
            break
        case .exceedingLimit:
            let publicizeInfo = PublicizeInfo(context: mainContext)
            publicizeInfo.shareLimit = 30
            publicizeInfo.sharesRemaining = 0
            blog.publicizeInfo = publicizeInfo
            break
        default:
            break
        }

        return blog
    }

    func createPublicizeService() -> PublicizeService {
        return PublicizeService(context: mainContext)
    }

}
