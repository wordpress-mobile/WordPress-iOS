import XCTest
@testable import WordPress

class BooleanUserDefaultsDebugViewModelTests: CoreDataTestCase {

    var viewModel: BooleanUserDefaultsDebugViewModel!
    var mockPersistentRepository: InMemoryUserDefaults!

    override func setUp() {
        super.setUp()
        mockPersistentRepository = InMemoryUserDefaults()
        viewModel = BooleanUserDefaultsDebugViewModel(coreDataStack: contextManager,
                                                      persistentRepository: mockPersistentRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockPersistentRepository = nil
        super.tearDown()
    }

    func testLoadUserDefaults_WithOtherSection() {
            // Given
            mockPersistentRepository.set(true, forKey: "entry1")

            // When
            viewModel.load()

            // Then
        XCTAssertTrue(viewModel.userDefaultsSections["Other"]?["entry1"]?.value ?? false)
        }

        func testLoadUserDefaults_WithoutOtherSection() {
            // Given
            mockPersistentRepository.set(["entry1": true], forKey: "section1")

            // When
            viewModel.load()

            // Then
            XCTAssertNil(viewModel.userDefaultsSections["Other"])
        }

        func testUserDefaultsSections_MatchingQuery() {
            // Given
            mockPersistentRepository.set(["match": true], forKey: "section1")
            viewModel.load()

            // When
            viewModel.searchQuery = "mat"

            // Then
            XCTAssertNotNil(viewModel.userDefaultsSections["section1"])
            XCTAssertTrue(viewModel.userDefaultsSections["section1"]?["match"]?.value ?? false)
        }

        func testUserDefaultsSections_NotMatchingQuery() {
            // Given
            mockPersistentRepository.set(["entry1": true], forKey: "section1")
            viewModel.load()

            // When
            viewModel.searchQuery = "noMatch"

            // Then
            XCTAssertTrue(viewModel.userDefaultsSections.isEmpty)
        }

        func testUserDefaultsSections_WithFilteredOutNonBooleanEntries() {
            // Given
            mockPersistentRepository.set(["entry1": "NotBoolean"], forKey: "section1")
            mockPersistentRepository.set(["entry2": false], forKey: "section1")

            // When
            viewModel.load()

            // Then
            XCTAssertTrue(viewModel.userDefaultsSections["section1"]?.count == 1)
            XCTAssertFalse(viewModel.userDefaultsSections["section1"]?["entry2"]?.value ?? true)
        }

        func testUserDefaultsSections_WithFilteredOutGutenbergItems() {
            // Given
            mockPersistentRepository.set(true, forKey: "com.wordpress.gutenberg-entry")

            // When
            viewModel.load()

            // Then
            XCTAssertTrue(viewModel.userDefaultsSections.isEmpty)
        }

        func testUserDefaultsSections_WithFilteredOutFeatureFlagSection() {
            // Given
            mockPersistentRepository.set(["entry1": true], forKey: "FeatureFlagStoreCache")

            // When
            viewModel.load()

            // Then
            XCTAssertTrue(viewModel.userDefaultsSections.isEmpty)
        }

        func testUpdateUserDefault_OtherSection() {
            // Given
            mockPersistentRepository.set(true, forKey: "entry1")
            viewModel.load()

            // When
            viewModel.updateUserDefault(false, forSection: "Other", forUserDefault: "entry1")

            // Then
            XCTAssertEqual(viewModel.userDefaultsSections["Other"]?["entry1"]?.value, false)
        }

        func testUpdateUserDefault_GivenSection() {
            // Given
            mockPersistentRepository.set(["entry1": true], forKey: "section1")
            viewModel.load()

            // When
            viewModel.updateUserDefault(false, forSection: "section1", forUserDefault: "entry1")

            // Then
            XCTAssertEqual(viewModel.userDefaultsSections["section1"]?["entry1"]?.value, false)
        }
}
