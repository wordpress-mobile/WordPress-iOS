import XCTest

@testable import WordPress

final class ContainerContextFactoryTests: XCTestCase {

    private var persistentContainer: NSPersistentContainer!
    private var factory: ContainerContextFactory!

    override func setUp() {
        super.setUp()

        persistentContainer = makeInMemoryContainer()
        factory = ContainerContextFactory(persistentContainer: persistentContainer)
    }

    override func tearDown() {
        persistentContainer = nil
        factory = nil

        super.tearDown()
    }

    // MARK: - `save` Tests

    func test_save_givenMainQueueConcurrencyType_shouldCallPerform() {
        let context = makeMockContext(concurrencyType: .mainQueueConcurrencyType)

        factory.save(context, andWait: false, withCompletionBlock: nil)

        XCTAssertTrue(context.performCalled)
        XCTAssertFalse(context.performAndWaitCalled)
    }

    func test_save_givenMainQueueConcurrencyType_andWaitIsSetToTrue_shouldCallPerformAndWait() {
        let context = makeMockContext(concurrencyType: .mainQueueConcurrencyType)

        factory.save(context, andWait: true, withCompletionBlock: nil)

        XCTAssertFalse(context.performCalled)
        XCTAssertTrue(context.performAndWaitCalled)
    }

    func test_save_givenPrivateQueueConcurrencyType_shouldCallPerform() {
        let context = makeMockContext(concurrencyType: .privateQueueConcurrencyType)

        factory.save(context, andWait: false, withCompletionBlock: nil)

        XCTAssertTrue(context.performCalled)
        XCTAssertFalse(context.performAndWaitCalled)
    }

    func test_save_givenPrivateQueueConcurrencyType_andWaitIsSetToTrue_shouldCallPerformAndWait() {
        let context = makeMockContext(concurrencyType: .privateQueueConcurrencyType)

        factory.save(context, andWait: true, withCompletionBlock: nil)

        XCTAssertFalse(context.performCalled)
        XCTAssertTrue(context.performAndWaitCalled)
    }

    func test_save_givenDeprecatedConcurrencyType_shouldNotCallPerform() {
        /// creates a context with `.confinementConcurrencyType`. The enum is created from its raw value
        /// to prevent Xcode from complaining since the enum value is deprecated.
        let context = makeMockContext(concurrencyType: NSManagedObjectContextConcurrencyType(rawValue: 0)!)

        factory.save(context, andWait: false, withCompletionBlock: nil)

        XCTAssertFalse(context.performCalled)
        XCTAssertFalse(context.performAndWaitCalled)
    }
}

// MARK: - Private Helpers

private extension ContainerContextFactoryTests {

    class MockManagedObjectContext: NSManagedObjectContext {

        var performCalled = false
        var performAndWaitCalled = false

        override func perform(_ block: @escaping () -> Void) {
            performCalled = true
        }

        override func performAndWait(_ block: () -> Void) {
            performAndWaitCalled = true
        }

        override func save() throws {
            // do nothing. let's make sure nothing gets saved.
        }
    }

    /// Creates an "in-memory" NSPersistentContainer.
    /// This follows the approach used in WWDC'18: https://developer.apple.com/videos/play/wwdc2018/224/
    ///
    /// - Returns: An instance of NSPersistentContainer that stores data in memory.
    func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "WordPress")
        let description = NSPersistentStoreDescription(url: .init(fileURLWithPath: "/dev/null"))
        container.persistentStoreDescriptions = [description]

        return container
    }

    func makeMockContext(concurrencyType: NSManagedObjectContextConcurrencyType) -> MockManagedObjectContext {
        return MockManagedObjectContext(concurrencyType: concurrencyType)
    }

}
