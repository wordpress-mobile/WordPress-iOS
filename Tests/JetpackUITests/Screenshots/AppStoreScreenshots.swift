import XCTest

/// Captures the raw screenshots the App Store screenshots are composed from.
///
/// Run by `bundle exec fastlane jetpack_screenshots` and `wordpress_screenshots`, which run it once
/// per device and language. See docs/app-store-screenshots.md.
///
/// The test target is Jetpack's, and it screenshots the WordPress app by launching it by its bundle
/// identifier, once the lane has installed it.
///
/// Runs against the fixtures, so every screenshot shows the same account and content. The test is
/// skipped unless the lane gives it somewhere to save the screenshots.
final class AppStoreScreenshots: JetpackUITestCase {
    override class var backend: Backend { .fixtures }

    /// The fixtures' content the test finds its way by. Names and site names aren't translated; the
    /// titles are, when the lane passes the screenshot content's translations for the language.
    private enum Fixture {
        static let readerSite = "WordPress.com News"
        static let readerPostAuthor = "Ioana Muresan"
        static let commenter = "Reyansh Pawar"
    }

    /// The draft the editor screenshot opens, by its title in the screenshot's language.
    private var draftTitle: String {
        configuration.content["editor.title"] ?? "Book Your Summer Sessions"
    }

    /// The WordPress screenshots' custom post type, by its name in the screenshot's language.
    private var staffTypeName: String {
        configuration.content["wordpress.staff.typeName"] ?? "Staff"
    }

    /// The first of the Staff posts, by its title, a name, which isn't translated.
    private let firstStaffMember = "Maya Okafor"

    /// The Reader post the screenshot opens, by its title in the screenshot's language.
    private var readerPostTitle: String {
        configuration.content["reader.title"] ?? "How to Collect Email Addresses with Gated Content on WordPress Sites"
    }

    private var configuration: Configuration!

    override func setUp() async throws {
        configuration = try Configuration(environment: ProcessInfo.processInfo.environment)
        try await super.setUp()
    }

    override var appBundleIdentifier: String? {
        configuration?.appBundleIdentifier
    }

    override var additionalLaunchArguments: [String] {
        guard let configuration else { return [] }
        var arguments = [
            "-AppleLanguages", "(\(configuration.language))",
            "-AppleLocale", configuration.locale,
            // Leaves out what doesn't belong in marketing, such as beta badges.
            "-ui-test-app-store-screenshots", "YES"
        ]
        if let overlay = configuration.fixturesOverlay {
            arguments += ["-ui-test-http-fixtures-overlay", overlay.path(percentEncoded: false)]
        }
        return arguments
    }

    // The app is launched in each of the App Store's languages, so this finds elements by their
    // identifiers or by the fixtures' content, never by the app's own text.
    //
    // On an iPad, My Site shows the site's menu in a column beside it instead of quick actions, and
    // the other tabs are in a sidebar instead of a tab bar.
    func testCaptureScreenshots() throws {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if configuration.appBundleIdentifier == Configuration.wordPressBundleIdentifier {
            try captureWordPressScreenshots(isPad: isPad)
        } else {
            try captureJetpackScreenshots(isPad: isPad)
        }
    }

    /// The Jetpack app's screenshots: Stats, the editor, the Reader and Notifications.
    private func captureJetpackScreenshots(isPad: Bool) throws {
        var mySite = try openMySite(isPad: isPad)

        // 1. Stats
        try mySite.tap(app.cells[isPad ? "Stats Row" : "quick_actions_stats"])
        let stats = try StatsScreen(app: app)
        try stats.waitFor(stats.chartCard)
        try save(1, "Stats")
        mySite = try returnToMySite(from: stats, goingBack: !isPad) ?? mySite

        // 2. Editor, with a draft that has a quote and an image.
        try mySite.tap(app.cells[isPad ? "Blog Post Row" : "quick_actions_posts"])
        let posts = app.tables["PostsTable"]
        try mySite.waitFor(posts)
        try openDraft(in: posts, from: mySite)
        _ = try EditorScreen(app: app)
        try save(2, "Editor")
        mySite = try relaunch(isPad: isPad)

        // 3. Reader. `ReaderScreen` waits for its menu to be hittable as a whole, which it isn't
        // beside the iPad's stream, or beside the iPhone Duo's side strip, so this taps the row.
        if isPad {
            try openFromSidebar("sidebar_reader", from: mySite)
        } else {
            try mySite.tap(app.buttons["tabbar_reader"])
        }
        try mySite.tap(app.collectionViews["reader_sidebar"].staticTexts[Fixture.readerSite])
        let stream = try ReaderStreamScreen(title: Fixture.readerSite, app: app)
        let backButton = app.buttons["reader-detail-back-button"]
        try openReaderPost(in: stream, backButton: backButton)
        try save(3, "Reader")

        // 4. Notifications. On an iPhone a post hides the tab bar, so go back to the stream first.
        if configuration.innerDisplayRequests != nil {
            mySite = try returnToMySite(from: stream, goingBack: false) ?? mySite
        } else {
            try stream.tap(backButton)
        }
        if isPad {
            try openFromSidebar("sidebar_notifications", from: stream)
        } else {
            try stream.tap(app.buttons["tabbar_notifications"])
        }
        let notifications = try NotificationsScreen(app: app)
        try notifications.waitFor(notifications.notifications.firstMatch)
        if isPad {
            // The iPad shows a notification beside the list, and a comment makes a better one than
            // the list of likes it opens with.
            try notifications.tap(notifications.notification(beginningWith: Fixture.commenter))
        }
        try save(4, "Notifications")
    }

