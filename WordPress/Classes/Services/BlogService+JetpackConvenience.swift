extension BlogService {
    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let service = BlogService(managedObjectContext: context)

        let blog: Blog?

        if site.isSelfHostedWithoutJetpack, let xmlRPC = site.xmlRPC {
            blog = service.findBlog(withXmlrpc: xmlRPC, andUsername: site.username)
        } else {
            blog = try? CoreDataQuery<Blog>.default().blogID(site.siteID).username(site.username).first(in: context)
        }

        return blog
    }
}
