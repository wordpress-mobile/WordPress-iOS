import Foundation
import XCTest
@testable import WordPress
@testable import WordPressKit

class TimeZoneSelectorViewModelTests: CoreDataTestCase {

    private var viewModel: TimeZoneSelectorViewModel!

    private var timeZoneGroups: [TimeZoneGroup]!

    override func setUp() {
        super.setUp()

        // Given TimeZoneGroups
        // When new ViewModel created with TimeZoneStore with state=loaded
        loadTimeZoneGroupsIntoViewModel()
    }

    override func tearDown() {
        viewModel = nil
        timeZoneGroups = nil

        super.tearDown()
    }

    func loadTimeZoneGroupsIntoViewModel(selectedValue: String = "", filter: String? = nil) {
        timeZoneGroups = [timeZoneGroup()]

        let loaded = TimeZoneStoreState.loaded(timeZoneGroups)
        viewModel = TimeZoneSelectorViewModel(
                state: TimeZoneSelectorViewModel.State.with(storeState: loaded),
                selectedValue: selectedValue,
                filter: filter)
    }

    func testReady() throws {
        switch viewModel.state {
        case .loading:
            XCTFail()
        case .ready(let groups):
            // Then viewModel should be ready
            XCTAssertEqual(groups.count, timeZoneGroups.count)
        case .error:
            XCTFail()
        }
    }

    func testGroups() {
        // Then viewModel allTimeZonesGroup() count is equal to mock data count
        XCTAssertEqual(viewModel.groups.count, timeZoneGroups.count)
    }

    func testFilteredGroupsExists() {
        // When user types "Addis" which exists
        loadTimeZoneGroupsIntoViewModel(filter: "Addis")

        // Then viewModel filteredGroups should be Addis_Ababa
        let filteredGroups = viewModel.filteredGroups
        XCTAssertEqual(filteredGroups.count, 1)

        let timeZoneGroup: TimeZoneGroup = filteredGroups[0]
        XCTAssertEqual(timeZoneGroup.timezones.count, 1)
        XCTAssertEqual(timeZoneGroup.name, "Africa")

        let timeZone: WPTimeZone = timeZoneGroup.timezones[0]
        XCTAssertEqual(timeZone.label, Constants.timeZoneTestTuple3.label)
        XCTAssertEqual(timeZone.value, Constants.timeZoneTestTuple3.value)
    }

    func testFilteredGroupsDoesNotExist() {
        // When user types an invalid filter
        loadTimeZoneGroupsIntoViewModel(filter: "NoTimeZoneForThisFilter")

        // Then viewModel filteredGroups will be empty
        let filteredGroups = viewModel.filteredGroups
        XCTAssertEqual(filteredGroups.count, 0)
    }

    func testGetTimeZoneForIdentifier() {
        // When TimeZoneIdentifier = "Africa/Addis_Ababa"
        // Then "Africa/Addis_Ababa" WPTimeZone returned
        guard let timeZone = viewModel.getTimeZoneForIdentifier(Constants.timeZoneTestTuple3.value) else {
            XCTFail()
            return
        }

        XCTAssertNotNil(timeZone)
        XCTAssertEqual(timeZone.label, Constants.timeZoneTestTuple3.label)
        XCTAssertEqual(timeZone.value, Constants.timeZoneTestTuple3.value)
    }

    func testTableViewModel() {
        // When viewModel has no selected value
        let immuTable: ImmuTable = viewModel.tableViewModel(selectionHandler: { (selectedTimezone) in
        })

        // Then section count = 1
        let sections = immuTable.sections
        XCTAssertNotNil(sections)
        XCTAssertEqual(sections.count, 1)

        // Then rows count = 3
        let section: ImmuTableSection = sections[0]
        let rows = section.rows
        XCTAssertNotNil(rows)
        XCTAssertEqual(rows.count, 3)
    }

    func testTableViewModelSelectedValue() {
        // When selectedValue = "Africa/Addis_Ababa"
        loadTimeZoneGroupsIntoViewModel(selectedValue: Constants.timeZoneTestTuple3.value)

        // Then selectedValue should be Addis_Ababa
        XCTAssertEqual(viewModel.selectedValue, Constants.timeZoneTestTuple3.value)
    }

    func testNoResultsViewModelLoading() {
        // Given viewModel
        // When loading
        viewModel = TimeZoneSelectorViewModel(
                state: TimeZoneSelectorViewModel.State.with(storeState: TimeZoneStoreState.loading),
                selectedValue: "",
                filter: nil)

        // Then noResultsViewModel exists
        guard let noResultsVCModel: NoResultsViewController.Model = viewModel.noResultsViewModel else {
            XCTFail()
            return
        }

        // Then accessoryView exists
        XCTAssertNotNil(noResultsVCModel.accessoryView)

        // Then noResultsViewModel title is loading
        XCTAssertEqual(noResultsVCModel.titleText, TimeZoneSelectorViewModel.LocalizedText.loadingTitle)
    }

    func testNoResultsViewModelReady() {
        // Given ViewModel
        // When ViewModel state is ready

        // Then noResultsViewModel is nil
        XCTAssertNil(viewModel.noResultsViewModel)
    }

    func testNoResultsViewModelError() {
        // Given ViewModel
        // When ViewModel state is error
        viewModel = TimeZoneSelectorViewModel(
                state: TimeZoneSelectorViewModel.State.with(storeState: TimeZoneStoreState.error(testError())),
                selectedValue: "",
                filter: nil)

        // Then noResultsViewModel exists
        guard let noResultsVCModel: NoResultsViewController.Model = viewModel.noResultsViewModel else {
            XCTFail()
            return
        }

        // Then noResultsViewModel title is No Connection
        XCTAssertEqual(noResultsVCModel.titleText, TimeZoneSelectorViewModel.LocalizedText.noConnectionTitle)
    }

    func timeZoneGroup() -> TimeZoneGroup {
        var zones = [WPTimeZone]()
        zones.append(NamedTimeZone(label: Constants.timeZoneTestTuple1.label, value: Constants.timeZoneTestTuple1.value))
        zones.append(NamedTimeZone(label: Constants.timeZoneTestTuple2.label, value: Constants.timeZoneTestTuple2.value))
        zones.append(NamedTimeZone(label: Constants.timeZoneTestTuple3.label, value: Constants.timeZoneTestTuple3.value))
        return TimeZoneGroup(name: "Africa", timezones: zones)
    }

}

private extension TimeZoneSelectorViewModelTests {
    enum DecodingError: Error {
        case decodingFailed
    }

    enum Constants {
        typealias timeZoneTestTuple = (label: String, value: String)
        static let timeZoneTestTuple1: timeZoneTestTuple = (label: "Abidjan", value: "Africa/Abidjan")
        static let timeZoneTestTuple2: timeZoneTestTuple = (label: "Accra", value: "Africa/Accra")
        static let timeZoneTestTuple3: timeZoneTestTuple = (label: "Addis Ababa", value: "Africa/Addis_Ababa")
    }
}
