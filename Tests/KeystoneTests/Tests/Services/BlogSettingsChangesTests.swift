import Testing
import WordPressKitModels
@testable import WordPress

struct BlogSettingsChangesTests {

    @Test func emptyByDefault() {
        #expect(BlogSettingsChanges().isEmpty)
    }

    @Test func notEmptyWithOneField() {
        let changes = BlogSettingsChanges()
        changes.name = "Title"
        #expect(!changes.isEmpty)
    }

    @Test func sparseMappingCopiesOnlyDeclaredFields() {
        let changes = BlogSettingsChanges()
        changes.name = "My Blog"
        let remote = changes.toRemoteBlogSettings()
        #expect(remote.name == "My Blog")
        #expect(remote.tagline == nil)
        #expect(remote.postsPerPage == nil)
        #expect(remote.commentsAllowed == nil)
        #expect(remote.iconMediaID == nil)
    }

    @Test func mapsAllScalarFields() {
        let changes = BlogSettingsChanges()
        changes.tagline = "tag"
        changes.privacy = 1
        changes.languageID = 2
        changes.gmtOffset = NSNumber(value: -5.0)
        changes.timezoneString = "America/New_York"
        changes.defaultCategoryID = 3
        changes.defaultPostFormat = "aside"
        changes.dateFormat = "F j, Y"
        changes.timeFormat = "g:i a"
        changes.startOfWeek = "1"
        changes.postsPerPage = 10
        changes.iconMediaID = 42
        let remote = changes.toRemoteBlogSettings()
        #expect(remote.tagline == "tag")
        #expect(remote.privacy == 1)
        #expect(remote.languageID == 2)
        #expect(remote.gmtOffset == NSNumber(value: -5.0))
        #expect(remote.timezoneString == "America/New_York")
        #expect(remote.defaultCategoryID == 3)
        #expect(remote.defaultPostFormat == "aside")
        #expect(remote.dateFormat == "F j, Y")
        #expect(remote.timeFormat == "g:i a")
        #expect(remote.startOfWeek == "1")
        #expect(remote.postsPerPage == 10)
        #expect(remote.iconMediaID == 42)
    }

    @Test func mapsCommentSortOrderThroughAscendingBridge() {
        let changes = BlogSettingsChanges()
        changes.commentsSortOrderAscending = NSNumber(value: false)
        let remote = changes.toRemoteBlogSettings()
        #expect(!remote.commentsSortOrderAscending)
    }
}