    /// The WordPress app's screenshots: the editor, a custom post type, media and pages.
    ///
    /// The WordPress app leaves Stats, the Reader and Notifications to the Jetpack app, and shows a
    /// poster about it in their place, so its screenshots show what it has instead. Its My Site has
    /// no quick actions, so it opens everything from the site's menu, on an iPhone as on an iPad.
    ///
    /// The custom post type, Staff, is in the WordPress screenshots' own fixtures, which also make the
    /// site an Atomic one: the app only shows custom post types on sites it reaches with the core
    /// REST API.
    private func captureWordPressScreenshots(isPad: Bool) throws {
        var mySite = try openMySite(isPad: isPad)

        // 1. Editor, with a draft that has a quote and an image.
        try mySite.tap(app.cells["Blog Post Row"])
        let posts = app.tables["PostsTable"]
        try mySite.waitFor(posts)
        try openDraft(in: posts, from: mySite)
        _ = try EditorScreen(app: app)
        try save(1, "Editor")
        mySite = try relaunch(isPad: isPad)

        // 2. Staff, a custom post type: its rows have no identifier, so it's found by its name.
        try mySite.tap(app.cells.containing(.staticText, identifier: staffTypeName).firstMatch)
        try mySite.waitFor(app.staticTexts[firstStaffMember].firstMatch)
        try save(2, "Staff")
        mySite = try returnToMySite(from: mySite, goingBack: !isPad) ?? mySite

        // 3. Media.
        try mySite.tap(app.cells["Media Row"])
        // The library's grid is a SwiftUI view, whose items are images rather than cells.
        try mySite.waitFor(app.scrollViews.images.firstMatch)
        try save(3, "Media")
        mySite = try returnToMySite(from: mySite, goingBack: !isPad) ?? mySite

        // 4. Pages: the published ones.
        try mySite.tap(app.cells["Site Pages Row"])
        let pages = app.tables["PagesTable"]
        try mySite.waitFor(pages)
        try mySite.select(tab: pages.buttons["published"].firstMatch)
        try mySite.waitFor(pages.cells.firstMatch)
        try save(4, "Pages")
    }

    /// Opens the draft the editor screenshot shows, from the posts list.
    ///
    /// The list opens on its published posts. Switching to drafts while those are still loading can
    /// leave the drafts tab empty, without ever asking for drafts, so this waits for the published
    /// posts first, and switches tabs again if the drafts still don't come.
    private func openDraft(in posts: XCUIElement, from screen: ScreenObject) throws {
        _ = posts.cells.firstMatch.pollForExistence(timeout: 30)
        let draft = posts.staticTexts[draftTitle].firstMatch
        for _ in 0..<3 {
            try screen.select(tab: posts.buttons["drafts"].firstMatch)
            if draft.pollForExistence(timeout: 15) {
                try screen.tap(draft)
                return
            }
            try screen.select(tab: posts.buttons["published"].firstMatch)
        }
        throw ScreenObject.ElementNotReachedError(element: "\(draft)", expectation: "did not appear")
    }

    /// Returns to My Site after a screenshot.
    ///
    /// After a screenshot of an iPhone Duo's inner display, the app has been moved to a larger
    /// display and back, and screens don't all lay themselves out again for the smaller one: Stats
    /// loses its back button, for one. So on a Duo the app is relaunched, still signed in, instead.
    ///
    /// - Parameter goingBack: Whether the screen was pushed from My Site, and has to be popped.
    /// - Returns: My Site, or nil when nothing had to happen: on an iPad, where the site's menu is
    ///   always beside the screen, and the screen replaces My Site rather than covering it.
    private func returnToMySite(from screen: ScreenObject, goingBack: Bool) throws -> MySiteScreen? {
        if configuration.innerDisplayRequests != nil {
            return try relaunch(isPad: false)
        } else if goingBack {
            try goBack(from: screen)
        } else {
            return nil
        }
        return try MySiteScreen(app: app)
    }

