import Testing
import Foundation
import CoreData
import JetpackSocial
import SwiftUI
import WordPressAPIInternal
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
        settings.tags = ["swift", "ios", "testing"].map { PostSettings.Term(id: 0, name: $0) }

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

    @Test("apply preserves stored publicize metadata when social draft is unavailable")
    func applyPreservesStoredPublicizeMetadataWhenSocialDraftIsUnavailable() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.rawMetadata = try PostMetadataContainer(metadata: [
            ["key": "_wpas_mess", "value": "Hello", "id": "1"],
            ["key": "_wpas_skip_publicize_111", "value": "1", "id": "2"],
            ["key": "_jetpack_newsletter_access", "value": "everybody", "id": "3"]
        ])
        .encode()

        var settings = PostSettings(from: post)
        settings.socialSharingDraft = nil

        settings.apply(to: post)

        // With no draft to apply, the existing publicize metadata is left untouched
        // (the user's per-connection choices are preserved, not neutralized).
        let container = PostMetadataContainer(post)
        #expect(container.getString(for: "_wpas_mess") == "Hello")
        #expect(container.getString(for: "_wpas_skip_publicize_111") == "1")
        #expect(container.entry(forKey: "_wpas_skip_publicize_111")?["id"] as? String == "2")
        #expect(container.getString(for: "_jetpack_newsletter_access") == "everybody")
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
        settings.tags = ["swift", "ios", "testing"].map { PostSettings.Term(id: 0, name: $0) }

        // When
        let tagNames = settings.tags.map(\.name)

        // Then
        #expect(tagNames == ["swift", "ios", "testing"])
    }

    @Test("Generates empty tags text")
    func testMakeTagsTextEmpty() throws {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.tags = []

        // When
        let tagNames = settings.tags.map(\.name)

        // Then
        #expect(tagNames == [])
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
        #expect(settings.tags == [PostSettings.Term(id: 0, name: "tag1"), PostSettings.Term(id: 0, name: "tag2")])
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
        #expect(settings.tags == [])
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
        settings.otherTerms = ["genre": [PostSettings.Term(id: 0, name: "scifi")]]

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
        #expect(
            settings.getTerms(forTaxonomySlug: "genre") == [
                PostSettings.Term(id: 0, name: "tag1"), PostSettings.Term(id: 0, name: "tag2")
            ]
        )
        #expect(settings.getTerms(forTaxonomySlug: "nonexistent") == [])

        // Verify apply persists the terms to the post
        settings.apply(to: post)
        #expect(post.parsedOtherTerms["genre"] == ["tag1", "tag2"])
    }

    @Test("Round-trip: init(from:) preserves tags through apply(to:)")
    func testTagsRoundTrip() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let sourcePost = PostBuilder(context, blog: blog).build()
        sourcePost.tags = "swift, ios, testing"

        // When
        let settings = PostSettings(from: sourcePost)

        // Then — init captures the tags
        #expect(settings.tags == ["swift", "ios", "testing"].map { PostSettings.Term(id: 0, name: $0) })

        // When — apply to a different post
        let targetPost = PostBuilder(context, blog: blog).build()
        settings.apply(to: targetPost)

        // Then — tags are written back unchanged
        #expect(targetPost.tags == "swift, ios, testing")
    }

    @Test("Round-trip: init(from:) preserves custom terms through apply(to:)")
    func testCustomTermsRoundTrip() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let sourcePost = PostBuilder(context, blog: blog).build()
        sourcePost.parsedOtherTerms = ["genre": ["fiction", "drama"]]

        // When
        let settings = PostSettings(from: sourcePost)

        // Then — init captures the custom terms
        #expect(
            settings.otherTerms == [
                "genre": [PostSettings.Term(id: 0, name: "fiction"), PostSettings.Term(id: 0, name: "drama")]
            ]
        )

        // When — apply to a different post
        let targetPost = PostBuilder(context, blog: blog).build()
        settings.apply(to: targetPost)

        // Then — custom terms are written back unchanged
        #expect(targetPost.parsedOtherTerms == ["genre": ["fiction", "drama"]])
    }

    @Test(
        "makeTags parses comma-separated tag strings",
        arguments: [
            ("swift, ios, testing", ["swift", "ios", "testing"]),
            ("", []),
            ("  swift , , ios  ", ["swift", "ios"])
        ] as [(String, [String])]
    )
    func testMakeTags(input: String, expected: [String]) {
        #expect(AbstractPost.makeTags(from: input) == expected)
    }

    @Test("makeUpdateParameters reflects tag changes")
    func testMakeUpdateParametersIncludesTagChanges() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.tags = "old"

        var settings = PostSettings(from: post)
        settings.tags = ["new", "tags"].map { PostSettings.Term(id: 0, name: $0) }

        // When
        let parameters = settings.makeUpdateParameters(from: post)

        // Then — tags is a [String]? containing the new tag names
        #expect(parameters.tags == ["new", "tags"])
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

    // MARK: - Term Struct Tests

    @Test("init(from: Post) creates terms with id=0")
    func testInitFromPostCreatesTermsWithZeroId() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.tags = "swift, ios"

        // When
        let settings = PostSettings(from: post)

        // Then
        #expect(
            settings.tags == [
                PostSettings.Term(id: 0, name: "swift"),
                PostSettings.Term(id: 0, name: "ios")
            ]
        )
    }

    @Test("init(from: Post) creates other terms with id=0")
    func testInitFromPostCreatesOtherTermsWithZeroId() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.parsedOtherTerms = ["genre": ["fiction", "drama"]]

        // When
        let settings = PostSettings(from: post)

        // Then
        #expect(
            settings.otherTerms["genre"] == [
                PostSettings.Term(id: 0, name: "fiction"),
                PostSettings.Term(id: 0, name: "drama")
            ]
        )
    }

    @Test("init(from: AnyPostWithEditContext) stores tag IDs with empty names")
    func testInitFromRemotePostStoresTagIds() {
        // Given
        let post = makeRemotePost(tags: [TermId(5), TermId(8)])

        // When
        let settings = PostSettings(from: post)

        // Then
        #expect(
            settings.tags == [
                PostSettings.Term(id: 5, name: ""),
                PostSettings.Term(id: 8, name: "")
            ]
        )
    }

    @Test("init(from: AnyPostWithEditContext) preserves social sharing draft")
    func testInitFromRemotePostPreservesSocialSharingDraft() {
        let expectedDraft = PostSocialSharingDraft(
            customMessage: "Stored message",
            connectionsByID: [
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false)
            ]
        )
        let post = makeRemotePost(
            meta: PostMeta().addingPublicizeMessage("Stored message"),
            additionalFields: WpAdditionalFields()
                .addingPublicizeConnections(expectedDraft.connectionsByID ?? [:])
        )

        let settings = PostSettings(from: post)

        #expect(settings.socialSharingDraft == expectedDraft)
    }

    @Test("init(from: AnyPostWithEditContext) populates jetpack newsletter access from meta")
    func initFromRestPopulatesAccessLevel() throws {
        let meta = PostMeta().addingJetpackNewsletterAccess(.paidSubscribers)
        let post = makeRemotePost(meta: meta)
        let settings = PostSettings(from: post)
        #expect(settings.metadata.accessLevel == .paidSubscribers)
    }

    @Test("init(from: AnyPostWithEditContext) populates email-disabled flag from meta")
    func initFromRestPopulatesEmailDisabled() throws {
        let meta = PostMeta().addingJetpackNewsletterEmailDisabled(true)
        let post = makeRemotePost(meta: meta)
        let settings = PostSettings(from: post)
        #expect(settings.metadata.isJetpackNewsletterEmailDisabled)
    }

    @Test("init(from: AnyPostWithEditContext) defaults metadata when meta is nil")
    func initFromRestDefaultsMetadata() throws {
        let post = makeRemotePost(meta: nil)
        let settings = PostSettings(from: post)
        #expect(settings.metadata.accessLevel == nil)
        #expect(!settings.metadata.isJetpackNewsletterEmailDisabled)
    }

    @Test("apply(to:) converts terms back to name strings")
    func testApplyConvertsTermsToNameStrings() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)
        settings.tags = [
            PostSettings.Term(id: 0, name: "swift"),
            PostSettings.Term(id: 0, name: "ios")
        ]

        // When
        settings.apply(to: post)

        // Then
        #expect(post.tags == "swift, ios")
    }

    @Test("setTerms creates terms with id=0")
    func testSetTermsCreatesTermsWithZeroId() {
        // Given
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()

        var settings = PostSettings(from: post)

        // When
        settings.setTerms("tag1, tag2", forTaxonomySlug: "genre")

        // Then
        #expect(
            settings.getTerms(forTaxonomySlug: "genre") == [
                PostSettings.Term(id: 0, name: "tag1"),
                PostSettings.Term(id: 0, name: "tag2")
            ]
        )
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) produces TermIds from Term storage")
    func testMakeRemoteUpdateParametersIncludesTermIds() {
        // Given
        let post = makeRemotePost(tags: [TermId(5)])

        var settings = PostSettings(from: post)
        // Simulate resolved tags with an additional new tag
        settings.tags = [
            PostSettings.Term(id: 5, name: "swift"),
            PostSettings.Term(id: 8, name: "ios")
        ]

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then — both tags with id > 0 are included
        #expect(Set(params.tags) == Set([TermId(5), TermId(8)]))
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) includes featuredMedia when changed")
    func testMakeRemoteUpdateParametersIncludesFeaturedMedia() {
        // Given: post has no featured image
        let post = makeRemotePost()

        var settings = PostSettings(from: post)
        settings.featuredImageID = 42

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        #expect(params.featuredMedia == MediaId(42))
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) includes featuredMedia removal")
    func testMakeRemoteUpdateParametersIncludesFeaturedMediaRemoval() {
        // Given: post has a featured image
        let post = makeRemotePost(featuredMedia: MediaId(42))

        var settings = PostSettings(from: post)
        settings.featuredImageID = nil

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then: featuredMedia should be set to 0 (removal)
        #expect(params.featuredMedia == MediaId(0))
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) omits featuredMedia when unchanged (MediaId 0)")
    func testMakeRemoteUpdateParametersOmitsFeaturedMediaWhenZero() {
        // Given: post has featuredMedia = 0 (no featured image)
        let post = makeRemotePost(featuredMedia: MediaId(0))

        // Settings should also have no featured image (featuredImageID = nil)
        let settings = PostSettings(from: post)

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then: no spurious diff — featuredMedia should not be included
        #expect(params.featuredMedia == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) omits featuredMedia when unchanged (nil)")
    func testMakeRemoteUpdateParametersOmitsFeaturedMediaWhenNil() {
        // Given: post has featuredMedia = nil
        let post = makeRemotePost()

        let settings = PostSettings(from: post)

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        #expect(params.featuredMedia == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) includes format when changed")
    func testMakeRemoteUpdateParametersIncludesFormat() {
        // Given: post has standard format
        let post = makeRemotePost(format: .standard)

        var settings = PostSettings(from: post)
        settings.postFormat = "image"

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        #expect(params.format == .image)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) includes format when original is nil")
    func testMakeRemoteUpdateParametersIncludesFormatFromNil() {
        // Given: post has no format set
        let post = makeRemotePost()

        var settings = PostSettings(from: post)
        settings.postFormat = "image"

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        #expect(params.format == .image)
    }

    @Test("makeUpdateParameters preserves publicize message when social v2 is unavailable")
    func testMakeRemoteUpdateParametersPreservesPublicizeMessageWhenSocialContextIsNil() {
        // Given: the fetched post has a saved Publicize message, but Social v2
        // is not active for this save path.
        let post = makeRemotePost(meta: PostMeta().addingPublicizeMessage("Saved message"))
        var settings = PostSettings(from: post)
        settings.slug = "changed-slug"

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then: an unrelated settings save must not clear the saved message.
        #expect(params.slug == "changed-slug")
        #expect(params.meta == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) clears publicize message when social v2 draft is empty")
    func testMakeRemoteUpdateParametersClearsPublicizeMessageFromEmptySocialDraft() {
        // Given
        let post = makeRemotePost(meta: PostMeta().addingPublicizeMessage("Saved message"))
        var settings = PostSettings(from: post)
        settings.socialSharingDraft = PostSocialSharingDraft(customMessage: nil)

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then: an active Social v2 draft owns the field, so nil/empty clears it.
        #expect(params.meta != nil)
        #expect(params.meta?.publicizeMessage == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) adds publicize message from social v2 draft")
    func testMakeRemoteUpdateParametersAddsPublicizeMessageFromSocialDraft() {
        // Given
        let post = makeRemotePost()
        var settings = PostSettings(from: post)
        settings.socialSharingDraft = PostSocialSharingDraft(customMessage: "Share this")

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        #expect(params.meta?.publicizeMessage == "Share this")
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) encodes social connections")
    func testMakeRemoteUpdateParametersAddsPublicizeConnectionsFromSocialDraft() throws {
        // Given
        let post = makeRemotePost()
        var settings = PostSettings(from: post)
        settings.socialSharingDraft = PostSocialSharingDraft(connectionsByID: [
            "1": .init(id: "1", enabled: true),
            "2": .init(id: "2", enabled: false),
            "3": .init(id: "3", enabled: true)
        ])

        // When
        let params = settings.makeUpdateParameters(from: post)

        // Then
        let entries = try #require(params.additionalFields?.arrayValueForKey(key: "jetpack_publicize_connections"))
        let flagsByID = Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry -> (String, Bool)? in
                guard case let .object(dict) = entry,
                    case let .string(id)? = dict["connection_id"],
                    case let .bool(enabled)? = dict["enabled"]
                else {
                    return nil
                }
                return (id, enabled)
            }
        )
        #expect(flagsByID == ["1": true, "2": false, "3": true])
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) omits unchanged social connections")
    func testMakeRemoteUpdateParametersOmitsUnchangedPublicizeConnections() {
        let additionalFields = WpAdditionalFields()
            .addingPublicizeConnections([
                "1": .init(id: "1", enabled: true),
                "2": .init(id: "2", enabled: false)
            ])
        let post = makeRemotePost(additionalFields: additionalFields)
        var settings = PostSettings(from: post)
        settings.slug = "changed-slug"

        let params = settings.makeUpdateParameters(from: post)

        #expect(params.slug == "changed-slug")
        #expect(params.additionalFields == nil)
    }

    @Test("Resolved terms (id > 0) are equal when ids match, regardless of name")
    func testResolvedTermEquality() {
        let term1 = PostSettings.Term(id: 5, name: "swift")
        let term2 = PostSettings.Term(id: 5, name: "swift")
        let term3 = PostSettings.Term(id: 5, name: "ios")
        let term4 = PostSettings.Term(id: 6, name: "swift")

        #expect(term1 == term2)
        #expect(term1 == term3, "Same id, different name — same resolved term")
        #expect(term1 != term4, "Different id — different term")
    }

    @Test("Unresolved terms (id == 0) are equal only when names match")
    func testUnresolvedTermEquality() {
        let term1 = PostSettings.Term(id: 0, name: "swift")
        let term2 = PostSettings.Term(id: 0, name: "swift")
        let term3 = PostSettings.Term(id: 0, name: "ios")

        #expect(term1 == term2)
        #expect(term1 != term3, "Same id 0, different name — different unresolved term")
    }

    // MARK: - makeCreateParameters Tests

    @Test("makeCreateParameters includes custom taxonomy terms in additionalFields")
    func testMakeCreateParametersIncludesCustomTerms() {
        // Given
        let taxonomies = [
            SiteTaxonomy.makeTaxonomy(slug: "genre", restBase: "genre")
        ]
        var settings = PostSettings()
        settings.otherTerms = [
            "genre": [
                PostSettings.Term(id: 10, name: "fiction"),
                PostSettings.Term(id: 20, name: "drama")
            ]
        ]

        // When
        let params = settings.makeCreateParameters(taxonomies: taxonomies)

        // Then
        let termIds = params.additionalFields?.termIdsForKey(key: "genre") ?? []
        #expect(Set(termIds) == Set([TermId(10), TermId(20)]))
    }

    @Test("makeCreateParameters encodes the social custom message")
    func testMakeCreateParametersEncodesSocialCustomMessage() {
        // Given
        var settings = PostSettings()
        settings.socialSharingDraft = PostSocialSharingDraft(customMessage: "Share this")

        // When
        let params = settings.makeCreateParameters()

        // Then
        #expect(params.meta?.publicizeMessage == "Share this")
    }

    @Test("makeCreateParameters encodes social connections")
    func testMakeCreateParametersEncodesSocialConnections() throws {
        // Given
        var settings = PostSettings()
        settings.socialSharingDraft = PostSocialSharingDraft(connectionsByID: [
            "1": .init(id: "1", enabled: true),
            "2": .init(id: "2", enabled: false)
        ])

        // When
        let params = settings.makeCreateParameters()

        // Then
        let entries = try #require(params.additionalFields?.arrayValueForKey(key: "jetpack_publicize_connections"))
        let flagsByID = Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry -> (String, Bool)? in
                guard case let .object(dict) = entry,
                    case let .string(id)? = dict["connection_id"],
                    case let .bool(enabled)? = dict["enabled"]
                else {
                    return nil
                }
                return (id, enabled)
            }
        )
        #expect(flagsByID == ["1": true, "2": false])
    }

    // MARK: - makeUpdateParameters(from: AnyPostWithEditContext) Newsletter Meta Tests

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) omits meta when newsletter settings unchanged")
    func updateParamsOmitsMetaWhenUnchanged() throws {
        let meta = PostMeta()
            .addingJetpackNewsletterAccess(.subscribers)
            .addingJetpackNewsletterEmailDisabled(true)
        let post = makeRemotePost(meta: meta)
        let settings = PostSettings(from: post)
        // Sanity: metadata read back correctly.
        #expect(settings.metadata.accessLevel == .subscribers)

        let params = settings.makeUpdateParameters(from: post)
        #expect(params.meta?.jetpackNewsletterAccess == nil)
        #expect(params.meta?.valueForKey(key: "_jetpack_dont_email_post_to_subs") == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) writes access level when changed")
    func updateParamsWritesAccessLevelChange() throws {
        let post = makeRemotePost(meta: nil)
        var settings = PostSettings(from: post)
        settings.metadata.accessLevel = .paidSubscribers

        let params = settings.makeUpdateParameters(from: post)
        #expect(params.meta?.jetpackNewsletterAccess == .paidSubscribers)
        // Email-disabled key should NOT be written because it didn't change.
        #expect(params.meta?.valueForKey(key: "_jetpack_dont_email_post_to_subs") == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) writes email-disabled when changed")
    func updateParamsWritesEmailDisabledChange() throws {
        let post = makeRemotePost(meta: nil)
        var settings = PostSettings(from: post)
        settings.metadata.isJetpackNewsletterEmailDisabled = true

        let params = settings.makeUpdateParameters(from: post)
        #expect(params.meta?.isJetpackNewsletterEmailDisabled == true)
        #expect(params.meta?.valueForKey(key: "_jetpack_newsletter_access") == nil)
    }

    @Test("makeUpdateParameters(from: AnyPostWithEditContext) clears access level when set to nil")
    func updateParamsClearsAccessLevel() throws {
        let meta = PostMeta().addingJetpackNewsletterAccess(.subscribers)
        let post = makeRemotePost(meta: meta)
        var settings = PostSettings(from: post)
        settings.metadata.accessLevel = nil

        let params = settings.makeUpdateParameters(from: post)
        // A nil access level writes `.null` so the server clears the meta.
        #expect(params.meta?.valueForKey(key: "_jetpack_newsletter_access") == JsonValue.null)
    }

    // MARK: - makeCreateParameters Newsletter Meta Tests

    @Test("makeCreateParameters emits access level when set")
    func createParamsEmitsAccessLevel() throws {
        var settings = PostSettings()
        settings.metadata.accessLevel = .subscribers

        let params = settings.makeCreateParameters()
        #expect(params.meta?.jetpackNewsletterAccess == .subscribers)
    }

    @Test("makeCreateParameters emits email-disabled when true")
    func createParamsEmitsEmailDisabled() throws {
        var settings = PostSettings()
        settings.metadata.isJetpackNewsletterEmailDisabled = true

        let params = settings.makeCreateParameters()
        #expect(params.meta?.isJetpackNewsletterEmailDisabled == true)
    }

    @Test("makeCreateParameters omits newsletter meta at defaults")
    func createParamsOmitsDefaults() throws {
        let settings = PostSettings()
        // Defaults: accessLevel nil, isJetpackNewsletterEmailDisabled false.

        let params = settings.makeCreateParameters()
        #expect(params.meta?.valueForKey(key: "_jetpack_newsletter_access") == nil)
        #expect(params.meta?.valueForKey(key: "_jetpack_dont_email_post_to_subs") == nil)
    }

    // MARK: - defaults(from: Blog) Tests

    @Test("defaults inherits site discussion defaults (closed)")
    func testDefaultsInheritsClosedDiscussion() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Test").build()
        blog.settings?.commentsAllowed = NSNumber(value: false)
        blog.settings?.pingbackInboundEnabled = NSNumber(value: false)

        let settings = PostSettings.defaults(from: blog)
        let params = settings.makeCreateParameters(taxonomies: [])

        #expect(settings.allowComments == false)
        #expect(settings.allowPings == false)
        #expect(params.commentStatus == .closed)
        #expect(params.pingStatus == .closed)
    }

    @Test("defaults inherits site discussion defaults (open)")
    func testDefaultsInheritsOpenDiscussion() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Test").build()
        blog.settings?.commentsAllowed = NSNumber(value: true)
        blog.settings?.pingbackInboundEnabled = NSNumber(value: true)

        let settings = PostSettings.defaults(from: blog)
        let params = settings.makeCreateParameters(taxonomies: [])

        #expect(settings.allowComments == true)
        #expect(settings.allowPings == true)
        #expect(params.commentStatus == .open)
        #expect(params.pingStatus == .open)
    }

    // MARK: - PostSettings discussion tri-state

    @Test("New AbstractPost with unset comment status yields nil allowComments")
    func testInitFromNewPostHasUnknownDiscussion() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = nil
        post.pingsStatus = nil

        let settings = PostSettings(from: post)

        #expect(settings.allowComments == nil)
        #expect(settings.allowPings == nil)
    }

    @Test("Existing AbstractPost maps stored comment status to non-nil")
    func testInitFromExistingPostHasKnownDiscussion() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = "closed"
        post.pingsStatus = "open"

        let settings = PostSettings(from: post)

        #expect(settings.allowComments == false)
        #expect(settings.allowPings == true)
    }

    @Test("REST post with unset comment status yields nil discussion settings")
    func testInitFromRestPostHasUnknownDiscussion() {
        let post = makeRemotePost(commentStatus: nil, pingStatus: nil)

        let settings = PostSettings(from: post)

        #expect(settings.allowComments == nil)
        #expect(settings.allowPings == nil)
    }

    @Test("makeCreateParameters omits comment status when unknown")
    func testMakeCreateParametersOmitsUnknownDiscussion() {
        var settings = PostSettings()
        settings.allowComments = nil
        settings.allowPings = nil

        let params = settings.makeCreateParameters()

        #expect(params.commentStatus == nil)
        #expect(params.pingStatus == nil)
    }

    @Test("makeUpdateParameters omits comment/ping status when unknown")
    func testMakeUpdateParametersOmitsUnknownDiscussion() {
        let post = makeRemotePost()
        var settings = PostSettings(from: post)
        settings.allowComments = nil
        settings.allowPings = nil

        let params = settings.makeUpdateParameters(from: post)

        #expect(params.commentStatus == nil)
        #expect(params.pingStatus == nil)
    }

    @Test("apply leaves stored comment/ping status untouched when unknown")
    func testApplyLeavesDiscussionUntouchedWhenUnknown() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = "closed"
        post.pingsStatus = "closed"

        var settings = PostSettings(from: post)
        settings.allowComments = nil
        settings.allowPings = nil
        settings.apply(to: post)

        #expect(post.commentsStatus == "closed")
        #expect(post.pingsStatus == "closed")
    }

    // MARK: - Blog.createPost() discussion seeding

    @Test("createPost seeds comment/ping status from blog discussion defaults")
    func testCreatePostSeedsDiscussionDefaults() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Test").build()
        blog.settings?.commentsAllowed = NSNumber(value: false)
        blog.settings?.pingbackInboundEnabled = NSNumber(value: true)

        let post = blog.createPost()

        #expect(post.commentsStatus == "closed")
        #expect(post.pingsStatus == "open")
    }

    // MARK: - Unreadable site discussion defaults

    @Test("defaults yields nil discussion when site defaults are unreadable")
    func testDefaultsUnknownWhenSiteDefaultsUnreadable() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Test").build()
        blog.settings?.commentsAllowed = nil
        blog.settings?.pingbackInboundEnabled = nil

        let settings = PostSettings.defaults(from: blog)

        #expect(settings.allowComments == nil)
        #expect(settings.allowPings == nil)
    }

    @Test("createPost leaves comment status unset when site defaults are unreadable")
    func testCreatePostNoSeedWhenUnreadable() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(siteName: "Test").build()
        blog.settings?.commentsAllowed = nil
        blog.settings?.pingbackInboundEnabled = nil

        let post = blog.createPost()

        #expect(post.commentsStatus == nil)
        #expect(post.pingsStatus == nil)
    }

    // MARK: - Discussion row visibility gate (CMM-2077)

    @Test("Discussion row is hidden for a new post with unknown discussion defaults")
    func testDiscussionRowHiddenWhenDefaultsUnknown() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = nil
        post.pingsStatus = nil

        let viewModel = PostSettingsViewModel(post: post)

        #expect(viewModel.settings.allowComments == nil)
        #expect(!viewModel.visibleMoreOptions.contains(.discussion))
    }

    @Test("Discussion row is shown when the post has a known comment status")
    func testDiscussionRowShownWhenStatusKnown() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = "open"
        post.pingsStatus = "open"

        let viewModel = PostSettingsViewModel(post: post)

        #expect(viewModel.settings.allowComments == true)
        #expect(viewModel.visibleMoreOptions.contains(.discussion))
    }

    @Test("Discussion row is shown when only the ping status is known")
    func testDiscussionRowShownWhenOnlyPingStatusKnown() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).build()
        let post = PostBuilder(context, blog: blog).build()
        post.commentsStatus = nil
        post.pingsStatus = "open"

        let viewModel = PostSettingsViewModel(post: post)

        #expect(viewModel.settings.allowComments == nil)
        #expect(viewModel.settings.allowPings == true)
        #expect(viewModel.visibleMoreOptions.contains(.discussion))
    }

    @Test("Discussion view only shows sections for known settings")
    func testDiscussionViewSectionVisibility() {
        let commentsOnlyView = makeDiscussionView(allowComments: true, allowPings: nil)
        #expect(commentsOnlyView.showsCommentsSection)
        #expect(!commentsOnlyView.showsPingsSection)

        let pingsOnlyView = makeDiscussionView(allowComments: nil, allowPings: true)
        #expect(!pingsOnlyView.showsCommentsSection)
        #expect(pingsOnlyView.showsPingsSection)
    }

    // MARK: - Jetpack newsletter row visibility gate (post-type)

    /// Positive control: proves the blog setup actually enables newsletter, so the
    /// Page assertions below fail for the post-type reason, not a mis-configured blog.
    @Test("shouldShow .jetpackAccessLevel is true for a Post on a newsletter site")
    func testAccessLevelShownForPost() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = newsletterBlog(context)
        let post = PostBuilder(context, blog: blog).build()
        try context.save()

        let viewModel = PostSettingsViewModel(post: post)
        #expect(viewModel.shouldShow(.jetpackAccessLevel))
    }

    @Test("shouldShow .jetpackAccessLevel is false for a Page even on a newsletter site")
    func testAccessLevelHiddenForPage() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = newsletterBlog(context)
        let page = PageBuilder(context).build()
        page.blog = blog // PageBuilder builds its own accountless blog; move it onto the newsletter-capable one
        try context.save()

        let viewModel = PostSettingsViewModel(post: page)
        #expect(!viewModel.shouldShow(.jetpackAccessLevel))
    }

    /// Positive control for the publishing branch: proves a Post in publishing context
    /// shows the newsletter row, so the Page assertion below fails for the post-type reason.
    @Test("shouldShow .jetpackNewsletterEmailOptions is true for a Post in publishing context")
    func testNewsletterEmailShownForPostInPublishing() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = newsletterBlog(context)
        let post = PostBuilder(context, blog: blog).build()
        try context.save()

        let viewModel = PostSettingsViewModel(post: post, context: .publishing)
        #expect(viewModel.shouldShow(.jetpackNewsletterEmailOptions))
    }

    @Test("shouldShow .jetpackNewsletterEmailOptions is false for a Page in publishing context")
    func testNewsletterEmailHiddenForPage() throws {
        let context = ContextManager.forTesting().mainContext
        let blog = newsletterBlog(context)
        let page = PageBuilder(context).build()
        page.blog = blog
        try context.save()

        let viewModel = PostSettingsViewModel(post: page, context: .publishing)
        #expect(!viewModel.shouldShow(.jetpackNewsletterEmailOptions))
    }
}

