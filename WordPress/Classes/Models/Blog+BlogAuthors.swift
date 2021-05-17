import Foundation
import CoreData


extension Blog {
    @NSManaged public var authors: Set<BlogAuthor>?


    @objc(addAuthorsObject:)
    @NSManaged public func addToAuthors(_ value: BlogAuthor)

    @objc(removeAuthorsObject:)
    @NSManaged public func removeFromAuthors(_ value: BlogAuthor)

    @objc(addAuthors:)
    @NSManaged public func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged public func removeFromAuthors(_ values: NSSet)

    @objc
    func getAuthorWith(id: NSNumber) -> BlogAuthor? {
        return authors?.first(where: { $0.userID == id })
    }

    @objc
    func getAuthorWith(linkedID: NSNumber) -> BlogAuthor? {
        return authors?.first(where: { $0.linkedUserID == linkedID })
    }
}
