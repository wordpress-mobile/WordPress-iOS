import Testing
import WordPressAPI
import WordPressData

@testable import WordPress

@MainActor
struct BlogSettingsSiteSettingsTests {

    // MARK: - Helpers

    private func makeSettings() -> BlogSettings {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Old Name").build()
        return blog.settings!
    }

    /// - Parameters:
    ///   - commentsOpen: `true` → `.open`, `false` → `.closed`, `nil` → `nil`
    ///   - pingsOpen: `true` → `.open`, `false` → `.closed`, `nil` → `nil`
    private func makeSiteSettings(
        title: String = "Test Blog",
        description: String = "A tagline",
        timezone: String = "UTC",
        dateFormat: String = "Y-m-d",
        timeFormat: String = "H:i",
        startOfWeek: UInt64 = 0,
        defaultCategory: UInt64 = 1,
        defaultPostFormat: String = "standard",
        postsPerPage: UInt64 = 10,
        pingsOpen: Bool? = nil,
        commentsOpen: Bool? = nil
    ) -> SiteSettingsWithEditContext {
        SiteSettingsWithEditContext(
            title: title,
            description: description,
            url: "",
            email: "",
            timezone: timezone,
            dateFormat: dateFormat,
            timeFormat: timeFormat,
            startOfWeek: startOfWeek,
            language: "",
            useSmilies: false,
            defaultCategory: defaultCategory,
            defaultPostFormat: defaultPostFormat,
            postsPerPage: postsPerPage,
            showOnFront: "posts",
            pageOnFront: 0,
            pageForPosts: 0,
            defaultPingStatus: pingsOpen.map { $0 ? .open : .closed },
            defaultCommentStatus: commentsOpen.map { $0 ? .open : .closed },
            siteLogo: nil,
            siteIcon: 0
        )
    }

    // MARK: - General

    @Test func appliesTitle() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(title: "New Title"))
        #expect(settings.name == "New Title")
    }

    @Test func appliesTagline() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(description: "New Tagline"))
        #expect(settings.tagline == "New Tagline")
    }

    @Test func appliesTimezone() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(timezone: "America/Chicago"))
        #expect(settings.timezoneString == "America/Chicago")
    }

    // MARK: - Writing

    @Test func appliesPostFormat() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(defaultPostFormat: "aside"))
        #expect(settings.defaultPostFormat == "aside")
    }

    @Test func normalizesZeroPostFormatToStandard() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(defaultPostFormat: "0"))
        #expect(settings.defaultPostFormat == "standard")
    }

    @Test func normalizesEmptyPostFormatToStandard() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(defaultPostFormat: ""))
        #expect(settings.defaultPostFormat == "standard")
    }

    @Test func appliesDefaultCategory() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(defaultCategory: 42))
        #expect(settings.defaultCategoryID == NSNumber(value: 42))
    }

    @Test func appliesPostsPerPage() {
        let settings = makeSettings()
        settings.apply(makeSiteSettings(postsPerPage: 25))
        #expect(settings.postsPerPage == NSNumber(value: 25))
    }

    // MARK: - Discussion

    @Test func appliesCommentsOpen() {
        let settings = makeSettings()
        settings.commentsAllowed = false
        settings.apply(makeSiteSettings(commentsOpen: true))
        #expect(settings.commentsAllowed == true)
    }

    @Test func appliesCommentsClosed() {
        let settings = makeSettings()
        settings.commentsAllowed = true
        settings.apply(makeSiteSettings(commentsOpen: false))
        #expect(settings.commentsAllowed == false)
    }

    @Test func leavesCommentsUnchangedWhenNil() {
        let settings = makeSettings()
        settings.commentsAllowed = true
        settings.apply(makeSiteSettings(commentsOpen: nil))
        #expect(settings.commentsAllowed == true)
    }

    @Test func appliesPingsOpen() {
        let settings = makeSettings()
        settings.pingbackInboundEnabled = false
        settings.apply(makeSiteSettings(pingsOpen: true))
        #expect(settings.pingbackInboundEnabled == true)
    }

    @Test func appliesPingsClosed() {
        let settings = makeSettings()
        settings.pingbackInboundEnabled = true
        settings.apply(makeSiteSettings(pingsOpen: false))
        #expect(settings.pingbackInboundEnabled == false)
    }

    @Test func leavesPingsUnchangedWhenNil() {
        let settings = makeSettings()
        settings.pingbackInboundEnabled = true
        settings.apply(makeSiteSettings(pingsOpen: nil))
        #expect(settings.pingbackInboundEnabled == true)
    }
}
