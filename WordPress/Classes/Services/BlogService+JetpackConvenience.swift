extension BlogService {
    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let blog: Blog?

        if site.isSelfHostedWithoutJetpack, let xmlRPC = site.xmlRPC {
            blog = Blog.lookup(username: site.username, xmlrpc: xmlRPC, in: context)
        } else {
            blog = try? BlogQuery().blogID(site.siteID).username(site.username).blog(in: context)
        }

        return blog
    }
}
