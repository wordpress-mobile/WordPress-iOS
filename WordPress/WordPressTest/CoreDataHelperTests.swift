import Foundation
import XCTest
import CoreData

@testable import WordPress


// MARK: - CoreData Helper Tests
//
class CoreDataHelperTests: XCTestCase
{
    var stack: DummyStack!
    var helper: CoreDataHelper<DummyEntity>!


    override func setUp() {
        super.setUp()
        stack = DummyStack()
        helper = CoreDataHelper<DummyEntity>(context: stack.context)
    }

    func testNewFetchRequestReturnsNewRequestWithGenericEntityName() {
        let request = helper.newFetchRequest()
        XCTAssert(request.entityName! == DummyEntity.entityName)
    }

    func testInsertEntityReturnsNewManagedObjectOfTheGenericKind() {
        let entity = helper.insertNewObject()

        // Upcast to AnyObject to make really sure this works
        let anyObject = entity as AnyObject
        XCTAssert(anyObject is DummyEntity)
    }
}



// MARK: - Dummy Sample Entity
//
class DummyEntity: NSManagedObject, ManagedObject
{
    @NSManaged var key: String
    @NSManaged var value: Int

    static let entityName = "SomeRandomEntity"
}


// MARK: - InMemory Stack with Dynamic Model
//
class DummyStack
{
    lazy var model: NSManagedObjectModel = {
        // Attributes
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .StringAttributeType


        let valueAttribute  = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .Integer32AttributeType

        // Entity
        let entity = NSEntityDescription()
        entity.name = DummyEntity.entityName
        entity.managedObjectClassName = String(reflecting: DummyEntity.self)
        entity.properties = [keyAttribute, valueAttribute]

        // Tadaaaa
        let model = NSManagedObjectModel()
        model.entities = [entity]

        return model
    }()


    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        return context
    }()


    lazy var coordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        _ = try? coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: self.storeURL, options: nil)

        return coordinator
    }()

    lazy var storeURL: NSURL = {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
        let foundationPath = documents as NSString
        let dummyStore = foundationPath.stringByAppendingPathComponent("LordYosemite.sqlite")
        return NSURL.fileURLWithPath(dummyStore)
    }()
}
