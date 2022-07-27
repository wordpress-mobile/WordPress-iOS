extension BlogService {
    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let service = BlogService(managedObjectContext: context)

        let blog: Blog?

        if site.isSelfHostedWithoutJetpack, let xmlRPC = site.xmlRPC {
            blog = service.findBlog(withXmlrpc: xmlRPC, andUsername: site.username)
        } else {
            blog = service.blog(byBlogId: site.siteID as NSNumber, andUsername: site.username)
        }

        return blog
    }
}