    /// Relaunches the app, still signed in, and returns to My Site.
    ///
    /// The test leaves the editor this way rather than closing it. Closing a draft the editor
    /// considers changed asks whether to discard the changes, in a sheet whose buttons only have
    /// labels in the app's language, and the test runs in every language.
    private func relaunch(isPad: Bool) throws -> MySiteScreen {
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-test-reset-everything" }
        app.launch()
        return try openMySite(isPad: isPad)
    }

    /// Waits for My Site after a launch.
    ///
    /// An iPad can reopen on the site menu item it last showed, such as Stats, even after a reset,
    /// so this selects Home first.
    private func openMySite(isPad: Bool) throws -> MySiteScreen {
        if isPad {
            let home = app.cells["Home Row"]
            if home.pollForExistence(timeout: 60), !app.otherElements["my_site"].exists {
                home.tap()
            }
        }
        return try MySiteScreen(app: app)
    }

    /// Goes back from a pushed screen.
    ///
    /// On an iPhone Duo's outer display the navigation bar's buttons are in a strip down the side of
    /// the screen rather than in the navigation bar, so this looks for the back button anywhere.
    private func goBack(from screen: ScreenObject) throws {
        try screen.tap(app.buttons["BackButton"].firstMatch)
    }

    /// Opens the Reader post the screenshot shows.
    ///
    /// The stream reloads as its images arrive, which can move or replace the post's card just as
    /// it's tapped, so this waits for the card to be on screen, and tries again if another post
    /// opened instead.
    private func openReaderPost(in stream: ReaderStreamScreen, backButton: XCUIElement) throws {
        let card = stream.post(titled: readerPostTitle)
        let author = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", Fixture.readerPostAuthor))
            .firstMatch
        let window = app.windows.firstMatch
        for _ in 0..<3 {
            // A card that's being replaced has an infinite frame, and asking whether it's hittable,
            // or tapping it, then fails the test rather than missing. So this reads the card's frame
            // once and taps that point on the screen.
            var frame = CGRect.null
            let found = card.poll(timeout: 30) { card in
                frame = card.exists ? card.frame : .null
                return frame.minY.isFinite && !frame.isEmpty
                    && window.frame.contains(CGPoint(x: frame.midX, y: frame.midY))
            }
            guard found else {
                continue
            }
            window.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.midX - window.frame.minX, dy: frame.midY - window.frame.minY))
                .tap()
            guard backButton.pollForExistence(timeout: 10) else {
                continue
            }
            if author.pollForExistence(timeout: 10) {
                return
            }
            backButton.tap()
        }
        throw ScreenObject.ElementNotReachedError(element: "\(card)", expectation: "did not open")
    }

    /// Opens an item in the app's sidebar on an iPad, showing the sidebar first if it's hidden.
    ///
    /// The button that shows it has no identifier, only a label in the app's language, so it's found
    /// by where it is: the navigation bar button nearest the window's top leading corner, which is
    /// the top right in a right-to-left language.
    private func openFromSidebar(_ identifier: String, from screen: ScreenObject) throws {
        let item = app.descendants(matching: .any)[identifier].firstMatch
        if !item.isHittable {
            let width = app.windows.firstMatch.frame.width
            let isRightToLeft = ["ar", "he"].contains(String(configuration.language.prefix(2)))
            func distance(_ button: XCUIElement) -> CGFloat {
                (isRightToLeft ? width - button.frame.maxX : button.frame.minX) + button.frame.minY
            }
            let toggle = app.navigationBars.buttons.allElementsBoundByIndex
                .filter { $0.isHittable }
                .min { distance($0) < distance($1) }
            try XCTUnwrap(toggle, "There's no button to show the sidebar").tap()
        }
        try screen.tap(item)
    }

    /// Saves a screenshot of the whole screen as `<language>/<device>-<index>-<name>.png`.
    private func save(_ index: Int, _ name: String) throws {
        // Wait for what's still loading, then for images to finish fading in.
        _ = app.poll(timeout: 20) { !isShowingSpinner($0) }
        Thread.sleep(forTimeInterval: 2)

        // A screenshot of whatever is on screen would otherwise be saved after the app had crashed.
        guard app.state == .runningForeground else {
            throw AppNotRunningError(screenshot: "\(index)-\(name)")
        }

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(index)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)

        let directory = configuration.outputDirectory.appending(path: configuration.language)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: "\(configuration.deviceName)-\(index)-\(name).png")
        try screenshot.pngRepresentation.write(to: file)

        if let requests = configuration.innerDisplayRequests {
            try captureInnerDisplay(
                to: directory.appending(path: "\(configuration.deviceName) inner-\(index)-\(name).png"),
                requests: requests,
                name: "\(index)-\(name)"
            )
        }
    }

    /// Whether a spinner is on screen.
    ///
    /// This reads one snapshot of the app's accessibility tree. Querying spinners one by one fails
    /// the test whenever one disappears between being found and being read, and asking whether an
    /// off-screen one is hittable fails it too, rather than answering no.
    private func isShowingSpinner(_ app: XCUIElement) -> Bool {
        guard let root = try? app.snapshot() else {
            return true
        }
        let screen = root.frame
        func search(_ element: XCUIElementSnapshot) -> Bool {
            if element.elementType == .activityIndicator, !element.frame.isEmpty, screen.intersects(element.frame) {
                return true
            }
            return element.children.contains(where: search)
        }
        return search(root)
    }

    /// Has the lane screenshot the same screen on an iPhone Duo's inner display.
    ///
    /// The simulator only models the Duo's outer display. The lane shows the inner one by moving the
    /// app to a resizable display the inner one's size, which only the Mac can do, and which the test
    /// can't tap on. So the test asks for it with a file, the lane takes the screenshot and moves the
    /// app back, and then answers with another file. See `take_app_store_screenshots` in
    /// `fastlane/lanes/screenshots.rb`.
    private func captureInnerDisplay(to file: URL, requests: URL, name: String) throws {
        let request = requests.appending(path: "\(name).request")
        let done = requests.appending(path: "\(name).done")
        try? FileManager.default.removeItem(at: done)
        try Data(file.path(percentEncoded: false).utf8).write(to: request)

        let deadline = Date(timeIntervalSinceNow: 120)
        while !FileManager.default.fileExists(atPath: done.path(percentEncoded: false)) {
            guard Date() < deadline else {
                throw ScreenObject.ElementNotReachedError(
                    element: "The inner display screenshot \(name)",
                    expectation: "wasn't taken. Is the lane running?"
                )
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        // The app lays itself out for the outer display again.
        Thread.sleep(forTimeInterval: 2)
    }

    struct AppNotRunningError: Error, CustomStringConvertible {
        let screenshot: String

        var description: String {
            "The app wasn't running when screenshot \(screenshot) was due. Look for a crash report in ~/Library/Logs/DiagnosticReports."
        }
    }

    /// What the lane passes in, through `TEST_RUNNER_`-prefixed environment variables.
    struct Configuration {
        static let wordPressBundleIdentifier = "org.wordpress"

        /// The app to screenshot, or nil for the Jetpack app.
        let appBundleIdentifier: String?
        /// Where to save the screenshots, on the Mac.
        let outputDirectory: URL
        /// The App Store locale the screenshots are for, such as `de-DE`, which is also the
        /// language the app is launched in.
        let language: String
        /// The app's locale, such as `de_DE`, for its number and date formats.
        let locale: String
        let deviceName: String
        /// Where to ask the lane for a screenshot of an iPhone Duo's inner display, when it wants them.
        let innerDisplayRequests: URL?
        /// Fixtures with the content translated into `language`, which replace the English ones.
        let fixturesOverlay: URL?
        /// The translations of that content, by key, from `fastlane/appstoreres/screenshot_content`.
        let content: [String: String]

        init(environment: [String: String]) throws {
            guard let directory = environment["SCREENSHOTS_OUTPUT_DIR"], !directory.isEmpty else {
                throw XCTSkip(
                    "Captures the App Store screenshots. Run it with `bundle exec fastlane jetpack_screenshots` or `wordpress_screenshots`."
                )
            }
            outputDirectory = URL(filePath: directory)
            appBundleIdentifier = environment["SCREENSHOTS_APP"].flatMap { $0 == "com.automattic.jetpack" ? nil : $0 }
            language = environment["SCREENSHOTS_LANGUAGE"] ?? "en-US"
            locale = environment["SCREENSHOTS_LOCALE"] ?? language.replacingOccurrences(of: "-", with: "_")
            deviceName = environment["SIMULATOR_DEVICE_NAME"] ?? "Simulator"
            innerDisplayRequests = environment["SCREENSHOTS_INNER_DISPLAY_REQUESTS"].map { URL(filePath: $0) }
            fixturesOverlay = environment["SCREENSHOTS_FIXTURES_OVERLAY"].map { URL(filePath: $0) }
            content =
                try environment["SCREENSHOTS_CONTENT"]
                .map { path in
                    try JSONDecoder().decode([String: String].self, from: Data(contentsOf: URL(filePath: path)))
                } ?? [:]
        }
    }
}
