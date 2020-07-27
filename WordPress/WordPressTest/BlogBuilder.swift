import Foundation

@testable import WordPress

/// Creates a Blog
///
/// Defaults to creating a self-hosted blog
final class BlogBuilder {
    private let blog: Blog

    private let context: NSManagedObjectContext

    init(_ context: NSManagedObjectContext) {
        self.context = context

        blog = NSEntityDescription.insertNewObject(forEntityName: Blog.entityName(), into: context) as! Blog

        // Non-null properties in Core Data
        blog.dotComID = NSNumber(value: arc4random_uniform(UInt32.max))
        blog.url = "https://example.com"
        blog.xmlrpc = "https://example.com/xmlrpc.php"
    }

    func with(atomic: Bool) -> Self {
        var options = blog.options ?? [AnyHashable: Any]()
        options["is_wpcom_atomic"] = [
            "value": atomic ? 1 : 0
        ]
        blog.options = options

        return self
    }

    func withAnAccount() -> Self {
        // Add Account
        let account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: context) as! WPAccount
        account.displayName = "displayName"
        blog.account = account

        return self
    }

    func build() -> Blog {
        return blog
    }
}

extension Blog {
    func supportsWPComAPI() {
        guard let context = managedObjectContext else {
            return
        }

        let account = NSEntityDescription.insertNewObject(forEntityName: WPAccount.entityName(), into: context) as! WPAccount
        account.username = "foo"
        account.addBlogsObject(self)
    }
}
