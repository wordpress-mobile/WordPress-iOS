import Foundation
import CoreData

class BlogDashboardPostsParser {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func parse(postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {

    }
}
