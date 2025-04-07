extension Blog {

    /// Creates a blank `Blog` object for this account
    @objc(createBlankBlogWithAccount:)
    public static func createBlankBlog(with account: WPAccount) -> Blog {
        let blog = createBlankBlog(in: account.managedObjectContext!)
        blog.account = account
        return blog
    }

    /// Creates a blank `Blog` object with no account
    @objc(createBlankBlogInContext:)
    public static func createBlankBlog(in context: NSManagedObjectContext) -> Blog {
        let blog = Blog(context: context)
        blog.addSettingsIfNecessary()
        return blog
    }

    @objc
    public func addSettingsIfNecessary() {
        guard settings == nil else {
            return
        }

        settings = BlogSettings(context: managedObjectContext!)
        settings?.blog = self
    }

}
