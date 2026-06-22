import Foundation
import CoreData

public extension Blog {
    @NSManaged var authors: Set<BlogAuthor>?

    @objc(addAuthorsObject:)
    @NSManaged func addToAuthors(_ value: BlogAuthor)

    @objc(removeAuthorsObject:)
    @NSManaged func removeFromAuthors(_ value: BlogAuthor)

    @objc(addAuthors:)
    @NSManaged func addToAuthors(_ values: NSSet)

    @objc(removeAuthors:)
    @NSManaged func removeFromAuthors(_ values: NSSet)

    @objc
    func getAuthorWith(id: NSNumber) -> BlogAuthor? {
        return authors?.first(where: { $0.userID == id })
    }

    @objc
    func getAuthorWith(linkedID: NSNumber) -> BlogAuthor? {
        return authors?.first(where: { $0.linkedUserID == linkedID })
    }
}
