import Foundation
import CoreData
import WordPressData
@testable import WordPress

public class ModelTestHelper: NSObject {
    @objc
    public class func insertSelfHostedBlog(context: NSManagedObjectContext) -> Blog {
        let blog = Blog.init(context: context)
        blog.url = "http://example.com/"
        blog.xmlrpc = "http://example.com/xmlrpc.php"
        return blog
    }

    @objc
    public class func insertDotComBlog(context: NSManagedObjectContext) -> Blog {
        let blog = Blog.init(context: context)
        blog.url = "https://example.wordpress.com/"
        blog.xmlrpc = "https://example.wordpress.com/xmlrpc.php"
        blog.account = insertAccount(context: context)
        return blog
    }

    @objc
    public class func insertAccount(context: NSManagedObjectContext) -> WPAccount {
        let account = WPAccount.init(context: context)
        account.username = "test_user"
        return account
    }
}
