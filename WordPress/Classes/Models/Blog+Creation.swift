extension Blog {

    /// Creates a blank `Blog` object
    @objc(createWithAccount:orContext:)
    static func createBlog(with account: WPAccount?, or context: NSManagedObjectContext) -> Blog {
        let blog = createBlog(in: account?.managedObjectContext ?? context)
        blog.account = account
        return blog
    }

    /// Creates a blank `Blog` object for this account
    @objc(createWithAccount:)
    static func createBlog(with account: WPAccount) -> Blog {
        let blog = createBlog(in: account.managedObjectContext!)
        blog.account = account
        return blog
    }

    /// Creates a blank `Blog` object with no account
    @objc(createInContext:)
    static func createBlog(in context: NSManagedObjectContext) -> Blog {
        let blog = Blog(context: context)
        blog.addSettingsIfNecessary()
        return blog
    }

    @objc
    func addSettingsIfNecessary() {
        guard settings == nil else {
            return
        }

        settings = BlogSettings(context: managedObjectContext!)
        settings?.blog = self
    }

}
