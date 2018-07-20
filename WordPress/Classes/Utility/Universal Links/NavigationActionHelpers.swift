import Foundation

extension NavigationAction {
    func defaultBlog() -> Blog? {
        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        return service.lastUsedOrFirstBlog()
    }

    func blog(from values: [String: String]?) -> Blog? {
        guard let domain = values?["domain"] else {
            return nil
        }

        let context = ContextManager.sharedInstance().mainContext
        let service = BlogService(managedObjectContext: context)

        if let blog = service.blog(byHostname: domain) {
            return blog
        }

        // Some stats URLs use a site ID instead
        if let siteIDValue = Int(domain) {
            return service.blog(byBlogId: NSNumber(value: siteIDValue))
        }

        return nil
    }
}
