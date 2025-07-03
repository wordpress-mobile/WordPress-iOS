import Testing
import Foundation
import WordPressKit

@testable import WordPress

@MainActor
struct TimeZoneSelectorViewModelTests {
    @Test func initAndCheckInitialState() async {
        let service = MockTimeZoneService()
        let viewModel = TimeZoneSelectorViewModel(service: service)

        #expect(viewModel.sections.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test func filteredSectionsWithEmptySearchText() async {
        let mockGroups = createMockTimeZoneGroups()
        let service = MockTimeZoneService(timeZoneGroups: mockGroups)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        await viewModel.loadTimezones()

        let filtered = viewModel.filteredSections(searchText: "")

        #expect(filtered.count == viewModel.sections.count)
        #expect(filtered == viewModel.sections)
    }

    @Test func filteredSectionsWithMatchingSearchText() async {
        let mockGroups = createMockTimeZoneGroups()
        let service = MockTimeZoneService(timeZoneGroups: mockGroups)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        await viewModel.loadTimezones()

        let filtered = viewModel.filteredSections(searchText: "Addis")

        #expect(filtered.count == 1)
        #expect(filtered[0].name == "Africa")
        #expect(filtered[0].timezones.count == 1)
        #expect(filtered[0].timezones[0].timezone.label == "Addis Ababa")
    }

    @Test func filteredSectionsWithNonMatchingSearchText() async {
        let mockGroups = createMockTimeZoneGroups()
        let service = MockTimeZoneService(timeZoneGroups: mockGroups)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        await viewModel.loadTimezones()

        let filtered = viewModel.filteredSections(searchText: "NoTimeZoneForThisFilter")

        #expect(filtered.isEmpty)
    }

    @Test func loadTimezonesSuccess() async {
        // Create mock data
        let mockGroups = [
            TimeZoneGroup(name: "Africa", timezones: [
                NamedTimeZone(label: "Abidjan", value: "Africa/Abidjan"),
                NamedTimeZone(label: "Accra", value: "Africa/Accra")
            ]),
            TimeZoneGroup(name: "America", timezones: [
                NamedTimeZone(label: "New York", value: "America/New_York")
            ])
        ]

        let service = MockTimeZoneService(timeZoneGroups: mockGroups)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        #expect(viewModel.sections.isEmpty)
        #expect(!viewModel.isLoading)

        await viewModel.loadTimezones()

        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(viewModel.sections.count == 2)
        #expect(viewModel.sections[0].name == "Africa")
        #expect(viewModel.sections[0].timezones.count == 2)
        #expect(viewModel.sections[1].name == "America")
        #expect(viewModel.sections[1].timezones.count == 1)
    }

    @Test func loadTimezonesError() async {
        let service = MockTimeZoneService(shouldThrowError: true)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        #expect(viewModel.error == nil)
        #expect(!viewModel.isLoading)

        await viewModel.loadTimezones()

        #expect(!viewModel.isLoading)
        #expect(viewModel.error != nil)
        #expect(viewModel.sections.isEmpty)
    }

    @Test func loadTimezonesUpdatesSuggestion() async {
        // Mock timezone groups containing device's current timezone
        let deviceTimezone = TimeZone.current.identifier
        let mockGroups = [
            TimeZoneGroup(name: "Test", timezones: [
                NamedTimeZone(label: "Test Zone", value: deviceTimezone)
            ])
        ]

        let service = MockTimeZoneService(timeZoneGroups: mockGroups)
        let viewModel = TimeZoneSelectorViewModel(service: service)

        #expect(viewModel.suggestedTimezoneRowViewModel == nil)

        await viewModel.loadTimezones()

        #expect(viewModel.suggestedTimezoneRowViewModel != nil)
        #expect(viewModel.suggestedTimezoneRowViewModel?.timezone.value.caseInsensitiveCompare(deviceTimezone) == .orderedSame)
    }

    // MARK: - Helpers

    private func createMockTimeZoneGroups() -> [TimeZoneGroup] {
        [
            TimeZoneGroup(name: "Africa", timezones: [
                NamedTimeZone(label: "Abidjan", value: "Africa/Abidjan"),
                NamedTimeZone(label: "Accra", value: "Africa/Accra"),
                NamedTimeZone(label: "Addis Ababa", value: "Africa/Addis_Ababa")
            ]),
            TimeZoneGroup(name: "America", timezones: [
                NamedTimeZone(label: "New York", value: "America/New_York"),
                NamedTimeZone(label: "Los Angeles", value: "America/Los_Angeles")
            ])
        ]
    }
}

private struct MockTimeZoneService: TimeZoneServiceProtocol {
    var shouldThrowError = false
    var timeZoneGroups: [TimeZoneGroup] = []

    func timezones() async throws -> [TimeZoneGroup] {
        if shouldThrowError {
            throw MockError.testError
        }
        return timeZoneGroups
    }

    enum MockError: Error {
        case testError
    }
}
