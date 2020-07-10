import Foundation
import CoreData

public class ReaderInterest: NSManagedObject {
    convenience init(context: NSManagedObjectContext, from remoteInterest: RemoteReaderInterest) {
        self.init(context: context)
        title = remoteInterest.title
        slug = remoteInterest.slug
    }
}
