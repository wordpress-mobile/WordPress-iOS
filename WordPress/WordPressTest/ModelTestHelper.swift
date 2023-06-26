import Foundation
import CoreData

class ModelTestHelper: NSObject {
    @objc
    class func insertSelfHostedBlog(context: NSManagedObjectContext) -> Blog {
        return BlogBuilder(context).build()
    }

    @objc
    class func insertDotComBlog(context: NSManagedObjectContext) -> Blog {
        return BlogBuilder(context)
            .with(url: "https://example.wordpress.com/")
            .withAnAccount()
            .build()
    }

    @objc
    class func insertAccount(context: NSManagedObjectContext) -> WPAccount {
        let account = WPAccount.init(context: context)
        account.username = "test_user"
        return account
    }
}
