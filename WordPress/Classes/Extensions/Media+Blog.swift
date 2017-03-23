import Foundation

extension Media {

    /// Inserts and returns a new managed Media object, in the context.
    ///
    class func inserted(into context: NSManagedObjectContext) -> Media {
        let media = NSEntityDescription.insertNewObject(forEntityName: "Media", into: context) as! Media
        media.creationDate = Date()
        media.mediaID = 0
        return media
    }

    /// Inserts and returns a new managed Media object, with a blog.
    ///
    class func insertedWith(blog: Blog) -> Media {
        let media = inserted(into: blog.managedObjectContext!)
        media.blog = blog
        return media
    }

    /// Inserts and returns a new managed Media object, with a post.
    ///
    class func insertedWith(post: AbstractPost) -> Media {
        let media = insertedWith(blog: post.blog)
        media.addPostsObject(post)
        return media
    }

    /// Returns an existing Media object that matches the mediaID if it exists, or nil.
    ///
    class func existingMediaWith(mediaID: NSNumber, inBlog blog: Blog) -> Media? {
        guard let blogMedia = blog.media as? Set<Media> else {
            return nil
        }
        return blogMedia.first(where: ({ $0.mediaID == mediaID }))
    }
}
