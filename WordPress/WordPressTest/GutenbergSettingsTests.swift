import XCTest
@testable import WordPress

class GutenbergSettingsTests: CoreDataTestCase {

    private let gutenbergContent = "<!-- wp:paragraph -->\n<p>Hello world</p>\n<!-- /wp:paragraph -->"

    var database: EphemeralKeyValueDatabase!
    var settings: GutenbergSettings!
    var blog: Blog!
    var post: Post!

    fileprivate func newTestPost(with blog: Blog) -> Post {
        let post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: mainContext) as! Post
        post.blog = blog
        return post
    }

    private func newTestBlog(isWPComAPIEnabled: Bool = true) -> Blog {
        if isWPComAPIEnabled {
            let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
            blog.account?.authToken = "auth"
            blog.dotComID = 1
            return blog
        } else {
            return ModelTestHelper.insertSelfHostedBlog(context: mainContext)
        }
    }

    var isGutenbergEnabled: Bool {
        return blog.isGutenbergEnabled
    }

    var mustUseGutenberg: Bool {
        return settings.mustUseGutenberg(for: post)
    }

    var shouldAutoenableGutenberg: Bool {
        return settings.shouldAutoenableGutenberg(for: post)
    }

    override func setUp() {
        super.setUp()
        Environment.replaceEnvironment(contextManager: contextManager)
        database = EphemeralKeyValueDatabase()
        settings = GutenbergSettings(database: database)
        blog = newTestBlog()
        post = newTestPost(with: blog)
        TestAnalyticsTracker.setup()
    }

    override func tearDown() {
        TestAnalyticsTracker.tearDown()
        super.tearDown()
    }

    func testGutenbergDisabledByDefaultAndToggleEnablesInSecondLaunch() {

        let testClosure: () -> () = { () in
            let database = EphemeralKeyValueDatabase()
            let blog = self.newTestBlog()
            // This simulates the first launch
            let settings = GutenbergSettings(database: database)
            settings.setGutenbergEnabled(false, for: blog)

            XCTAssertFalse(blog.isGutenbergEnabled)

            settings.setGutenbergEnabled(true, for: blog)

            XCTAssertTrue(blog.isGutenbergEnabled)
        }

        BuildConfiguration.localDeveloper.test(testClosure)
        BuildConfiguration.a8cBranchTest.test(testClosure)
        BuildConfiguration.a8cPrereleaseTesting.test(testClosure)
        BuildConfiguration.appStore.test(testClosure)
    }

    func testGutenbergAlwaysUsedForExistingGutenbergPosts() {
        settings.setGutenbergEnabled(false, for: blog)
        XCTAssertFalse(isGutenbergEnabled)

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertTrue(mustUseGutenberg)
    }

    func testAztecAlwaysUsedForExistingAztecPosts() {
        settings.setGutenbergEnabled(false, for: blog)
        XCTAssertFalse(isGutenbergEnabled)

        post.content = "<p>Hello world</p>"

        XCTAssertFalse(mustUseGutenberg)

        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(isGutenbergEnabled)
        XCTAssertFalse(mustUseGutenberg)
    }

    // Thests for defaults when `mobile_editor` haven't been sync from remote

    func testSelfHostedDefaultsToGutenberg() {
        blog = newTestBlog(isWPComAPIEnabled: false)
        post = newTestPost(with: blog)
        XCTAssertTrue(mustUseGutenberg)
    }

    func testWPComAccountsDefaultsToGutenberg() {
        XCTAssertTrue(mustUseGutenberg)
    }

    // MARK: - Tracks tests

    func testTracksOnBlockPostOpening() {
        settings.setGutenbergEnabled(false, for: blog, source: .onBlockPostOpening)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergDisabled)

        let property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.onBlockPostOpening.rawValue)
    }

    func testTracksOnSiteCreation() {
        settings.softSetGutenbergEnabled(false, for: blog, source: .onSiteCreation)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergDisabled)

        let property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.onSiteCreation.rawValue)
    }

    func testTracksViaSiteSettings() {
        settings.setGutenbergEnabled(false, for: blog, source: .viaSiteSettings)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergDisabled)

        let property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.viaSiteSettings.rawValue)
    }

    func testTracksEventOnlyOnceWhenEditorDoesNotChange() {
        settings.softSetGutenbergEnabled(false, for: blog, source: .onSiteCreation)
        settings.setGutenbergEnabled(false, for: blog, source: .viaSiteSettings)
        settings.setGutenbergEnabled(false, for: blog, source: .onBlockPostOpening)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergDisabled)

        let property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.onSiteCreation.rawValue)
    }

    func testTracksSwitchEventOnAndOff() {
        settings.setGutenbergEnabled(false, for: blog, source: .viaSiteSettings)
        settings.setGutenbergEnabled(true, for: blog, source: .viaSiteSettings)

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 2)

        // First event (Switch ON)
        var trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergDisabled)

        var property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.viaSiteSettings.rawValue)

        // Second event (Switch OFF)
        trackEvent = TestAnalyticsTracker.tracked.last
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergEnabled)

        property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.viaSiteSettings.rawValue)
    }

    // MARK: - Tests for Autoenabling gutenberg

    // Autoenable on new installs

    func testDoNotAutoenableWithTrailingSlashURL() {
        blog.url = "https://wordpress.com/" // From site creation flow
        settings.setGutenbergEnabled(true, for: blog)
        blog.url = "https://wordpress.com" // After refreshing with remote
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testDoNotAutoenableIfUsersSwitchesToGutenberg() {
        settings.setGutenbergEnabled(true, for: blog)

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testDoNotAutoenableIfUsersSwitchesToGutenbergAndBackToAztec() {
        settings.setGutenbergEnabled(true, for: blog)
        settings.setGutenbergEnabled(false, for: blog)
        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testAutoenableWhenSetToAztecOpeningGutenbergPost() {
        post.content = gutenbergContent
        blog.mobileEditor = .aztec

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    // Autoenable on new blogs

    func testAutoenableOnNewPostAndNewBlogs() {
        settings.softSetGutenbergEnabled(true, for: blog, source: nil)
        settings.setGutenbergEnabled(true, for: blog) // Called after sync

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    func testAutoenableOnExistingPostAndNewBlogs() {
        settings.softSetGutenbergEnabled(true, for: blog, source: nil)
        settings.setGutenbergEnabled(true, for: blog) // Called after sync

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    func testAutoenableOnNewBlogsOccoursOnlyOnce() {
        settings.softSetGutenbergEnabled(true, for: blog, source: nil)
        settings.setGutenbergEnabled(true, for: blog) // Called after sync

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)

        settings.willShowDialog(for: blog) // Called by EditorFactory

        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    // Autoenable after Migration

    func testDoNotAutoenableAfterMigrationSetToGutenberg() {
        database.set(true, forKey: GutenbergSettings.Key.appWideEnabled)
        migration()

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testDoNotAutoenableAfterMigrationSetToAztec() {
        database.set(false, forKey: GutenbergSettings.Key.appWideEnabled)
        migration()

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertFalse(shouldAutoenableGutenberg)
    }

    func testAutoenableAfterMigrationNotSet() {
        database.set(nil, forKey: GutenbergSettings.Key.appWideEnabled)
        migration()

        post.content = gutenbergContent

        XCTAssertTrue(mustUseGutenberg)
        XCTAssertTrue(shouldAutoenableGutenberg)
    }

    func migration() {
        let gutenbergEnabledFlag = database.object(forKey: GutenbergSettings.Key.appWideEnabled) as? Bool
        let isGutenbergEnabled = gutenbergEnabledFlag ?? false
        let editor: MobileEditor = isGutenbergEnabled ? .gutenberg : .aztec

        blog.mobileEditor = editor

        if gutenbergEnabledFlag != nil {
            let perSiteEnabledKey = GutenbergSettings.Key.enabledOnce(for: blog)
            database.set(true, forKey: perSiteEnabledKey)
        }
    }

    // mark - Phase 2

    func testPhase2RolloutMigration() {
        blog.mobileEditor = .aztec
        setupAccount(withId: 80)
        makeNetworkAvailable()

        settings.performGutenbergPhase2MigrationIfNeeded()

        XCTAssertTrue(database.bool(forKey: GutenbergSettings.Key.showPhase2Dialog(for: blog)))
        XCTAssertTrue(GutenbergRollout(database: database).isUserInRolloutGroup)
    }

    func testPhase2RolloutMigrationIsTracked() {
        blog.mobileEditor = .aztec
        setupAccount(withId: 80)
        makeNetworkAvailable()

        settings.performGutenbergPhase2MigrationIfNeeded()

        XCTAssertEqual(TestAnalyticsTracker.tracked.count, 1)

        let trackEvent = TestAnalyticsTracker.tracked.first
        XCTAssertEqual(trackEvent?.stat, WPAnalyticsStat.appSettingsGutenbergEnabled)

        let property = trackEvent?.properties["source"] as? String
        XCTAssertEqual(property, GutenbergSettings.TracksSwitchSource.onProgressiveRolloutPhase2.rawValue)
    }

    func setupAccount(withId userId: Int) {
        let account = ModelTestHelper.insertAccount(context: mainContext)
        account.authToken = "auth"
        account.uuid = UUID().uuidString
        account.userID = NSNumber(value: userId)
        contextManager.saveContextAndWait(mainContext)
        AccountService(coreDataStack: contextManager).setDefaultWordPressComAccount(account)
    }
}
