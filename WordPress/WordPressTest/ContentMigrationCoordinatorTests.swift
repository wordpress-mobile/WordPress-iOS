import XCTest

@testable import WordPress

final class ContentMigrationCoordinatorTests: CoreDataTestCase {

    private let timeout: TimeInterval = 1

    private var mockEligibilityProvider: MockEligibilityProvider!
    private var mockDataMigrator: MockDataMigrator!
    private var mockNotificationCenter: MockNotificationCenter!
    private var mockPersistentRepository: InMemoryUserDefaults!
    private var mockSharedPersistentRepository: InMemoryUserDefaults!
    private var coordinator: ContentMigrationCoordinator!

    override func setUp() {
        super.setUp()

        mockEligibilityProvider = MockEligibilityProvider()
        mockDataMigrator = MockDataMigrator()
        mockNotificationCenter = MockNotificationCenter()
        mockPersistentRepository = InMemoryUserDefaults()
        mockSharedPersistentRepository = InMemoryUserDefaults()
        coordinator = makeCoordinator()
    }

    override func tearDown() {
        mockEligibilityProvider = nil
        mockDataMigrator = nil
        mockNotificationCenter = nil
        mockPersistentRepository = nil
        mockSharedPersistentRepository = nil
        coordinator = nil

        super.tearDown()
    }

    // MARK: `startAndDo` tests

