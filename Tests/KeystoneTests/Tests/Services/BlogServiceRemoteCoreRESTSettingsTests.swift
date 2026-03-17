import Testing
import WordPressAPI
@testable import WordPress
@testable import WordPressKit

struct BlogServiceRemoteCoreRESTSettingsTests {

    // MARK: - Helpers

    private func makeSiteSettings(
        title: String = "My Blog",
        description: String = "Just another WordPress site",
        timezone: String = "America/New_York",
        dateFormat: String = "F j, Y",
        timeFormat: String = "g:i a",
        startOfWeek: UInt64 = 1,
        defaultCategory: UInt64 = 1,
        defaultPostFormat: String = "standard",
        postsPerPage: UInt64 = 10
    ) -> SiteSettingsWithEditContext {
        SiteSettingsWithEditContext(
            title: title, description: description, url: "", email: "",
            timezone: timezone, dateFormat: dateFormat, timeFormat: timeFormat,
            startOfWeek: startOfWeek, language: "", useSmilies: false,
            defaultCategory: defaultCategory, defaultPostFormat: defaultPostFormat,
            postsPerPage: postsPerPage, showOnFront: "posts",
            pageOnFront: 0, pageForPosts: 0,
            defaultPingStatus: .closed,
            defaultCommentStatus: .closed,
            siteLogo: nil, siteIcon: 0
        )
    }

    // MARK: - General

    @Test func mapsTitle() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(title: "My Blog")
        )
        #expect(result.name == "My Blog")
    }

    @Test func mapsDescription() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(description: "A tagline")
        )
        #expect(result.tagline == "A tagline")
    }

    @Test func mapsTimezone() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(timezone: "America/New_York")
        )
        #expect(result.timezoneString == "America/New_York")
    }

    // MARK: - Writing

    @Test func mapsNormalPostFormat() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(defaultPostFormat: "aside")
        )
        #expect(result.defaultPostFormat == "aside")
    }

    @Test func mapsZeroStringToStandard() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(defaultPostFormat: "0")
        )
        #expect(result.defaultPostFormat == "standard")
    }

    @Test func mapsEmptyStringToStandard() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(defaultPostFormat: "")
        )
        #expect(result.defaultPostFormat == "standard")
    }

    @Test func mapsDefaultCategoryID() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(defaultCategory: 42)
        )
        #expect(result.defaultCategoryID == NSNumber(value: 42))
    }

    @Test func mapsDateFormat() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(dateFormat: "Y-m-d")
        )
        #expect(result.dateFormat == "Y-m-d")
    }

    @Test func mapsTimeFormat() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(timeFormat: "H:i")
        )
        #expect(result.timeFormat == "H:i")
    }

    @Test func mapsStartOfWeek() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(startOfWeek: 1)
        )
        #expect(result.startOfWeek == "1")
    }

    @Test func mapsPostsPerPage() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(
            makeSiteSettings(postsPerPage: 25)
        )
        #expect(result.postsPerPage == NSNumber(value: 25))
    }

}
