extension BlogService {
    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let service = BlogService(managedObjectContext: context)
        return service.blog(byBlogId: site.siteID as NSNumber, andUsername: site.username)
    }
}
