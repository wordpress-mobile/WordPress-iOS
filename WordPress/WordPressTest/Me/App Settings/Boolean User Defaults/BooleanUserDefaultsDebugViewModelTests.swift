import XCTest
@testable import WordPress

private typealias Section = BooleanUserDefaultsDebugViewModel.Section
private typealias Row = BooleanUserDefaultsDebugViewModel.Row

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
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "Other")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == true)
    }

    func testLoadUserDefaults_WithoutOtherSection() {
        // Given
        mockPersistentRepository.set(["entry1": true], forKey: "section1")

        // When
        viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == true)
    }

    func testUserDefaultsSections_MatchingQuery() {
        // Given
        mockPersistentRepository.set(["match": true], forKey: "section1")
        viewModel.load()

        // When
        viewModel.searchQuery = "mat"

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "match")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "match")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == true)
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
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry2")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry2")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == false)
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
        let section = viewModel.userDefaultsSections[0]
        let row = section.rows[0]
        viewModel.updateUserDefault(false, section: section, row: row)

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "Other")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == false)
    }

    func testUpdateUserDefault_GivenSection() {
        // Given
        mockPersistentRepository.set(["entry1": true], forKey: "section1")
        viewModel.load()

        // When
        let section = viewModel.userDefaultsSections[0]
        let row = section.rows[0]
        viewModel.updateUserDefault(false, section: section, row: row)

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == false)
    }
}
