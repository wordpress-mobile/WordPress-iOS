import Foundation
import CoreData

extension Post {

    @NSManaged var commentCount: NSNumber?
    @NSManaged var geolocation: Coordinate?
    @NSManaged var latitudeID: String?
    @NSManaged var likeCount: NSNumber?
    @NSManaged var longitudeID: String?
    @NSManaged var postFormat: String?
    @NSManaged var postType: String?
    @NSManaged var publicID: String?
    @NSManaged var tags: String?
    @NSManaged var categories: Set<PostCategory>?

    // These were added manually, since the code generator for Swift is not generating them.
    //
    @NSManaged func addCategoriesObject(value: PostCategory)
    @NSManaged func removeCategoriesObject(value: PostCategory)
    @NSManaged func addCategories(values: Set<PostCategory>)
    @NSManaged func removeCategories(values: Set<PostCategory>)
}
