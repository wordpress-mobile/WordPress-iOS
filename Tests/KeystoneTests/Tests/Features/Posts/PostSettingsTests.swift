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
}
