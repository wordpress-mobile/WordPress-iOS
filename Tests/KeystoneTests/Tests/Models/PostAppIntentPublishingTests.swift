import Foundation
import Testing
import WordPressKit

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Post app intent publishing eligibility search")
struct PostAppIntentPublishingSearchTests {
    @Test("returns drafts, pending, and scheduled posts but not published or trashed ones")
    func returnsOnlyPublishableStatuses() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let draft = PostBuilder(context, blog: blog).drafted().with(title: "Draft").build()
        draft.postID = 1
        let pending = PostBuilder(context, blog: blog).pending().with(title: "Pending").build()
        pending.postID = 2
        let scheduled = PostBuilder(context, blog: blog).scheduled().with(title: "Scheduled").build()
        scheduled.postID = 3
        let published = PostBuilder(context, blog: blog).published().with(title: "Published").build()
        published.postID = 4
        let trashed = PostBuilder(context, blog: blog).trashed().with(title: "Trashed").build()
        trashed.postID = 5

        let results = Post.recentForAppIntentPublishing(in: context)

        #expect(Set(results) == Set([draft, pending, scheduled]))
    }

    @Test("excludes pages")
    func excludesPages() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let page = PageBuilder(context).build()
        page.blog = blog
        page.postTitle = "Draft page"
        page.status = .draft
        page.postID = 1

        #expect(Post.recentForAppIntentPublishing(in: context) == [])
    }

    @Test("excludes local-only posts")
    func excludesLocalOnlyPosts() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        PostBuilder(context, blog: blog).drafted().with(title: "Local only").build()

        #expect(Post.recentForAppIntentPublishing(in: context) == [])
    }

    @Test("excludes posts with unsaved local edits")
    func excludesPostsWithUnsavedEdits() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let edited = PostBuilder(context, blog: blog).drafted().with(title: "Edited").build()
        edited.postID = 1
        _ = edited.createRevision()

        #expect(Post.recentForAppIntentPublishing(in: context) == [])
    }

    @Test("returns recent posts, most recently modified first")
    func returnsRecentPostsFirst() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let older = PostBuilder(context, blog: blog).drafted().with(title: "Older")
            .with(dateModified: Date(timeIntervalSince1970: 1000)).build()
        older.postID = 1
        let newer = PostBuilder(context, blog: blog).drafted().with(title: "Newer")
            .with(dateModified: Date(timeIntervalSince1970: 2000)).build()
        newer.postID = 2

        #expect(Post.recentForAppIntentPublishing(in: context) == [newer, older])
    }

    @Test("caps the number of results")
    func capsResults() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        for index in 1...3 {
            let post = PostBuilder(context, blog: blog).drafted().with(title: "Post \(index)").build()
            post.postID = NSNumber(value: index)
        }

        #expect(Post.recentForAppIntentPublishing(limit: 2, in: context).count == 2)
    }
}

@MainActor
@Suite("Post app intent publishing blocker")
struct PostAppIntentPublishingBlockerTests {
    @Test("a server-synced draft, pending, or scheduled post has no blocker")
    func publishablePostsHaveNoBlocker() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let draft = PostBuilder(context, blog: blog).drafted().build()
        draft.postID = 1
        let pending = PostBuilder(context, blog: blog).pending().build()
        pending.postID = 2
        let scheduled = PostBuilder(context, blog: blog).scheduled().build()
        scheduled.postID = 3

