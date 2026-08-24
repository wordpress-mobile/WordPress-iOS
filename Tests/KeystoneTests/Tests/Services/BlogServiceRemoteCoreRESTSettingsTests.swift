import Testing
import WordPressAPI
import WordPressAPIInternal
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
        postsPerPage: UInt64 = 10,
        siteIcon: UInt64 = 0
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
            defaultPingStatus: .closed,
            defaultCommentStatus: .closed,
            siteLogo: nil,
            siteIcon: siteIcon,
            additionalFields: WpAdditionalFields()
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

    // MARK: - Write mapping

    @Test func writeMapsTitleOnly() {
        let sparse = RemoteBlogSettings()
        sparse.name = "New Title"
        let params = BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse)
        #expect(params.title == "New Title")
        #expect(params.description == nil)
        #expect(params.timezone == nil)
        #expect(params.defaultCommentStatus == nil)
        #expect(params.defaultPingStatus == nil)
        #expect(params.siteIcon == nil)
    }

    @Test func writeMapsWritingFields() {
        let sparse = RemoteBlogSettings()
        sparse.tagline = "tag"
        sparse.timezoneString = "Europe/Vienna"
        sparse.dateFormat = "F j, Y"
        sparse.timeFormat = "g:i a"
        sparse.startOfWeek = "1"
        sparse.defaultCategoryID = 7
        sparse.postsPerPage = 12
        let params = BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse)
        #expect(params.description == "tag")
        #expect(params.timezone == "Europe/Vienna")
        #expect(params.dateFormat == "F j, Y")
        #expect(params.timeFormat == "g:i a")
        #expect(params.startOfWeek == 1)
        #expect(params.defaultCategory == 7)
        #expect(params.postsPerPage == 12)
    }

    @Test func writeMapsStandardPostFormatToZero() {
        let sparse = RemoteBlogSettings()
        sparse.defaultPostFormat = "standard"
        #expect(BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse).defaultPostFormat == "0")
    }

    @Test func writeMapsNonStandardPostFormatVerbatim() {
        let sparse = RemoteBlogSettings()
        sparse.defaultPostFormat = "aside"
        #expect(BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse).defaultPostFormat == "aside")
    }

    @Test func writeOmitsNonNumericStartOfWeek() {
        let sparse = RemoteBlogSettings()
        sparse.startOfWeek = "monday"
        #expect(BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse).startOfWeek == nil)
    }

    @Test func writeMapsDiscussionBooleans() {
        let sparse = RemoteBlogSettings()
        sparse.commentsAllowed = true
        sparse.pingbackInboundEnabled = false
        let params = BlogServiceRemoteCoreREST.makeUpdateParams(from: sparse)
        #expect(params.defaultCommentStatus == .open)
        #expect(params.defaultPingStatus == .closed)
    }

    @Test func writeMapsIconAndRemoval() {
        let set = RemoteBlogSettings()
        set.iconMediaID = 42
        #expect(BlogServiceRemoteCoreREST.makeUpdateParams(from: set).siteIcon == 42)

        let removal = RemoteBlogSettings()
        removal.iconMediaID = 0
        #expect(BlogServiceRemoteCoreREST.makeUpdateParams(from: removal).siteIcon == 0)
    }

    // MARK: - Icon read mapping

    @Test func readMapsSiteIcon() {
        let result = BlogServiceRemoteCoreREST.mapSiteSettings(makeSiteSettings(siteIcon: 42))
        #expect(result.iconMediaID == 42)
    }
}
