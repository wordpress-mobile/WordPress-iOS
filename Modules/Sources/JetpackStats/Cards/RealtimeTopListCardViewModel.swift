import SwiftUI

@MainActor
final class RealtimeTopListCardViewModel: ObservableObject {
    @Published var topListData: TopListResponse?
    @Published var isLoading = true
    @Published var loadingError: Error?

    private let service: any StatsServiceProtocol
    private var realtimeTimer: Task<Void, Never>?
    private var currentDataType: TopListItemType?

    var isFirstLoad: Bool { isLoading && topListData == nil }

    init(service: any StatsServiceProtocol) {
        self.service = service
        startRealtimeUpdates()
    }

    deinit {
        realtimeTimer?.cancel()
    }

    func loadData(for dataType: TopListItemType) {
        currentDataType = dataType

        Task {
            await actuallyLoadData(dataType: dataType)
        }
    }

    private func actuallyLoadData(dataType: TopListItemType) async {
        isLoading = true
        loadingError = nil

        do {
            let response = try await service.getRealtimeTopListData(dataType)
            topListData = response
        } catch {
            loadingError = error
            topListData = nil
        }

        isLoading = false
    }

    private func startRealtimeUpdates() {
        realtimeTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self, !Task.isCancelled else { break }

                // Trigger a reload with the current state
                if let dataType = self.currentDataType {
                    await self.actuallyLoadData(dataType: dataType)
                }
            }
        }
    }
}
