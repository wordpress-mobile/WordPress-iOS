import Foundation

@testable import WordPress

class PostBuilder {
    private let post: Post

    init(_ context: NSManagedObjectContext = PostBuilder.setUpInMemoryManagedObjectContext()) {
        post = Post(context: context)

        // Non-null Core Data properties
        post.blog = BlogBuilder(context).build()
    }

    func published() -> PostBuilder {
        post.status = .publish
        return self
    }

    func drafted() -> PostBuilder {
        post.status = .draft
        return self
    }

    func scheduled() -> PostBuilder {
        post.status = .scheduled
        return self
    }

    func trashed() -> PostBuilder {
        post.status = .trash
        return self
    }

    func `private`() -> PostBuilder {
        post.status = .publishPrivate
        return self
    }

    func withImage() -> PostBuilder {
        post.pathForDisplayImage = "https://localhost/image.png"
        return self
    }

    func with(status: BasePost.Status) -> PostBuilder {
        post.status = status
        return self
    }

    func with(title: String) -> PostBuilder {
        post.postTitle = title
        return self
    }

    func with(snippet: String) -> PostBuilder {
        post.content = snippet
        return self
    }

    func with(dateCreated: Date) -> PostBuilder {
        post.dateCreated = dateCreated
        return self
    }

    func with(dateModified: Date) -> PostBuilder {
        post.dateModified = dateModified
        return self
    }

    func with(author: String) -> PostBuilder {
        post.author = author
        return self
    }

    func with(userName: String) -> PostBuilder {
        post.blog.username = userName
        return self
    }

    func with(password: String) -> PostBuilder {
        post.blog.password = password
        return self
    }

    func with(remoteStatus: AbstractPostRemoteStatus) -> PostBuilder {
        post.remoteStatus = remoteStatus
        return self
    }

    func `is`(sticked: Bool) -> PostBuilder {
        post.isStickyPost = sticked
        return self
    }

    func confirmedAutoUpload() -> PostBuilder {
        post.shouldAttemptAutoUpload = true
        return self
    }

    /// Sets a random postID to emulate that self exists in the server.
    func withRemote() -> PostBuilder {
        post.postID = NSNumber(value: arc4random_uniform(UINT32_MAX))
        return self
    }

    func cancelledAutoUpload() -> PostBuilder {
        post.shouldAttemptAutoUpload = false
        return self
    }

    func build() -> Post {
        return post
    }

    private static func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }
}
