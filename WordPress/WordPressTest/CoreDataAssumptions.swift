import XCTest
import Nimble
@testable import WordPress

/*
Usually, you should only test your code and not the system frameworks.

But when you rely on certain behavior that it's either undocumented, or the
documentation doesn't clearly guarantee, it's good to be notified when that
behavior changes.
*/
class CoreDataAssumptions: XCTestCase {

    func testOptionalStringNilOnCreation() {
        let blog = createBlog()
        expect(blog.name).to(beNil())
    }

    func testNonOptionalStringIsEmptyOnCreation() {
        let category = createCategory()
        expect(category.name).to(equal(""))
    }

    func testOptionalNumberIsNilOnCreation() {
        let category = createCategory()
        expect(category.parentID).to(beNil())
    }

    func testNonOptionalNumberIsNilOnCreation() {
        let blog = createBlog()
        expect(blog.blogID).to(beNil())
    }

    func testNonOptionalCanCastToOptional() {
        let blog = createBlog()
        let optionalID = blog.blogID as NSNumber?
        expect(optionalID).to(beNil())
    }

    func testOptionalRelationshipIsEmptySetOnCreation() {
        let blog = createBlog()
        expect(blog.categories).toNot(beNil())
        expect(blog.categories).to(beEmpty())
    }

    class TestBlog: NSManagedObject {
        @NSManaged var blogID: NSNumber
        @NSManaged var name: String?
        @NSManaged var categories: Set<TestCategory>
    }

    class TestCategory: NSManagedObject {
        @NSManaged var categoryID: NSNumber
        @NSManaged var name: String
        @NSManaged var parentID: NSNumber?
        @NSManaged var blog: TestBlog
    }

    private func createBlog() -> TestBlog {
        let context = createManagedObjectContext()
        let blog = NSEntityDescription.insertNewObjectForEntityForName("TestBlog", inManagedObjectContext: context) as! TestBlog
        return blog
    }

    private func createCategory() -> TestCategory {
        let context = createManagedObjectContext()
        let category = NSEntityDescription.insertNewObjectForEntityForName("TestCategory", inManagedObjectContext: context) as! TestCategory
        return category
    }

    private func createManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStore()
        return context
    }

    private func persistentStore() -> NSPersistentStoreCoordinator {
        let store = NSPersistentStoreCoordinator(managedObjectModel: managedModel())
        try! store.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        return store
    }

    private func managedModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let blogEntity = NSEntityDescription()
        blogEntity.name = "TestBlog"
        blogEntity.managedObjectClassName = NSStringFromClass(TestBlog.self)

        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "TestCategory"
        categoryEntity.managedObjectClassName = NSStringFromClass(TestCategory.self)

        let blogID = NSAttributeDescription()
        blogID.name = "blogID"
        blogID.attributeType = .Integer64AttributeType
        blogID.optional = false

        let blogName = NSAttributeDescription()
        blogName.name = "name"
        blogName.attributeType = .StringAttributeType
        blogName.optional = true

        let categoryID = NSAttributeDescription()
        categoryID.name = "categoryID"
        categoryID.attributeType = .Integer64AttributeType
        categoryID.optional = false

        let categoryName = NSAttributeDescription()
        categoryName.name = "name"
        categoryName.attributeType = .StringAttributeType
        categoryName.optional = false

        let categoryParent = NSAttributeDescription()
        categoryParent.name = "parentID"
        categoryParent.attributeType = .Integer64AttributeType
        categoryParent.optional = true

        let blogCategories = NSRelationshipDescription()
        let categoryBlog = NSRelationshipDescription()
        blogCategories.name = "categories"
        blogCategories.destinationEntity = categoryEntity
        blogCategories.deleteRule = .CascadeDeleteRule
        blogCategories.inverseRelationship = categoryBlog
        categoryBlog.name = "blog"
        categoryBlog.destinationEntity = blogEntity
        categoryBlog.deleteRule = .NullifyDeleteRule
        categoryBlog.minCount = 1
        categoryBlog.maxCount = 1
        categoryBlog.optional = false
        categoryBlog.inverseRelationship = blogCategories

        blogEntity.properties = [blogID, blogName, blogCategories]
        categoryEntity.properties = [categoryID, categoryName, categoryParent, categoryBlog]

        model.entities = [blogEntity, categoryEntity]
        return model
    }
}
