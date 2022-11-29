import XCTest

@testable import WordPress

final class ContentMigrationCoordinatorTests: CoreDataTestCase {

    private let timeout: TimeInterval = 1

    private var mockEligibilityProvider: MockEligibilityProvider!
    private var mockDataMigrator: MockDataMigrator!
    private var mockPersistentRepository: InMemoryUserDefaults!
    private var coordinator: ContentMigrationCoordinator!

    override func setUp() {
        super.setUp()

        mockEligibilityProvider = MockEligibilityProvider()
        mockDataMigrator = MockDataMigrator()
        mockPersistentRepository = InMemoryUserDefaults()
        coordinator = makeCoordinator()
    }

    override func tearDown() {
        mockEligibilityProvider = nil
        mockDataMigrator = nil
        mockPersistentRepository = nil
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

            XCTAssertFalse(self.mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startAndDo_givenExportError_shouldInvokeClosureWithError() {
        mockDataMigrator.exportErrorToReturn = .databaseCopyError

        let expect = expectation(description: "Content migration should fail")
        coordinator.startAndDo { _ in
            XCTAssertTrue(self.mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    // MARK: Local draft checking tests

    func test_startAndDo_givenPostWithLocalStatus_shouldReturnFailure() {
        // Given
        makeDraftPost(remoteStatus: .local)
        makeDraftPost(remoteStatus: .sync)

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
        makeDraftPost(remoteStatus: .pushing)
        makeDraftPost(remoteStatus: .sync)

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
        makeDraftPost(remoteStatus: .pushingMedia)
        makeDraftPost(remoteStatus: .sync)

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
        makeDraftPost(remoteStatus: .failed)
        makeDraftPost(remoteStatus: .sync)

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

    // MARK: `startOnce` tests

    func test_startOnce_whenUserDefaultsDoesNotExist_shouldMigrate() {
        let expect = expectation(description: "Content migration should succeed")
        coordinator.startOnceIfNeeded { [unowned self] in
            XCTAssertTrue(mockDataMigrator.exportCalled)
            XCTAssertTrue(mockPersistentRepository.bool(forKey: userDefaultsKey))
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startOnce_givenErrorResult_shouldNotSaveUserDefaults() {
        mockDataMigrator.exportErrorToReturn = .databaseCopyError

        let expect = expectation(description: "Content migration should succeed")
        coordinator.startOnceIfNeeded { [unowned self] in
            XCTAssertTrue(mockDataMigrator.exportCalled)
            XCTAssertFalse(mockPersistentRepository.bool(forKey: userDefaultsKey))
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startOnce_whenUserDefaultsExists_shouldNotMigrate() {
        mockPersistentRepository.set(true, forKey: userDefaultsKey)

        let expect = expectation(description: "Content migration should not be called")
        coordinator.startOnceIfNeeded { [unowned self] in
            XCTAssertFalse(mockDataMigrator.exportCalled)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

}

// MARK: - Helpers

private extension ContentMigrationCoordinatorTests {

    var userDefaultsKey: String {
        "wordpress_one_off_export"
    }

    final class MockEligibilityProvider: ContentMigrationEligibilityProvider {
        var isEligibleForMigration: Bool = true
    }

    final class MockDataMigrator: ContentDataMigrating {
        var exportErrorToReturn: DataMigrationError? = nil
        var exportCalled = false
        var importErrorToReturn: DataMigrationError? = nil
        var importCalled = false

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
    }

    func makeCoordinator() -> ContentMigrationCoordinator {
        return .init(coreDataStack: contextManager,
                     dataMigrator: mockDataMigrator,
                     userPersistentRepository: mockPersistentRepository,
                     eligibilityProvider: mockEligibilityProvider)
    }

    func makeDraftPost(remoteStatus: AbstractPostRemoteStatus = .failed) {
        let _ = PostBuilder(contextManager.mainContext)
            .drafted()
            .with(remoteStatus: remoteStatus)
            .build()
    }

}
