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


    /// Verifies that newFetchRequest effectively returns a new Request associated to the Stack's
    /// specialized type.
    ///
    func testNewFetchRequestReturnsNewRequestWithGenericEntityName() {
        let request = helper.newFetchRequest()
        XCTAssert(request.entityName! == DummyEntity.entityName)
    }

    /// Verifies that allObjects returns all of the entities of the specialized kind.
    ///
    func testAllObjectsReturnsAllOfTheAvailableEntitiesSortedByValue() {
        insertDummyEntities(100)


        let descriptor = NSSortDescriptor(key: "value", ascending: true)
        let all = helper.allObjects(sortedBy: [descriptor])
        XCTAssert(all.count == 100)

        for (index, object) in all.enumerate() {
            XCTAssert(object.value == index)
        }
    }

    /// Verifies that allObjects returns all of the entities of the specialized kind that match a given
    /// predicate.
    ///
    func testAllObjectsMatchingPredicateEffectivelyFiltersEntities() {
        insertDummyEntities(100)

        let minValue = 50
        let maxValue = 59
        let predicate = NSPredicate(format: "value BETWEEN %@", [minValue, maxValue])
        let descriptor = NSSortDescriptor(key: "value", ascending: true)

        let filtered = helper.allObjects(matchingPredicate: predicate, sortedBy: [descriptor])
        XCTAssert(filtered.count == 10)

        for (index, object) in filtered.enumerate() {
            XCTAssert(object.value == minValue + index)
        }
    }

    /// Verifies that countObjects returns the expected entity count
    ///
    func testCountObjectsReturnsTheRightEntityCount() {
        let expected = 80
        insertDummyEntities(expected)

        let count = helper.countObjects()
        XCTAssert(count == expected)
    }

    /// Verifies that countObjects returns the expected entity count matching a given predicate
    ///
    func testCountObjectsReturnsTheRightEntityCountMatchingTheSpecifiedPredicate() {
        let inserted = 42
        let expected = 3
        insertDummyEntities(inserted)

        let predicate = NSPredicate(format: "value BETWEEN %@", [5, 7])
        let retrieved = helper.countObjects(matchingPredicate: predicate)
        XCTAssert(retrieved == expected)
    }

    /// Verifies that deleteObject effectively nukes the object from the context
    ///
    func testDeleteObjectEffectivelyNukesTheObjectFromContext() {
        let count = 30

        insertDummyEntities(count)
        XCTAssert(helper.countObjects() == count)

        let all = helper.allObjects()

        helper.deleteObject(all.first!)
        XCTAssert(helper.countObjects() == (count - 1))
    }

    /// Verifies that deleteAllObjects effectively nukes the entire bucket
    ///
    func testDeleteAllObjectsEffectivelyNukesAllOfTheEntities() {
        let count = 50

        insertDummyEntities(count)

        XCTAssert(helper.countObjects() == count)
        helper.deleteAllObjects()

        XCTAssert(helper.countObjects() == 0)
        XCTAssert(helper.allObjects().count == 0)
    }

    func testFirstObjectMatchingPredicateReturnsTheExpectedObject() {
        
    }

    func testFirstObjectMatchingPredicateReturnsNilIfNothingWasFound() {

    }

    /// Verifies that insertNewObject returns a new entity of the specialized kind
    ///
    func testInsertEntityReturnsNewManagedObjectOfTheExpectedKind() {
        let entity = helper.insertNewObject()

        // Upcast to AnyObject to make really sure this works
        let anyObject = entity as AnyObject
        XCTAssert(anyObject is DummyEntity)
    }

    func testLoadObjectReturnsNilIfTheObjectWasDeleted() {

    }

    func testLoadObjectReturnsTheExpectedObject() {

    }
}


// MARK: - Testing Helpers
//
extension CoreDataHelperTests
{
    func insertDummyEntities(count: Int) {
        for i in 0 ..< count {
            let entity = helper.insertNewObject()
            entity.value = i
        }
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
        valueAttribute.attributeType = .Integer64AttributeType

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
