extension BlogService {
    static func blog(with site: JetpackSiteRef, context: NSManagedObjectContext = ContextManager.shared.mainContext) -> Blog? {
        let service = BlogService(managedObjectContext: context)
        return service.blog(byBlogId: site.siteID as NSNumber, andUsername: site.username)
    }
}

// MARK: - Jetpack remote install

extension BlogService {
    func installJetpack(url: String,
                        username: String,
                        password: String,
                        completion: @escaping (Bool, JetpackInstallError?) -> Void) {
        let service = BlogServiceRemoteREST(wordPressComRestApi: WordPressComRestApi(), siteID: Constants.defaultSelfHostedBlogId)
        service.installJetpack(url: url, username: username, password: password, completion: completion)
    }

    private enum Constants {
        static let defaultSelfHostedBlogId = NSNumber(value: 0)
    }
}