        #expect(draft.appIntentPublishingBlocker == nil)
        #expect(pending.appIntentPublishingBlocker == nil)
        #expect(scheduled.appIntentPublishingBlocker == nil)
    }

    @Test("a page is blocked")
    func pageIsBlocked() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let page = PageBuilder(context).build()
        page.blog = blog
        page.status = .draft
        page.postID = 1

        #expect(page.appIntentPublishingBlocker == .isPage)
    }

    @Test("a local-only post is blocked")
    func localOnlyPostIsBlocked() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).drafted().build()

        #expect(post.appIntentPublishingBlocker == .localOnly)
    }

    @Test("a post with unsaved local edits is blocked")
    func postWithUnsavedEditsIsBlocked() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        post.postID = 1
        _ = post.createRevision()

        #expect(post.appIntentPublishingBlocker == .hasUnsavedChanges)
    }

    @Test("a user without the publish capability is blocked")
    func missingPublishCapabilityIsBlocked() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).with(capabilities: [.editPosts]).build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        post.postID = 1

        #expect(post.appIntentPublishingBlocker == .publishingNotAllowed)
    }

    @Test("a user with the publish capability has no blocker")
    func publishCapabilityHasNoBlocker() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).with(capabilities: [.publishPosts]).build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        post.postID = 1

        #expect(post.appIntentPublishingBlocker == nil)
    }

    @Test("a site without loaded capabilities stays allowed")
    func nilCapabilitiesHasNoBlocker() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).drafted().build()
        post.postID = 1

        #expect(blog.capabilities == nil)
        #expect(post.appIntentPublishingBlocker == nil)
    }

    @Test("a published or trashed post is blocked")
    func nonPublishableStatusIsBlocked() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let published = PostBuilder(context, blog: blog).published().build()
        published.postID = 1
        let trashed = PostBuilder(context, blog: blog).trashed().build()
        trashed.postID = 2

        #expect(published.appIntentPublishingBlocker == .notPublishable)
        #expect(trashed.appIntentPublishingBlocker == .notPublishable)
    }
}

@MainActor
@Suite("Post app intent publishing parameters")
struct PostAppIntentPublishingParametersTests {
    @Test("publishing a draft sets the publish status and keeps the date")
    func publishParametersForDraft() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let draft = PostBuilder(context, blog: blog).drafted().build()
        draft.postID = 1

        let changes = draft.appIntentPublishParameters(now: Date(timeIntervalSince1970: 5000))

        #expect(changes.status == Post.Status.publish.rawValue)
        #expect(changes.date == nil)
    }

    @Test("publishing a scheduled post moves its date to now so it publishes immediately")
    func publishParametersForScheduledPost() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let scheduled = PostBuilder(context, blog: blog).scheduled().build()
        scheduled.postID = 1
        let now = Date(timeIntervalSince1970: 5000)

        let changes = scheduled.appIntentPublishParameters(now: now)

        #expect(changes.status == Post.Status.publish.rawValue)
        #expect(changes.date == now)
    }

    @Test("scheduling sets the scheduled status and the given date")
    func scheduleParameters() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let draft = PostBuilder(context, blog: blog).drafted().build()
        draft.postID = 1
        let date = Date(timeIntervalSince1970: 90000)

        let changes = draft.appIntentScheduleParameters(for: date)

        #expect(changes.status == Post.Status.scheduled.rawValue)
        #expect(changes.date == date)
    }
}

@Suite("Remote post update parameters publish date coercion")
struct RemotePostUpdateParametersPublishingTests {
    @Test("publishing privately from scheduled also moves the date to now")
    func privatePublishFromScheduledMovesDate() {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.publishPrivate.rawValue
        let now = Date(timeIntervalSince1970: 5000)

        changes.setDateForImmediatePublishIfNeeded(previousStatus: .scheduled, now: now)

        #expect(changes.date == now)
    }

    @Test("an explicitly chosen publish date is preserved")
    func explicitDateIsPreserved() {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.publish.rawValue
        let date = Date(timeIntervalSince1970: 90000)
        changes.date = date

        changes.setDateForImmediatePublishIfNeeded(previousStatus: .scheduled, now: Date(timeIntervalSince1970: 5000))

        #expect(changes.date == date)
    }

    @Test("a post that was not scheduled keeps a nil date")
    func nonScheduledPreviousStatusKeepsNilDate() {
        var changes = RemotePostUpdateParameters()
        changes.status = Post.Status.publish.rawValue

        changes.setDateForImmediatePublishIfNeeded(previousStatus: .draft, now: Date(timeIntervalSince1970: 5000))

        #expect(changes.date == nil)
    }
}
