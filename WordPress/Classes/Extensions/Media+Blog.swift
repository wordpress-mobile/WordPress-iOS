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
}
