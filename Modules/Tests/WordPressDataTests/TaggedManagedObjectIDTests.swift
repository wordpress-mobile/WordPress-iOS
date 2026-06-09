import Foundation
import Testing
import CoreData

@testable import WordPressData

@Suite struct TaggedManagedObjectIDTests {
    private let contextManager = ContextManager.forTesting()

    @Test func querySaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        try contextManager.mainContext.save()

        let id = TaggedManagedObjectID(post)
        let result = try contextManager.mainContext.existingObject(with: id)
        #expect(result.postTitle == "Test post")
    }

    @Test func queryUnsaved() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let id = TaggedManagedObjectID(post)

        try contextManager.mainContext.save()

        let newContext = contextManager.newDerivedContext()
        let result = try newContext.existingObject(with: id)
        #expect(result.postTitle == "Test post")
    }

    @Test func queryUnsavedUsingTheSameContext() throws {
        let context = contextManager.mainContext
        let post = PostBuilder(context).with(title: "Test post").build()
        let id = TaggedManagedObjectID(post)

        let result = try context.existingObject(with: id)
        #expect(result.postTitle == "Test post")
    }

    @Test func queryUnsavedUsingDifferentContext() throws {
        let post = PostBuilder(contextManager.mainContext).build()
        let id = TaggedManagedObjectID(post)

        let newContext = contextManager.newDerivedContext()

        #expect(throws: (any Error).self) {
            try newContext.existingObject(with: id)
        }
    }

    @Test func equatable() throws {
        let post = PostBuilder(contextManager.mainContext).with(title: "Test post").build()
        let unsavedID = TaggedManagedObjectID(post)
        try contextManager.mainContext.save()
        let savedID = TaggedManagedObjectID(post)

        #expect(unsavedID == savedID)
        #expect(TaggedManagedObjectID(post) == savedID)
    }

    // MARK: - Covariance workaround demo

    // This is not really a test. More like a demonstration of how to work around Swift compiler's
    // covariance support. If this test compiles, then the overload definition works.
    @Test func covariance() throws {
        let post = PostBuilder(contextManager.mainContext).with(author: "WordPress.com").build()
        try contextManager.mainContext.save()

        let postID: TaggedManagedObjectID<Post> = .init(post)
        let abstractPostID: TaggedManagedObjectID<AbstractPost> = .init(post)

        #expect(try author(of: postID, in: contextManager.mainContext) == "WordPress.com")
        #expect(try author(of: abstractPostID, in: contextManager.mainContext) == "WordPress.com")
    }

    private func author(of id: TaggedManagedObjectID<AbstractPost>, in context: NSManagedObjectContext) throws -> String? {
        try context.existingObject(with: id).author
    }

    private func author<T: AbstractPost>(of id: TaggedManagedObjectID<T>, in context: NSManagedObjectContext) throws -> String? {
        try context.existingObject(with: id).author
    }
}
