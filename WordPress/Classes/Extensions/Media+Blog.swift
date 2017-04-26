import Foundation

extension Media {

    /// Inserts and returns a new managed Media object, in the context.
    ///
    class func makeMedia(in context: NSManagedObjectContext) -> Media {
        let media = NSEntityDescription.insertNewObject(forEntityName: "Media", into: context) as! Media
        media.creationDate = Date()
        media.mediaID = 0
        return media
    }

    /// Inserts and returns a new managed Media object, with a blog.
    ///
    class func makeMedia(blog: Blog) -> Media {
        let media = makeMedia(in: blog.managedObjectContext!)
        media.blog = blog
        return media
    }

    /// Inserts and returns a new managed Media object, with a post.
    ///
    class func makeMedia(post: AbstractPost) -> Media {
        let media = makeMedia(blog: post.blog)
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

    /// Returns an existing Media object that matches the remoteURL if it exists, or nil.
    ///
    class func existingMediaWith(remoteURL: String, inBlog blog: Blog) -> Media? {
        guard let blogMedia = blog.media as? Set<Media> else {
            return nil
        }
        return blogMedia.first(where: ({ $0.remoteURL == remoteURL }))
    }
}
