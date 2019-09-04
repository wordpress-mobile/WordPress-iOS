import Foundation

@testable import WordPress

class PostBuilder {

    var post: Post!

    init() {
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: setUpInMemoryManagedObjectContext()) as? Post
    }

    init(_ context: NSManagedObjectContext) {
        post = NSEntityDescription.insertNewObject(forEntityName: Post.entityName(), into: context) as? Post
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

    func `is`(sticked: Bool) -> PostBuilder {
        post.isStickyPost = sticked
        return self
    }

    func build() -> Post {
        return post
    }

    private func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
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
