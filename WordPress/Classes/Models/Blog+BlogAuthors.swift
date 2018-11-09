import Foundation
import CoreData


extension Blog {
    @NSManaged public var authors: NSSet?


    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: BlogAuthor)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: BlogAuthor)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)
}
