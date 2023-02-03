import XCTest
@testable import WordPress

class SharedDataIssueSolverTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var contextManager: CoreDataStackMock!
    private var keychainUtils: KeychainUtilsMock!
    private var sharedUserDefaults: InMemoryUserDefaults!
    private var mockLocalStore: MockLocalFileStore!
    private var sharedDataIssueSolver: SharedDataIssueSolver!

    override func setUp() {
        super.setUp()

        context = try! createInMemoryContext()
        contextManager = CoreDataStackMock(mainContext: context)
        keychainUtils = KeychainUtilsMock()
        sharedUserDefaults = InMemoryUserDefaults()
        mockLocalStore = MockLocalFileStore()
        sharedDataIssueSolver = SharedDataIssueSolver(contextManager: contextManager,
                                                      keychainUtils: keychainUtils,
                                                      sharedDefaults: sharedUserDefaults,
                                                      localFileStore: mockLocalStore)
    }

    // MARK: Widget Migration Tests

    func test_widgetMigration_userDefaultsShouldMigrateSuccessfully() {
        // Given
        sharedUserDefaults.set("test1", forKey: "WordPressHomeWidgetsSiteId")
        sharedUserDefaults.set("test2", forKey: "WordPressHomeWidgetsLoggedIn")
        sharedUserDefaults.set("test3", forKey: "WordPressTodayWidgetSiteId")
        sharedUserDefaults.set("test4", forKey: "WordPressTodayWidgetSiteName")
        sharedUserDefaults.set("test5", forKey: "WordPressTodayWidgetSiteUrl")
        sharedUserDefaults.set("test6", forKey: "WordPressTodayWidgetTimeZone")

        // When
        sharedDataIssueSolver.copyTodayWidgetDataToJetpack()

        // Then
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackHomeWidgetsSiteId"), "test1")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackHomeWidgetsLoggedIn"), "test2")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackTodayWidgetSiteId"), "test3")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackTodayWidgetSiteName"), "test4")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackTodayWidgetSiteUrl"), "test5")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JetpackTodayWidgetTimeZone"), "test6")
    }

    func test_widgetMigration_plistFileShouldMigrateSuccessfully() {
        // Given
        let expectedSourceFilename = "HomeWidgetTodayData.plist"
        mockLocalStore.fileShouldExistClosure = { url in
            guard let url else {
                return false
            }
            return url.lastPathComponent == expectedSourceFilename
        }

        // When
        sharedDataIssueSolver.copyTodayWidgetDataToJetpack()

        // Then
        XCTAssertEqual(mockLocalStore.removeItemCallCount, 0)
        XCTAssertEqual(mockLocalStore.copyItemCallCount, 1)
    }

    func test_widgetMigration_whenTargetPlistFileExists_itShouldBeDeletedFirst() {
        // Given
        let expectedSourceFilename = "HomeWidgetTodayData.plist"
        let expectedTargetFilename = "JetpackHomeWidgetTodayData.plist"
        mockLocalStore.fileShouldExistClosure = { url in
            guard let url else {
                return false
            }
            return [expectedSourceFilename, expectedTargetFilename].contains(url.lastPathComponent)
        }

        // When
        sharedDataIssueSolver.copyTodayWidgetDataToJetpack()

        // Then
        // migrator tries to remove any existing item in the target location first.
        XCTAssertEqual(mockLocalStore.removeItemCallCount, 1)
        XCTAssertEqual(mockLocalStore.copyItemCallCount, 1)
    }

    // MARK: Share Extension Migration Tests

    func test_shareExtensionMigration_userDefaultsShouldMigrateSuccessfully() {
        // Given
        sharedUserDefaults.set("test1", forKey: "WPShareUserDefaultsPrimarySiteName")
        sharedUserDefaults.set("test2", forKey: "WPShareUserDefaultsPrimarySiteID")
        sharedUserDefaults.set("test3", forKey: "WPShareUserDefaultsLastUsedSiteName")
        sharedUserDefaults.set("test4", forKey: "WPShareUserDefaultsLastUsedSiteID")
        sharedUserDefaults.set("test5", forKey: "WPShareExtensionMaximumMediaDimensionKey")
        sharedUserDefaults.set("test6", forKey: "WPShareExtensionRecentSitesKey")

        // When
        sharedDataIssueSolver.copyShareExtensionDataToJetpack()

        // Then
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareUserDefaultsPrimarySiteName"), "test1")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareUserDefaultsPrimarySiteID"), "test2")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareUserDefaultsLastUsedSiteName"), "test3")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareUserDefaultsLastUsedSiteID"), "test4")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareExtensionMaximumMediaDimensionKey"), "test5")
        XCTAssertEqual(sharedUserDefaults.string(forKey: "JPShareExtensionRecentSitesKey"), "test6")
    }

}

