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
        return AccountBuilder(context)
            .with(username: "test_user") // necessary for some tests to pass
            .build()
    }
}
