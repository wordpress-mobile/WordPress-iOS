import XCTest
import Combine
@testable import WordPress

private typealias Section = BooleanUserDefaultsDebugViewModel.Section
private typealias Row = BooleanUserDefaultsDebugViewModel.Row

@MainActor final class BooleanUserDefaultsDebugViewModelTests: CoreDataTestCase {

    var viewModel: BooleanUserDefaultsDebugViewModel!
    var mockPersistentRepository: InMemoryUserDefaults!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = .init()
        mockPersistentRepository = InMemoryUserDefaults()
        viewModel = BooleanUserDefaultsDebugViewModel(coreDataStack: contextManager,
                                                      persistentRepository: mockPersistentRepository)
    }

    override func tearDown() {
        viewModel = nil
        mockPersistentRepository = nil
        super.tearDown()
    }

    func testLoadUserDefaults_WithOtherSection() async {
        // Given
        mockPersistentRepository.set(true, forKey: "entry1")

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "Other")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == true)
    }

    func testLoadUserDefaults_WithoutOtherSection() async {
        // Given
        mockPersistentRepository.set(["entry1": true], forKey: "section1")

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == true)
    }

    func testUserDefaultsSections_MatchingQuery() async {
        // Given
        mockPersistentRepository.set(["match": true], forKey: "section1")
        await viewModel.load()

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

    func testUserDefaultsSections_NotMatchingQuery() async {
        // Given
        let expectation = expectation(description: "List should be empty when no matching entries")
        mockPersistentRepository.set(["entry1": true], forKey: "section1")
        await viewModel.load()

        // When
        viewModel.$userDefaultsSections
            .dropFirst()
            .sink { sections in
                XCTAssertTrue(sections.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        viewModel.searchQuery = "noMatch"

        // Then
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testUserDefaultsSections_WithFilteredOutNonBooleanEntries() async {
        // Given
        mockPersistentRepository.set(["entry1": "NotBoolean"], forKey: "section1")
        mockPersistentRepository.set(["entry2": false], forKey: "section1")

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.key == "section1")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.count == 1)
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.key == "entry2")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.title == "entry2")
        XCTAssertTrue(viewModel.userDefaultsSections.first?.rows.first?.value == false)
    }

    func testUserDefaultsSections_WithFilteredOutGutenbergItems() async {
        // Given
        mockPersistentRepository.set(true, forKey: "com.wordpress.gutenberg-entry")

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.isEmpty)
    }

    func testUserDefaultsSections_WithFilteredOutFeatureFlagSection() async {
        // Given
        mockPersistentRepository.set(["entry1": true], forKey: "FeatureFlagStoreCache")

        // When
        await viewModel.load()

        // Then
        XCTAssertTrue(viewModel.userDefaultsSections.isEmpty)
    }

    func testUpdateUserDefault_OtherSection() async {
        // Given
        mockPersistentRepository.set(true, forKey: "entry1")
        await viewModel.load()

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

    func testUpdateUserDefault_GivenSection() async {
        // Given
        mockPersistentRepository.set(["entry1": true], forKey: "section1")
        await viewModel.load()

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
