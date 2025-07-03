import Foundation
import WordPressKit
import WordPressShared

/// Protocol for fetching timezone data
protocol TimeZoneServiceProtocol {
    func timezones() async throws -> [TimeZoneGroup]
}

/// Default implementation using WordPress.com API
struct DefaultTimeZoneService: TimeZoneServiceProtocol {
    func timezones() async throws -> [TimeZoneGroup] {
        let api = WordPressComRestApi.anonymousApi(
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyV2
        )
        let remote = TimeZoneServiceRemote(wordPressComRestApi: api)
        return try await remote.timezones()
    }
}

// MARK: - TimeZoneServiceRemote Extension
private extension TimeZoneServiceRemote {
    func timezones() async throws -> [TimeZoneGroup] {
        try await withCheckedThrowingContinuation { continuation in
            getTimezones(success: { groups in
                continuation.resume(returning: groups)
            }, failure: { error in
                continuation.resume(throwing: error)
            })
        }
    }
}

@MainActor
final class TimeZoneSelectorViewModel: ObservableObject {
    @Published private(set) var sections: [TimeZoneSectionViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var suggestedTimezoneRowViewModel: TimeZoneRowViewModel?

    private let timeZoneFormatter = TimeZoneFormatter(currentDate: Date())
    private let service: TimeZoneServiceProtocol

    init(service: TimeZoneServiceProtocol = DefaultTimeZoneService()) {
        self.service = service
    }

    func loadTimezones() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let groups = try await service.timezones()

            sections = groups.map { group in
                let rowViewModels = group.timezones.map {
                    TimeZoneRowViewModel(timezone: $0, formatter: timeZoneFormatter)
                }
                return TimeZoneSectionViewModel(name: group.name, timezones: rowViewModels)
            }

            // Find and cache the suggested timezone
            updateSuggestions()
        } catch {
            self.error = error
            DDLogError("Error loading timezones: \(error)")
        }

        isLoading = false
    }

    private func updateSuggestions() {
        let deviceIdentifier = TimeZone.current.identifier
        for section in sections {
            if let rowViewModel = section.timezones.first(where: {
                $0.timezone.value.caseInsensitiveCompare(deviceIdentifier) == .orderedSame
            }) {
                suggestedTimezoneRowViewModel = rowViewModel
                return
            }
        }
    }

    func filteredSections(searchText: String) -> [TimeZoneSectionViewModel] {
        guard !searchText.isEmpty else { return sections }

        let search = StringRankedSearch(searchTerm: searchText)

        return sections
            .compactMap { section in
                let matchingViewModels = search.search(
                    in: section.timezones,
                    input: { $0.searchableText }
                )
                guard !matchingViewModels.isEmpty else {
                    return nil
                }
                return TimeZoneSectionViewModel(name: section.name, timezones: matchingViewModels)
            }
    }
}

struct TimeZoneRowViewModel: Identifiable, Equatable {
    let timezone: WPTimeZone
    let offset: String
    let currentTime: String

    var id: String { timezone.value }

    init(timezone: WPTimeZone, formatter: TimeZoneFormatter) {
        self.timezone = timezone
        self.offset = formatter.getZoneOffset(timezone)
        self.currentTime = formatter.getTimeAtZone(timezone)
    }

    var searchableText: String {
        "\(timezone.label) \(timezone.value) \(offset) \(currentTime)"
    }

    static func == (lhs: TimeZoneRowViewModel, rhs: TimeZoneRowViewModel) -> Bool {
        lhs.timezone.value == rhs.timezone.value &&
        lhs.timezone.label == rhs.timezone.label
    }
}

struct TimeZoneSectionViewModel: Identifiable, Equatable {
    let name: String
    let timezones: [TimeZoneRowViewModel]

    var id: String { name }
}
