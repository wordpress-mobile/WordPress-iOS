import CoreData
import Testing

@testable import WordPress
@testable import WordPressData
import WordPressKit

@MainActor
struct PostRepositoryPostLifetimeTests {
    enum Operation: CaseIterable {
        case create, save, update, delete, autosave

        @MainActor
        func perform(on post: AbstractPost, using repository: PostRepository) async throws {
            var changes = RemotePostUpdateParameters()
            changes.title = "Updated"
            switch self {
            case .create, .save:
                try await repository.save(post, changes: changes)
            case .update:
                try await repository.update(post, changes: changes)
            case .delete:
                try await repository.delete(post)
            case .autosave:
                _ = try await repository.autosave(post)
            }
        }
    }

    @Test
    func trashAfterBackgroundPurge() async throws {
        let stack = ContextManager.forTesting()
        let post = makePost(in: stack)
        let blogID = TaggedManagedObjectID(post.blog)
        let factory = RemoteFactorySpy()
        let repository = PostRepository(coreDataStack: stack, remoteFactory: factory)

        try await stack.performAndSave { context in
            _ = PostHelper.merge(
                [],
                ofType: "post",
                withStatuses: ["publish"],
                byAuthor: nil,
                for: try context.existingObject(with: blogID),
                purgeExisting: true,
                in: context
            )
        }
        await stack.mainContext.perform {}

        // A background purge clears the relationship before the retained ID.
        try #require(post.isDeleted)
        #expect(post.postID == 123)
        #expect(post.value(forKey: "blog") == nil)

        await #expect(throws: PostRepository.Error.self) {
            try await repository.trash(post)
        }
        #expect(factory.callCount == 0)
    }

    @Test(arguments: Operation.allCases)
    func rejectsMissingBlog(operation: Operation) async throws {
        let stack = ContextManager.forTesting()
        let post = makePost(in: stack)
        if operation == .create {
            post.postID = nil
        }
        let subject = operation == .autosave ? post.createRevision() : post
        subject.setValue(nil, forKey: "blog")
        let factory = RemoteFactorySpy()
        let repository = PostRepository(coreDataStack: stack, remoteFactory: factory)

        await #expect(throws: PostRepository.Error.self) {
            try await operation.perform(on: subject, using: repository)
        }
        #expect(factory.callCount == 0)
    }

    @Test
    func rejectsDeletedAutosaveRevision() async throws {
        let stack = ContextManager.forTesting()
        let post = makePost(in: stack)
        let revision = post.createRevision()
        stack.saveContextAndWait(stack.mainContext)
        stack.mainContext.delete(revision)
        stack.saveContextAndWait(stack.mainContext)
        let factory = RemoteFactorySpy()
        let repository = PostRepository(coreDataStack: stack, remoteFactory: factory)

        await #expect(throws: PostRepository.Error.self) {
            _ = try await repository.autosave(revision)
        }
        #expect(factory.callCount == 0)
    }

    private func makePost(in stack: ContextManager) -> Post {
        let post = PostBuilder(stack.mainContext).published().build()
        post.postID = 123
        stack.saveContextAndWait(stack.mainContext)
        return post
    }
}

private final class RemoteFactorySpy: PostServiceRemoteFactory {
    private(set) var callCount = 0

    override func forBlog(_ blog: Blog) -> PostServiceRemote? {
        callCount += 1
        return nil
    }
}
