import Foundation

extension ReaderPost {

    @objc var blog: Blog? {
        guard let siteID = siteID, siteID.intValue > 0 else {
            return nil
        }
        let service = BlogService(managedObjectContext: ContextManager.shared.mainContext)
        return service.blog(byBlogId: siteID)
    }
}