// MARK: - Helpers

private extension SharedDataIssueSolverTests {
    func createInMemoryContext() throws -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }
}

// MARK: - CoreDataStackMock

private final class CoreDataStackMock: CoreDataStack {
    var mainContext: NSManagedObjectContext

    init(mainContext: NSManagedObjectContext) {
        self.mainContext = mainContext
    }

    func newDerivedContext() -> NSManagedObjectContext {
        return mainContext
    }

    func saveContextAndWait(_ context: NSManagedObjectContext) {}
    func save(_ context: NSManagedObjectContext) {}
    func save(_ context: NSManagedObjectContext, completion completionBlock: (() -> Void)?, on queue: DispatchQueue) {}

    func performAndSave(_ aBlock: @escaping (NSManagedObjectContext) -> Void) {}
    func performAndSave(_ aBlock: @escaping (NSManagedObjectContext) -> Void, completion: (() -> Void)?, on queue: DispatchQueue) {}
}

// MARK: - KeychainUtilsMock

private final class KeychainUtilsMock: KeychainUtils {

    var sourceAccessGroup: String?
    var destinationAccessGroup: String?
    var shouldThrowError = false
    var passwordToReturn: String? = nil
    var storeShouldThrow = false
    var storedPassword: String? = nil
    var storedUsername: String? = nil
    var storedServiceName: String? = nil
    var storedAccessGroup: String? = nil

    override func copyKeychain(from sourceAccessGroup: String?, to destinationAccessGroup: String?, updateExisting: Bool = true) throws {
        if shouldThrowError {
            throw NSError(domain: "", code: 0)
        }

        self.sourceAccessGroup = sourceAccessGroup
        self.destinationAccessGroup = destinationAccessGroup
    }

    override func password(for username: String, serviceName: String, accessGroup: String? = nil) throws -> String? {
        return passwordToReturn
    }

    override func store(username: String, password: String, serviceName: String, accessGroup: String? = nil, updateExisting: Bool) throws {
        if storeShouldThrow {
            throw NSError(domain: "", code: 0)
        }

        storedUsername = username
        storedPassword = password
        storedServiceName = serviceName
        storedAccessGroup = accessGroup
    }

}

// MARK: - Mock Local File Store

private final class MockLocalFileStore: LocalFileStore {
    var fileShouldExistClosure: (URL?) -> Bool = { _ in return false }
    var removeItemCallCount: Int = 0
    var copyItemCallCount: Int = 0

    var removeShouldThrowError: Bool = false
    var copyShouldThrowError: Bool = false

    func fileExists(at url: URL) -> Bool {
        return fileShouldExistClosure(url)
    }

    func save(contents: Data, at url: URL) -> Bool {
        return true
    }

    func containerURL(forAppGroup appGroup: String) -> URL? {
        return URL(string: "/dev/null")
    }

    func removeItem(at url: URL) throws {
        if removeShouldThrowError {
            throw NSError(domain: "", code: 0)
        }
        removeItemCallCount += 1
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        if copyShouldThrowError {
            throw NSError(domain: "", code: 0)
        }
        copyItemCallCount += 1
    }
}
