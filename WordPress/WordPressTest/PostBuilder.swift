import Foundation

@testable import WordPress

/// Builds a Post
///
/// Defaults to creating a post in a self-hosted site.
class PostBuilder {
    private let post: Post

    init(_ context: NSManagedObjectContext = PostBuilder.setUpInMemoryManagedObjectContext()) {
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as! Post

        // Non-null Core Data properties
        post.blog = BlogBuilder(context).build()
    }

    private static func buildPost(context: NSManagedObjectContext) -> Post {
        let blog = NSEntityDescription.insertNewObject(forEntityName: Blog.entityName(), into: context) as! Blog
        blog.xmlrpc = "http://example.com/xmlrpc.php"
        blog.url = "http://example.com"
        blog.username = "test"
        blog.password = "test"

        let post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as! Post
        post.blog = blog

        return post
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

    func pending() -> PostBuilder {
        post.status = .pending
        return self
    }

    func revision() -> PostBuilder {
        post.setPrimitiveValue(post, forKey: "original")
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

    func with(statusAfterSync: BasePost.Status?) -> PostBuilder {
        post.statusAfterSync = statusAfterSync
        return self
    }

    func with(image: String, status: MediaRemoteStatus? = nil, autoUploadFailureCount: Int = 0) -> PostBuilder {
        guard let context = post.managedObjectContext else {
            return self
        }

        guard let media = NSEntityDescription.insertNewObject(forEntityName: Media.entityName(), into: context) as? Media else {
            return self
        }
        media.localURL = image
        media.localThumbnailURL = "thumb-\(image)"
        media.blog = post.blog
        media.autoUploadFailureCount = NSNumber(value: autoUploadFailureCount)

        if let status = status {
            media.remoteStatus = status
        }

        media.addPostsObject(post)
        post.addMediaObject(media)

        return self
    }

    func with(media: [Media]) -> PostBuilder {
        for item in media {
             item.blog = post.blog
        }
        post.media = Set(media)

        return self
    }

    func with(autoUploadAttemptsCount: Int) -> PostBuilder {
        post.autoUploadAttemptsCount = NSNumber(value: autoUploadAttemptsCount)

        return self
    }

    func `is`(sticked: Bool) -> PostBuilder {
        post.isStickyPost = sticked
        return self
    }

    func supportsWPComAPI() -> PostBuilder {
        post.blog.supportsWPComAPI()
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
