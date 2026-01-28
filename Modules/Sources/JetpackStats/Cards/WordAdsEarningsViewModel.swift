import Foundation
@preconcurrency import WordPressKit

/// ViewModel managing state for WordAds earnings data.
@MainActor
final class WordAdsEarningsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var earnings: StatsWordAdsEarningsResponse?
    @Published private(set) var isFirstLoad = true
    @Published private(set) var loadingError: Error?

    // MARK: - Dependencies

    private let service: any StatsServiceProtocol

    // MARK: - Initialization

    init(service: any StatsServiceProtocol) {
        self.service = service
    }

    func refresh() async {
        do {
            let response = try await service.getWordAdsEarnings()
            guard !Task.isCancelled else { return }
            self.earnings = response
            self.loadingError = nil
            self.isFirstLoad = false
        } catch {
            guard !Task.isCancelled else { return }
            self.loadingError = error
            self.isFirstLoad = false
        }
    }
}
