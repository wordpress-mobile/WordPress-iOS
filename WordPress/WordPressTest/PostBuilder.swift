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

    func with(pathForDisplayImage: String) -> PostBuilder {
        post.pathForDisplayImage = pathForDisplayImage
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

    func with(remoteStatus: AbstractPostRemoteStatus) -> PostBuilder {
        post.remoteStatus = remoteStatus
        return self
    }

    func with(image: String, status: MediaRemoteStatus? = nil) -> PostBuilder {
        guard let context = post.managedObjectContext else {
            return self
        }

        guard let media = NSEntityDescription.insertNewObject(forEntityName: Media.classNameWithoutNamespaces(), into: context) as? Media else {
            return self
        }
        media.localURL = image
        media.localThumbnailURL = "thumb-\(image)"

        if let status = status {
            media.remoteStatus = status
        }

        media.addPostsObject(post)
        post.addMediaObject(media)

        return self
    }

    func with(media: [Media]) -> PostBuilder {
        post.media = Set(media)

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