    func test_startAndDo_givenEligibleAccount_shouldMigrateContent() {
        let expect = expectation(description: "Content migration should succeed")
        coordinator.startAndDo { result in
            guard case .success = result else {
                XCTFail()
                return
            }

            XCTAssertNil(self.coordinator.previousMigrationError)
            XCTAssertTrue(self.mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_whenAccountNotEligible_shouldNotMigrateContent() {
        mockEligibilityProvider.isEligibleForMigration = false

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure = result else {
                XCTFail()
                return
            }

            XCTAssertNotNil(self.coordinator.previousMigrationError)
            XCTAssertFalse(self.mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenExportError_shouldInvokeClosureWithError() {
        let error: DataMigrationError = .databaseExportError(underlyingError: ContextManager.ContextManagerError.missingCoordinatorOrStore)
        mockDataMigrator.exportErrorToReturn = error

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            XCTAssertNotNil(self.coordinator.previousMigrationError)
            XCTAssertEqual(error, .exportFailure)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenExistingError_andSubsequentExportSucceeds_shouldClearStoredError() {
        // Given
        mockSharedPersistentRepository.set("ineligible", forKey: exportFailureSharedKey)

        // When
        let expect = expectation(description: "Content migration should succeed")
        coordinator.startAndDo { result in
            guard case .success = result else {
                XCTFail()
                return
            }

            // Then
            XCTAssertNil(self.coordinator.previousMigrationError)
            XCTAssertTrue(self.mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    // MARK: Local draft checking tests

    func test_startAndDo_givenPostWithLocalStatus_shouldReturnFailure() {
        // Given
        makePost(remoteStatus: .local)
        makePost(remoteStatus: .sync)

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(error, .localDraftsNotSynced)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenPostWithPushingStatus_shouldReturnFailure() {
        // Given
        makePost(remoteStatus: .pushing)
        makePost(remoteStatus: .sync)

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(error, .localDraftsNotSynced)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenPostWithPushingMediaStatus_shouldReturnFailure() {
        // Given
        makePost(remoteStatus: .pushingMedia)
        makePost(remoteStatus: .sync)

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(error, .localDraftsNotSynced)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenPostWithFailedStatus_shouldReturnFailure() {
        // Given
        makePost(remoteStatus: .failed)
        makePost(remoteStatus: .sync)

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { result in
            guard case .failure(let error) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(error, .localDraftsNotSynced)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    // MARK: Export data cleanup tests

    func test_cleanupExportedData_givenUserIsIneligible_shouldDeleteData() {
        // Given
        mockEligibilityProvider.isEligibleForMigration = false

        // When
        coordinator.cleanupExportedDataIfNeeded()

        // Then
        XCTAssertTrue(mockDataMigrator.deleteExportedDataCalled)
    }

    func test_cleanupExportedData_givenUserIsEligible_shouldExportData() {
        // When
        coordinator.cleanupExportedDataIfNeeded()

        // Then
        XCTAssertTrue(mockDataMigrator.exportCalled)
    }

    func test_coordinatorShouldObserveLogoutNotifications() {
        XCTAssertNotNil(mockNotificationCenter.observerSelector)
        XCTAssertNotNil(mockNotificationCenter.observedNotificationName)
        XCTAssertEqual(mockNotificationCenter.observedNotificationName, Foundation.Notification.Name.WPAccountDefaultWordPressComAccountChanged)
    }

    func test_givenLoginNotifications_coordinatorShouldDoNothing() {
        // Given
        let loginNotification = mockNotificationCenter.makeLoginNotification()

        // When
        mockNotificationCenter.post(loginNotification)

        // Then
        XCTAssertFalse(mockDataMigrator.exportCalled)
        XCTAssertFalse(mockDataMigrator.deleteExportedDataCalled)
    }

    func test_givenLogoutNotifications_coordinatorShouldPerformCleanup() {
        // Given
        mockEligibilityProvider.isEligibleForMigration = false
        let logoutNotification = mockNotificationCenter.makeLogoutNotification()

        // When
        mockNotificationCenter.post(logoutNotification)

        // Then
        XCTAssertFalse(mockDataMigrator.exportCalled)
        XCTAssertTrue(mockDataMigrator.deleteExportedDataCalled)
    }
}

// MARK: - Helpers

private extension ContentMigrationCoordinatorTests {

    var userDefaultsKey: String {
        "wordpress_one_off_export"
    }

    var exportFailureSharedKey: String {
        "wordpress_shared_export_error"
    }

    final class MockEligibilityProvider: ContentMigrationEligibilityProvider {
        var isEligibleForMigration = true
    }

    final class MockDataMigrator: ContentDataMigrating {
        var exportErrorToReturn: DataMigrationError? = nil
        var exportCalled = false
        var importErrorToReturn: DataMigrationError? = nil
        var importCalled = false
        var deleteExportedDataCalled = false

        func exportData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
            exportCalled = true
            guard let exportErrorToReturn else {
                completion?(.success(()))
                return
            }
            completion?(.failure(exportErrorToReturn))
        }

        func importData(completion: ((Result<Void, DataMigrationError>) -> Void)? = nil) {
            importCalled = true
            guard let importErrorToReturn else {
                completion?(.success(()))
                return
            }
            completion?(.failure(importErrorToReturn))
        }

        func deleteExportedData() {
            deleteExportedDataCalled = true
        }
    }

    func makeCoordinator() -> ContentMigrationCoordinator {
        return .init(coreDataStack: contextManager,
                     dataMigrator: mockDataMigrator,
                     notificationCenter: mockNotificationCenter,
                     userPersistentRepository: mockPersistentRepository,
                     sharedPersistentRepository: mockSharedPersistentRepository,
                     eligibilityProvider: mockEligibilityProvider)
    }

    func makePost(remoteStatus: AbstractPostRemoteStatus = .failed) {
        let _ = PostBuilder(contextManager.mainContext)
            .published()
            .with(remoteStatus: remoteStatus)
            .build()
    }

}

private final class MockNotificationCenter: NotificationCenter {
    var observedNotificationName: NSNotification.Name? = nil
    var observerSelector: Selector? = nil

    override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        observedNotificationName = aName
        observerSelector = aSelector
        super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
    }

    func makeLoginNotification() -> Foundation.Notification {
        return Foundation.Notification(name: .WPAccountDefaultWordPressComAccountChanged, object: String())
    }

    func makeLogoutNotification() -> Foundation.Notification {
        return Foundation.Notification(name: .WPAccountDefaultWordPressComAccountChanged, object: nil)
    }
}
