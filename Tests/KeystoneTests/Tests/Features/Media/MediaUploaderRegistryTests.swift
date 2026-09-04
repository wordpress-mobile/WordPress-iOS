import Foundation
import CoreData
import Testing
import WordPressData
@testable import WordPress

@Suite("MediaUploaderRegistry", .serialized)
@MainActor
struct MediaUploaderRegistryTests {
    let contextManager = ContextManager.forTesting()
    var mainContext: NSManagedObjectContext { contextManager.mainContext }

    // WordPressSite(blog:) for a dotCom blog requires a non-nil dotComID and
    // account.authToken so it can construct the .dotCom case without hitting
    // the keychain.
    private func makeBlog(siteId: Int) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.dotComID = siteId as NSNumber
        blog.account?.authToken = "test-token"
        // TaggedManagedObjectID(blog) requires a permanent ID; save the
        // context so Core Data assigns one before the blog is keyed.
        contextManager.saveContextAndWait(mainContext)
        return blog
    }

    @Test("Returns the same uploader for the same blog")
    func sameBlogReturnsSameUploader() throws {
        let blog = makeBlog(siteId: 1)
        let registry = MediaUploaderRegistry(mainContext: mainContext)
        let first = try registry.uploader(for: blog)
        let second = try registry.uploader(for: blog)
        #expect(first === second)
    }

    @Test("tearDown removes only the targeted blog's uploader")
    func tearDownIsTargeted() async throws {
        let blogA = makeBlog(siteId: 1)
        let blogB = makeBlog(siteId: 2)
        let registry = MediaUploaderRegistry(mainContext: mainContext)
        _ = try registry.uploader(for: blogA)
        let bUploader = try registry.uploader(for: blogB)
        await registry.tearDown(blogID: TaggedManagedObjectID(blogA))
        let bAgain = try registry.uploader(for: blogB)
        #expect(bUploader === bAgain)
    }

    @Test("tearDownAll clears every uploader")
    func tearDownAllClears() async throws {
        let blogA = makeBlog(siteId: 1)
        let blogB = makeBlog(siteId: 2)
        let registry = MediaUploaderRegistry(mainContext: mainContext)
        let aFirst = try registry.uploader(for: blogA)
        _ = try registry.uploader(for: blogB)
        await registry.tearDownAll()
        let aSecond = try registry.uploader(for: blogA)
        #expect(aFirst !== aSecond)
    }

    @Test("Deleting a blog tears down its uploader")
    func blogDeletionTearsDownUploader() throws {
        let blogA = makeBlog(siteId: 1)
        let blogB = makeBlog(siteId: 2)
        let blogAID = TaggedManagedObjectID(blogA)
        let blogBID = TaggedManagedObjectID(blogB)
        let registry = MediaUploaderRegistry(mainContext: mainContext)
        _ = try registry.uploader(for: blogA)
        _ = try registry.uploader(for: blogB)

        mainContext.delete(blogA)
        contextManager.saveContextAndWait(mainContext)

        #expect(!registry.hasUploader(blogID: blogAID))
        #expect(registry.hasUploader(blogID: blogBID))
    }
}
