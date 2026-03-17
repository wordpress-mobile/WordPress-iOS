import Foundation
import Testing
import CoreData

@testable import WordPressData

@Suite @MainActor struct CoreDataHelperTests {
    private let stack = DummyStack()
    private var context: NSManagedObjectContext { stack.context }

    @Test func newFetchRequestReturnsNewRequestWithGenericEntityName() {
        let request = DummyEntity.safeFetchRequest()
        #expect(request.entityName == DummyEntity.entityName())
    }

    @Test func allObjectsReturnsAllOfTheAvailableEntitiesSortedByValue() {
        insertDummyEntities(100)

        let descriptor = NSSortDescriptor(key: "value", ascending: true)
        let all = context.allObjects(ofType: DummyEntity.self, sortedBy: [descriptor])
        #expect(all.count == 100)

        for (index, object) in all.enumerated() {
            #expect(object.value == index)
        }
    }

    @Test func allObjectsMatchingPredicateEffectivelyFiltersEntities() {
        insertDummyEntities(100)

        let minValue = 50
        let maxValue = 59
        let predicate = NSPredicate(format: "value BETWEEN %@", [minValue, maxValue])
        let descriptor = NSSortDescriptor(key: "value", ascending: true)

        let filtered = context.allObjects(ofType: DummyEntity.self, matching: predicate, sortedBy: [descriptor])
        #expect(filtered.count == 10)

        for (index, object) in filtered.enumerated() {
            #expect(object.value == minValue + index)
        }
    }

    @Test func countObjectsReturnsTheRightEntityCount() {
        let expected = 80
        insertDummyEntities(expected)

        let count = context.countObjects(ofType: DummyEntity.self)
        #expect(count == expected)
    }

    @Test func countObjectsReturnsTheRightEntityCountMatchingTheSpecifiedPredicate() {
        let inserted = 42
        let expected = 3
        insertDummyEntities(inserted)

        let predicate = NSPredicate(format: "value BETWEEN %@", [5, 7])
        let retrieved = context.countObjects(ofType: DummyEntity.self, matching: predicate)
        #expect(retrieved == expected)
    }

    @Test func deleteObjectEffectivelyNukesTheObjectFromContext() {
        let count = 30

        insertDummyEntities(count)
        #expect(context.countObjects(ofType: DummyEntity.self) == count)

        let all = context.allObjects(ofType: DummyEntity.self)

        context.deleteObject(all.first!)
        #expect(context.countObjects(ofType: DummyEntity.self) == (count - 1))
    }

    @Test func deleteAllObjectsEffectivelyNukesAllOfTheEntities() {
        let count = 50

        insertDummyEntities(count)

        #expect(context.countObjects(ofType: DummyEntity.self) == count)
        context.deleteAllObjects(ofType: DummyEntity.self)

        #expect(context.countObjects(ofType: DummyEntity.self) == 0)
        #expect(context.allObjects(ofType: DummyEntity.self).count == 0)
    }

    @Test func firstObjectMatchingPredicateReturnsTheExpectedObject() {
        let count = 50
        let targetKey = "5"
        insertDummyEntities(count)

        let predicate = NSPredicate(format: "key == %@", targetKey)
        let retrieved = context.firstObject(ofType: DummyEntity.self, matching: predicate)

        #expect(retrieved != nil)
        #expect(retrieved?.key == targetKey)
    }

    @Test func firstObjectMatchingPredicateReturnsNilIfNothingWasFound() {
        let count = 5
        let targetKey = "50"
        insertDummyEntities(count)

        let predicate = NSPredicate(format: "key == %@", targetKey)
        let retrieved = context.firstObject(ofType: DummyEntity.self, matching: predicate)

        #expect(retrieved == nil)
    }

    @Test func insertEntityReturnsNewManagedObjectOfTheExpectedKind() {
        let entity = context.insertNewObject(ofType: DummyEntity.self)

        let anyObject = entity as AnyObject
        #expect(anyObject is DummyEntity)
    }

    @Test func loadObjectReturnsNilIfTheObjectWasDeleted() throws {
        let entity = context.insertNewObject(ofType: DummyEntity.self)
        let objectID = entity.objectID

        let retrieved = context.loadObject(ofType: DummyEntity.self, with: objectID)
        #expect(retrieved != nil)

        context.deleteObject(entity)
        _ = try? stack.context.save()

        #expect(context.loadObject(ofType: DummyEntity.self, with: objectID) == nil)
    }

    @Test func loadObjectReturnsTheExpectedObject() {
        let entity = context.insertNewObject(ofType: DummyEntity.self)
        entity.key = "YEAH!"
        entity.value = 42

        let objectID = entity.objectID
        let retrieved = context.loadObject(ofType: DummyEntity.self, with: objectID)

        #expect(retrieved != nil)
        #expect(retrieved?.key == "YEAH!")
        #expect(retrieved?.value == 42)
    }

    @Test func safeManagedObjectIDRetrievalUsingURI() throws {
        insertDummyEntities(10)
        let psc = try #require(context.persistentStoreCoordinator)
        let uriGood = try #require(URL(string: "x-coredata://ABDASDBASD/a.png"))
        let uriBad1 = try #require(URL(string: "ABDASDBASD/a.png"))
        let uriBad2 = try #require(URL(string: "x-coredata://ABDASDBASD"))

        #expect(psc.safeManagedObjectID(forURIRepresentation: uriGood) == nil)
        #expect(psc.safeManagedObjectID(forURIRepresentation: uriBad1) == nil)
        #expect(psc.safeManagedObjectID(forURIRepresentation: uriBad2) == nil)
    }

    // MARK: - Testing Helpers

    private func insertDummyEntities(_ count: Int) {
        for i in 0 ..< count {

            let entity = context.insertNewObject(ofType: DummyEntity.self)
            entity.key = "\(i)"
            entity.value = i
        }

        _ = try? stack.context.save()
    }
}

// MARK: - Dummy Sample Entity

class DummyEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var value: Int
}

// MARK: - InMemory Stack with Dynamic Model

class DummyStack {
    // Only one had to exist at a time
    static let model: NSManagedObjectModel = {
        let keyAttribute = NSAttributeDescription()
        keyAttribute.name = "key"
        keyAttribute.attributeType = .stringAttributeType

        let valueAttribute = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .integer64AttributeType

        let entity = NSEntityDescription()
        entity.name = DummyEntity.entityName()
        entity.managedObjectClassName = String(reflecting: DummyEntity.self)
        entity.properties = [keyAttribute, valueAttribute]

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
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: Self.model)
        _ = try? coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        return coordinator
    }()
}
