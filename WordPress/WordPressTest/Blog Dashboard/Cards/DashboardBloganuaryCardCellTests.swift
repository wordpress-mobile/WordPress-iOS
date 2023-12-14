import XCTest
@testable import WordPress

final class DashboardBloganuaryCardCellTests: CoreDataTestCase {

    private static var calendar = {
        Calendar(identifier: .gregorian)
    }()
    private let blogID = 100
    private let featureFlags = FeatureFlagOverrideStore()

    override func setUp() {
        super.setUp()
        try? featureFlags.override(RemoteFeatureFlag.bloganuaryDashboardNudge, withValue: true)
    }

    override func tearDown() {
        super.tearDown()
        try? featureFlags.override(RemoteFeatureFlag.bloganuaryDashboardNudge,
                                   withValue: RemoteFeatureFlag.bloganuaryDashboardNudge.defaultValue)
    }

    // MARK: - `shouldShowCard` tests

    func testCardIsNotShownWhenFlagIsDisabled() throws {
        // Given
        let blog = makeBlog()
        makeBloggingPromptSettings()
        try mainContext.save()
        try featureFlags.override(RemoteFeatureFlag.bloganuaryDashboardNudge, withValue: false)

        // When
        let result = DashboardBloganuaryCardCell.shouldShowCard(for: blog, date: sometimeInDecember)

        // Then
        XCTAssertFalse(result)
    }

    func testCardIsNotShownWhenSiteIsNotMarkedAsBloggingSite() throws {
        // Given
        let blog = makeBlog()
        makeBloggingPromptSettings(markAsBloggingSite: false)
        try mainContext.save()

        // When
        let result = DashboardBloganuaryCardCell.shouldShowCard(for: blog, date: sometimeInDecember)

        // Then
        XCTAssertFalse(result)
    }

    func testCardIsNotShownForEligibleSitesOutsideDecember() throws {
        // Given
        let blog = makeBlog()
        makeBloggingPromptSettings()
        try mainContext.save()

        // When
        let result = DashboardBloganuaryCardCell.shouldShowCard(for: blog, date: sometimeInJanuary)

        // Then
        XCTAssertFalse(result)
    }

    func testCardIsShownWhenSiteIsEligible() throws {
        // Given
        let blog = makeBlog()
        makeBloggingPromptSettings()
        try mainContext.save()

        // When
        let result = DashboardBloganuaryCardCell.shouldShowCard(for: blog, date: sometimeInDecember)

        // Then
        XCTAssertTrue(result)
    }

    func testCardIsShownForEligibleSitesThatHavePromptsDisabled() throws {
        // Given
        let blog = makeBlog()
        makeBloggingPromptSettings(promptCardEnabled: false)
        try mainContext.save()

        // When
        let result = DashboardBloganuaryCardCell.shouldShowCard(for: blog, date: sometimeInDecember)

        // Then
        XCTAssertTrue(result)
    }
}

// MARK: - Helpers

private extension DashboardBloganuaryCardCellTests {

    var sometimeInDecember: Date {
        let date = Date()
        var components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        components.month = 12
        components.year = 2023
        components.day = 10

        return Self.calendar.date(from: components) ?? date
    }

    var sometimeInJanuary: Date {
        let date = Date()
        var components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        components.month = 1
        components.year = 2024
        components.day = 10

        return Self.calendar.date(from: components) ?? date
    }

    func prepareData() -> (Blog, BloggingPromptSettings) {
        return (makeBlog(), makeBloggingPromptSettings())
    }

    func makeBlog() -> Blog {
        let builder = BlogBuilder(mainContext)
            .withAnAccount()
            .with(dotComID: blogID)

        return builder.build()
    }

    @discardableResult
    func makeBloggingPromptSettings(markAsBloggingSite: Bool = true, promptCardEnabled: Bool = true) -> BloggingPromptSettings {
        let settings = NSEntityDescription.insertNewObject(forEntityName: "BloggingPromptSettings",
                                                           into: mainContext) as! WordPress.BloggingPromptSettings

        let reminderDays = NSEntityDescription.insertNewObject(forEntityName: "BloggingPromptSettingsReminderDays",
                                                               into: mainContext) as! WordPress.BloggingPromptSettingsReminderDays
        reminderDays.monday = false
        reminderDays.tuesday = false
        reminderDays.wednesday = false
        reminderDays.thursday = false
        reminderDays.friday = false
        reminderDays.saturday = false
        reminderDays.sunday = false

        settings.isPotentialBloggingSite = markAsBloggingSite
        settings.promptCardEnabled = promptCardEnabled
        settings.reminderDays = reminderDays
        settings.siteID = Int32(blogID)

        return settings
    }
}
