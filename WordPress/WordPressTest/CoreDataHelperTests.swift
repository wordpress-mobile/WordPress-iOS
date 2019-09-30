import Foundation
import XCTest
import CoreData

@testable import WordPress


// MARK: - CoreData Helper Tests
//
class CoreDataHelperTests: XCTestCase {
    var stack: DummyStack!
    var context: NSManagedObjectContext {
        return stack.context
    }

    override func setUp() {
        super.setUp()
        stack = DummyStack()
    }


    /// Verifies that newFetchRequest effectively returns a new Request associated to the Stack's
    /// specialized type.
    ///
    func testNewFetchRequestReturnsNewRequestWithGenericEntityName() {
        let request = DummyEntity.safeFetchRequest()
        XCTAssert(request.entityName! == DummyEntity.entityName())
    }

    /// Verifies that allObjects returns all of the entities of the specialized kind.
    ///
    func testAllObjectsReturnsAllOfTheAvableEntitiesSortedByValue() {
        insertDummyEntities(100)

        let descriptor = NSSortDescriptor(key: "value", ascending: true)
        let all = context.allObjects(ofType: DummyEntity.self, sortedBy: [descriptor])
        XCTAssert(all.count == 100)

        for (index, object) in all.enumerated() {
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

        let filtered = context.allObjects(ofType: DummyEntity.self, matching: predicate, sortedBy: [descriptor])
        XCTAssert(filtered.count == 10)

        for (index, object) in filtered.enumerated() {
            XCTAssert(object.value == minValue + index)
        }
    }

    /// Verifies that countObjects returns the expected entity count
    ///
    func testCountObjectsReturnsTheRightEntityCount() {
        let expected = 80
        insertDummyEntities(expected)

        let count = context.countObjects(ofType: DummyEntity.self)
        XCTAssert(count == expected)
    }

    /// Verifies that countObjects returns the expected entity count matching a given predicate
    ///
    func testCountObjectsReturnsTheRightEntityCountMatchingTheSpecifiedPredicate() {
        let inserted = 42
        let expected = 3
        insertDummyEntities(inserted)

        let predicate = NSPredicate(format: "value BETWEEN %@", [5, 7])
        let retrieved = context.countObjects(ofType: DummyEntity.self, matching: predicate)
        XCTAssert(retrieved == expected)
    }

    /// Verifies that deleteObject effectively nukes the object from the context
    ///
    func testDeleteObjectEffectivelyNukesTheObjectFromContext() {
        let count = 30

        insertDummyEntities(count)
        XCTAssert(context.countObjects(ofType: DummyEntity.self) == count)

        let all = context.allObjects(ofType: DummyEntity.self)

        context.deleteObject(all.first!)
        XCTAssert(context.countObjects(ofType: DummyEntity.self) == (count - 1))
    }

    /// Verifies that deleteAllObjects effectively nukes the entire bucket
    ///
    func testDeleteAllObjectsEffectivelyNukesAllOfTheEntities() {
        let count = 50

        insertDummyEntities(count)

        XCTAssert(context.countObjects(ofType: DummyEntity.self) == count)
        context.deleteAllObjects(ofType: DummyEntity.self)

        XCTAssert(context.countObjects(ofType: DummyEntity.self) == 0)
        XCTAssert(context.allObjects(ofType: DummyEntity.self).count == 0)
    }

    /// Verifies that firstObject effectively retrieves a single instance, when applicable
    ///
    func testFirstObjectMatchingPredicateReturnsTheExpectedObject() {
        let count = 50
        let targetKey = "5"
        insertDummyEntities(count)

        let predicate = NSPredicate(format: "key == %@", targetKey)
        let retrieved = context.firstObject(ofType: DummyEntity.self, matching: predicate)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.key, targetKey)
    }

    /// Verifies that firstObject effectively retrieves nil, when applicable
    ///
    func testFirstObjectMatchingPredicateReturnsNilIfNothingWasFound() {
        let count = 5
        let targetKey = "50"
        insertDummyEntities(count)

        let predicate = NSPredicate(format: "key == %@", targetKey)
        let retrieved = context.firstObject(ofType: DummyEntity.self, matching: predicate)

        XCTAssertNil(retrieved)
    }

    /// Verifies that insertNewObject returns a new entity of the specialized kind
    ///
    func testInsertEntityReturnsNewManagedObjectOfTheExpectedKind() {
        let entity = context.insertNewObject(ofType: DummyEntity.self)

        // Upcast to AnyObject to make really sure this works
        let anyObject = entity as AnyObject
        XCTAssert(anyObject is DummyEntity)
    }

    /// Verifies that loadObject returns nil whenever the entity was deleted
    ///
    func testLoadObjectReturnsNilIfTheObjectWasDeleted() {
        let entity = context.insertNewObject(ofType: DummyEntity.self)
        let objectID = entity.objectID

        let retrieved = context.loadObject(ofType: DummyEntity.self, with: objectID)
        XCTAssertNotNil(retrieved)

        context.deleteObject(entity)
        _ = try? stack.context.save()

        XCTAssertNil(context.loadObject(ofType: DummyEntity.self, with: objectID))
    }

    /// Verifies that loadObject retrieves the expected entity
    ///
    func testLoadObjectReturnsTheExpectedObject() {
        let entity = context.insertNewObject(ofType: DummyEntity.self)
        entity.key = "YEAH!"
        entity.value = 42

        let objectID = entity.objectID
        let retrieved = context.loadObject(ofType: DummyEntity.self, with: objectID)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved!.key, "YEAH!")
        XCTAssertEqual(retrieved!.value, 42)
    }

    /// Verifies that safeManagedObjectID never runs into exceptions and always returns nil
    ///
    func testSafeManagedObjectIDRetrievalUsingURI() {
        insertDummyEntities(10)
        guard let psc = context.persistentStoreCoordinator,
            let uriGood = URL(string: "x-coredata://ABDASDBASD/a.png"),
            let uriBad1 = URL(string: "ABDASDBASD/a.png"),
            let uriBad2 = URL(string: "x-coredata://ABDASDBASD") else {
                return
        }


        XCTAssertNil(psc.safeManagedObjectID(forURIRepresentation: uriGood))
        XCTAssertNil(psc.safeManagedObjectID(forURIRepresentation: uriBad1))
        XCTAssertNil(psc.safeManagedObjectID(forURIRepresentation: uriBad2))
    }
}


// MARK: - Testing Helpers
//
extension CoreDataHelperTests {
    func insertDummyEntities(_ count: Int) {
        for i in 0 ..< count {
            let entity = context.insertNewObject(ofType: DummyEntity.self)
            entity.key = "\(i)"
            entity.value = i
        }

        _ = try? stack.context.save()
    }
}


// MARK: - Dummy Sample Entity
//
class DummyEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var value: Int
}


// MARK: - InMemory Stack with Dynamic Model
//
class DummyStack {
    lazy var model: NSManagedObjectModel = {
        // Attributes
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType

        let valueAttribute  = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .integer64AttributeType

        // Entity
        let entity = NSEntityDescription()
        entity.name = DummyEntity.entityName()
        entity.managedObjectClassName = String(reflecting: DummyEntity.self)
        entity.properties = [keyAttribute, valueAttribute]

        // Tadaaaa
        let model = NSManagedObjectModel()
        model.entities = [entity]

        return model
    }()

    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.coordinator
        return context
    }()

    lazy var coordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        _ = try? coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

        return coordinator
    }()
}
