@testable import WordPress

/// Builds a `ReaderPost`
///
class ReaderPostBuilder {
    private let post: ReaderPost

    init(_ context: NSManagedObjectContext, blog: Blog? = nil) {
        post = NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: context) as! ReaderPost
    }

    func build() -> ReaderPost {
        post.blogURL = "https://wordpress.com"
        post.permaLink = "https://wordpress.com"
        return post
    }
}