// MARK: - Test Helpers

private extension SiteTaxonomy {
    static func makeTaxonomy(slug: String, restBase: String) -> SiteTaxonomy {
        SiteTaxonomy(slug: slug, name: slug, restBase: restBase)
    }
}

private func makeDiscussionView(allowComments: Bool?, allowPings: Bool?) -> PostDiscussionSettingsView {
    var settings = PostSettings()
    settings.allowComments = allowComments
    settings.allowPings = allowPings
    return PostDiscussionSettingsView(postSettings: .constant(settings))
}

/// A blog that supports Jetpack newsletter: the "subscriptions" module is what
/// `Blog.supports(.jetpackNewsletter)` checks for a self-hosted (account-backed) site.
private func newsletterBlog(_ context: NSManagedObjectContext) -> Blog {
    BlogBuilder(context)
        .withAnAccount()
        .with(modules: ["subscriptions"])
        .build()
}

private func makeRemotePost(
    tags: [TermId]? = nil,
    categories: [TermId]? = nil,
    featuredMedia: MediaId? = nil,
    format: PostFormat? = nil,
    meta: PostMeta? = nil,
    commentStatus: PostCommentStatus? = .open,
    pingStatus: PostPingStatus? = .open,
    additionalFields: WpAdditionalFields? = nil
) -> AnyPostWithEditContext {
    AnyPostWithEditContext(
        id: PostId(1),
        date: "2025-01-01T00:00:00",
        dateGmt: Date(timeIntervalSince1970: 0),
        guid: PostGuidWithEditContext(raw: nil, rendered: ""),
        link: "https://example.com",
        modified: "2025-01-01T00:00:00",
        modifiedGmt: Date(timeIntervalSince1970: 0),
        slug: "test-post",
        status: .draft,
        postType: "post",
        password: nil,
        permalinkTemplate: nil,
        generatedSlug: nil,
        title: nil,
        content: PostContentWithEditContext(raw: nil, rendered: "", protected: nil, blockVersion: nil),
        author: nil,
        excerpt: nil,
        featuredMedia: featuredMedia,
        commentStatus: commentStatus,
        pingStatus: pingStatus,
        format: format,
        meta: meta,
        sticky: nil,
        template: "",
        categories: categories,
        tags: tags,
        parent: nil,
        menuOrder: nil,
        additionalFields: additionalFields
    )
}
