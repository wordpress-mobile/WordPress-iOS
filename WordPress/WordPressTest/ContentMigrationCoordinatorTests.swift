import XCTest

@testable import WordPress

final class ContentMigrationCoordinatorTests: XCTestCase {

    private let timeout: TimeInterval = 1

    private var mockEligibilityProvider: MockEligibilityProvider!
    private var mockDataMigrator: MockDataMigrator!
    private var mockKeyValueDatabase: EphemeralKeyValueDatabase!
    private var coordinator: ContentMigrationCoordinator!

    override func setUp() {
        super.setUp()

        mockEligibilityProvider = MockEligibilityProvider()
        mockDataMigrator = MockDataMigrator()
        mockKeyValueDatabase = EphemeralKeyValueDatabase()
        coordinator = makeCoordinator()
    }

    override func tearDown() {
        mockEligibilityProvider = nil
        mockDataMigrator = nil
        mockKeyValueDatabase = nil
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

    // MARK: `startOnce` tests

    func test_startOnce_whenUserDefaultsDoesNotExist_shouldMigrate() {
        let expect = expectation(description: "Content migration should succeed")
        coordinator.startOnceIfNeeded { [unowned self] in
            XCTAssertTrue(mockDataMigrator.exportCalled)
            XCTAssertTrue(mockKeyValueDatabase.bool(forKey: userDefaultsKey))
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startOnce_givenErrorResult_shouldNotSaveUserDefaults() {
        mockDataMigrator.exportErrorToReturn = .localDraftsNotSynced

        let expect = expectation(description: "Content migration should succeed")
        coordinator.startOnceIfNeeded { [unowned self] in
            XCTAssertTrue(mockDataMigrator.exportCalled)
            XCTAssertFalse(mockKeyValueDatabase.bool(forKey: userDefaultsKey))
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
    }

    func test_startOnce_whenUserDefaultsExists_shouldNotMigrate() {
        mockKeyValueDatabase.set(true, forKey: userDefaultsKey)

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
        var exportErrorToReturn: DataMigrator.DataMigratorError? = nil
        var exportCalled = false
        var importErrorToReturn: DataMigrator.DataMigratorError? = nil
        var importCalled = false

        func exportData(completion: ((Result<Void, DataMigrator.DataMigratorError>) -> Void)? = nil) {
            exportCalled = true
            guard let exportErrorToReturn else {
                completion?(.success(()))
                return
            }
            completion?(.failure(exportErrorToReturn))
        }

        func importData(completion: ((Result<Void, DataMigrator.DataMigratorError>) -> Void)? = nil) {
            importCalled = true
            guard let importErrorToReturn else {
                completion?(.success(()))
                return
            }
            completion?(.failure(importErrorToReturn))
        }
    }

    func makeCoordinator() -> ContentMigrationCoordinator {
        return .init(dataMigrator: mockDataMigrator,
                     keyValueDatabase: mockKeyValueDatabase,
                     eligibilityProvider: mockEligibilityProvider)
    }

}
