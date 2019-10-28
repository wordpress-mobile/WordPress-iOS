import Foundation

@testable import WordPress

final class BlogBuilder {
    private let blog: Blog

    init(_ context: NSManagedObjectContext) {
        blog = NSEntityDescription.insertNewObject(forEntityName: Blog.entityName(), into: context) as! Blog

        // Non-null properties in Core Data
        blog.dotComID = NSNumber(value: arc4random_uniform(UInt32.max))
        blog.url = "https://example.com"
        blog.xmlrpc = "https://example.com/xmlrpc.php"
    }

    func build() -> Blog {
        return blog
    }
}
