import Testing
import Foundation
import CoreData
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("PostSettings Tests")
struct PostSettingsTests {

    // MARK: - apply(to:) Tests

    @Test("Applies basic properties to post")
    func testApplyBasicProperties() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.slug = "new-slug"
        settings.status = .publish
        settings.publishDate = Date(timeIntervalSince1970: 1000)
        settings.password = "secret"

        // When
        settings.apply(to: post)

        // Then
        #expect(post.wp_slug == "new-slug")
        #expect(post.status == .publish)
        #expect(post.dateCreated == Date(timeIntervalSince1970: 1000))
        #expect(post.password == "secret")
    }

    @Test("Applies author changes to post")
    func testApplyAuthorChanges() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.author = PostSettings.Author(
            id: 123,
            displayName: "John Doe",
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        )

        // When
        settings.apply(to: post)

        // Then
        #expect(post.authorID == NSNumber(value: 123))
        #expect(post.author == "John Doe")
        #expect(post.authorAvatarURL == "https://example.com/avatar.jpg")
    }

    @Test("Applies featured image changes to post")
    func testApplyFeaturedImageChanges() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.featuredImageID = 456

        // When
        settings.apply(to: post)

        // Then
        #expect(post.featuredImage?.mediaID == NSNumber(value: 456))
    }

    @Test("Removes featured image when ID is nil")
    func testRemoveFeaturedImage() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        let media = Media(context: context)
        media.mediaID = NSNumber(value: 789)
        post.featuredImage = media

        var settings = PostSettings(from: post)
        settings.featuredImageID = nil

        // When
        settings.apply(to: post)

        // Then
        #expect(post.featuredImage == nil)
    }

    @Test("Applies categories and tags to post")
    func testApplyCategoriesAndTags() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        // Create test categories
        let category1 = PostCategory(context: context)
        category1.categoryID = NSNumber(value: 1)
        category1.categoryName = "Tech"
        category1.blog = blog

        let category2 = PostCategory(context: context)
        category2.categoryID = NSNumber(value: 2)
        category2.categoryName = "News"
        category2.blog = blog

        blog.categories = Set([category1, category2])

        var settings = PostSettings(from: post)
        settings.categoryIDs = Set([1, 2])
        settings.tags = "swift, ios, testing"

        // When
        settings.apply(to: post)

        // Then
        #expect(post.categories?.count == 2)
        #expect(post.categories?.contains(category1) == true)
        #expect(post.categories?.contains(category2) == true)
        #expect(post.tags == "swift, ios, testing")
    }

    @Test("Only updates changed properties")
    func testOnlyUpdatesChangedProperties() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        let originalSlug = "original-slug"
        post.wp_slug = originalSlug
        post.status = .draft

        var settings = PostSettings(from: post)
        // Only change status, not slug
        settings.status = .publish

        // When
        settings.apply(to: post)

        // Then
        #expect(post.wp_slug == originalSlug) // Unchanged
        #expect(post.status == .publish) // Changed
    }

    // MARK: - makeUpdateParameters Tests

    @Test("Creates update parameters for changed properties")
    func testMakeUpdateParametersWithChanges() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        post.postTitle = "Original Title"
        post.content = "Original Content"
        post.wp_slug = "original-slug"

        var settings = PostSettings(from: post)
        settings.slug = "updated-slug"

        // When
        let parameters = settings.makeUpdateParameters(from: post)

        // Then
        #expect(parameters.slug == "updated-slug")
        #expect(parameters.title == nil) // Title wasn't changed via settings
        #expect(parameters.content == nil) // Content wasn't changed via settings
    }

    @Test("Creates empty parameters when no changes")
    func testMakeUpdateParametersWithNoChanges() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        let settings = PostSettings(from: post)

        // When
        let parameters = settings.makeUpdateParameters(from: post)

        // Then
        // Check that parameters has no significant changes
        #expect(parameters.status == nil)
        #expect(parameters.slug == nil)
        #expect(parameters.date == nil)
        #expect(parameters.authorID == nil)
    }

    // MARK: - Text Generation Tests

    @Test("Generates categories text correctly")
    func testMakeCategoriesText() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        // Create test categories
        let category1 = PostCategory(context: context)
        category1.categoryID = NSNumber(value: 1)
        category1.categoryName = "Technology"
        category1.blog = blog

        let category2 = PostCategory(context: context)
        category2.categoryID = NSNumber(value: 2)
        category2.categoryName = "Apple"
        category2.blog = blog

        blog.categories = Set([category1, category2])

        var settings = PostSettings(from: post)
        settings.categoryIDs = Set([1, 2])

        // When
        let categoryNames = settings.getCategoryNames(for: post)

        // Then
        #expect(categoryNames == ["Apple", "Technology"]) // Alphabetically sorted
    }

    @Test("Generates empty categories text for pages")
    func testMakeCategoriesTextForPage() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let page = PageBuilder(context).build()

        var settings = PostSettings(from: page)
        settings.categoryIDs = Set([1, 2])

        // When
        let categoryNames = settings.getCategoryNames(for: page)

        // Then
        #expect(categoryNames == [])
    }

    @Test("Generates tags text correctly")
    func testMakeTagsText() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.tags = "swift, ios, testing"

        // When
        let tagsText = settings.tags

        // Then
        #expect(tagsText == "swift, ios, testing")
    }

    @Test("Generates empty tags text")
    func testMakeTagsTextEmpty() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.tags = ""

        // When
        let tagsText = settings.tags

        // Then
        #expect(tagsText == "")
    }

    // MARK: - init(from:) Roundtrip Tests

    @Test("Initializes all fields from a Post")
    func testInitFromPostRoundtrip() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).is(sticked: true).build()

        post.mt_excerpt = "Test excerpt"
        post.wp_slug = "test-slug"
        post.status = .publish
        post.dateCreated = Date(timeIntervalSince1970: 5000)
        post.password = "pass123"
        post.authorID = NSNumber(value: 42)
        post.author = "Jane"
        post.postFormat = "aside"
        post.tags = "tag1, tag2"
        post.commentsStatus = "closed"
        post.pingsStatus = "closed"

        let category1 = PostCategory(context: context)
        category1.categoryID = NSNumber(value: 10)
        category1.categoryName = "Cat A"
        category1.blog = blog
        let category2 = PostCategory(context: context)
        category2.categoryID = NSNumber(value: 20)
        category2.categoryName = "Cat B"
        category2.blog = blog
        blog.categories = Set([category1, category2])
        post.categories = Set([category1, category2])

        // When
        let settings = PostSettings(from: post)

        // Then
        #expect(settings.excerpt == "Test excerpt")
        #expect(settings.slug == "test-slug")
        #expect(settings.status == .publish)
        // publishDate is non-nil because status is .publish, so shouldPublishImmediately() returns false
        #expect(settings.publishDate == Date(timeIntervalSince1970: 5000))
        #expect(settings.password == "pass123")
        #expect(settings.author?.id == 42)
        #expect(settings.author?.displayName == "Jane")
        #expect(settings.postFormat == "aside")
        #expect(settings.isStickyPost == true)
        #expect(settings.tags == "tag1, tag2")
        #expect(settings.categoryIDs == Set([10, 20]))
        #expect(settings.allowComments == false)
        #expect(settings.allowPings == false)
    }

    @Test("Initializes fields from a Page with page-specific defaults")
    func testInitFromPageRoundtrip() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let page = PageBuilder(context).build()

        page.parentID = NSNumber(value: 42)
        page.mt_excerpt = "Page excerpt"
        page.wp_slug = "page-slug"

        // When
        let settings = PostSettings(from: page)

        // Then
        #expect(settings.excerpt == "Page excerpt")
        #expect(settings.slug == "page-slug")
        #expect(settings.parentPageID == 42)
        #expect(settings.postFormat == nil)
        #expect(settings.isStickyPost == false)
        #expect(settings.tags == "")
        #expect(settings.categoryIDs == Set<Int>())
    }

    // MARK: - Individual Property apply(to:) Tests

    @Test("Applies excerpt change to post")
    func testApplyExcerpt() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.excerpt = "New excerpt"

        // When
        settings.apply(to: post)

        // Then
        #expect(post.mt_excerpt == "New excerpt")
    }

    @Test("Applies post format change to post")
    func testApplyPostFormat() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.postFormat = "aside"

        var settings = PostSettings(from: post)
        settings.postFormat = "video"

        // When
        settings.apply(to: post)

        // Then
        #expect(post.postFormat == "video")
    }

    @Test("Applies sticky post change to post")
    func testApplyStickyPost() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).is(sticked: false).build()

        var settings = PostSettings(from: post)
        settings.isStickyPost = true

        // When
        settings.apply(to: post)

        // Then
        #expect(post.isStickyPost == true)
    }

    @Test("Applies discussion settings to post")
    func testApplyDiscussionSettings() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)

        // Verify initial state
        #expect(post.allowComments == true)
        #expect(post.allowPings == true)

        // Apply closed
        settings.allowComments = false
        settings.allowPings = false
        settings.apply(to: post)
        #expect(post.allowComments == false)
        #expect(post.allowPings == false)

        // Apply open again
        settings.allowComments = true
        settings.allowPings = true
        settings.apply(to: post)
        #expect(post.allowComments == true)
        #expect(post.allowPings == true)
    }

    @Test("Applies parent page ID to page")
    func testApplyParentPageID() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let page = PageBuilder(context).build()

        var settings = PostSettings(from: page)
        settings.parentPageID = 99

        // When
        settings.apply(to: page)

        // Then
        #expect(page.parentID == NSNumber(value: 99))
    }

    @Test("Clears parent page ID when set to nil")
    func testApplyParentPageIDNil() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let page = PageBuilder(context).build()
        page.parentID = NSNumber(value: 50)

        var settings = PostSettings(from: page)
        settings.parentPageID = nil

        // When
        settings.apply(to: page)

        // Then
        #expect(page.parentID == nil)
    }

    @Test("Applies other terms to post")
    func testApplyOtherTerms() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.parsedOtherTerms = ["genre": ["fiction", "drama"]]

        var settings = PostSettings(from: post)
        settings.otherTerms = ["genre": ["scifi"]]

        // When
        settings.apply(to: post)

        // Then
        #expect(post.parsedOtherTerms == ["genre": ["scifi"]])
    }

    // MARK: - Computed Property Tests

    @Test("isPendingReview reflects status correctly")
    func testIsPendingReview() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).drafted().build()

        var settings = PostSettings(from: post)

        // Then — draft is not pending
        #expect(settings.isPendingReview == false)

        // When — set to pending
        settings.isPendingReview = true
        #expect(settings.status == .pending)

        // When — set back to not pending
        settings.isPendingReview = false
        #expect(settings.status == .draft)

        // Starting from .publish: isPendingReview = false always reverts to .draft
        settings.status = .publish
        settings.isPendingReview = true
        #expect(settings.status == .pending)
        settings.isPendingReview = false
        #expect(settings.status == .draft) // Note: always reverts to .draft, not the original status
    }

    // MARK: - setTerms / getTerms Tests

    @Test("setTerms and getTerms work for custom taxonomy")
    func testSetAndGetTerms() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)

        // When
        settings.setTerms("tag1, tag2", forTaxonomySlug: "genre")

        // Then
        #expect(settings.getTerms(forTaxonomySlug: "genre") == ["tag1", "tag2"])
        #expect(settings.getTerms(forTaxonomySlug: "nonexistent") == [])

        // Verify apply persists the terms to the post
        settings.apply(to: post)
        #expect(post.parsedOtherTerms["genre"] == ["tag1", "tag2"])
    }

    // MARK: - makeUpdateParameters Tests (Page)

    @Test("Creates update parameters for page slug change")
    func testMakeUpdateParametersForPage() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let page = PageBuilder(context).build()

        var settings = PostSettings(from: page)
        settings.slug = "new-page-slug"

        // When
        let parameters = settings.makeUpdateParameters(from: page)

        // Then
        #expect(parameters.slug == "new-page-slug")
    }
}
