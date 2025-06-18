import Foundation
import WordPressKit
import WordPressUI

typealias ActivityLogsPaginatedResponse = DataViewPaginatedResponse<ActivityLogRowViewModel, Int>

@MainActor
final class ActivityLogsViewModel: ObservableObject {
    let blog: Blog

    @Published var searchText = ""
    @Published var parameters = GetActivityLogsParameters() {
        didSet {
            response = nil
            onRefreshNeeded()
        }
    }
    @Published var response: ActivityLogsPaginatedResponse?
    @Published var isLoading = false
    @Published var error: Error?

    private var refreshTask: Task<Void, Never>?

    var isFreePlan: Bool {
        blog.isHostedAtWPcom && !blog.hasPaidPlan
    }

    init(blog: Blog) {
        self.blog = blog
    }

    func onAppear() {
        guard response == nil else { return }
        onRefreshNeeded()
    }

    func onRefreshNeeded() {
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
        }
    }

    func refresh() async {
        isLoading = true
        error = nil
        Task {
            do {
                let response = try await makeResponse(searchText: searchText, parameters: parameters)
                guard !Task.isCancelled else { return }
                self.isLoading = false
                self.response = response
            } catch {
                guard !Task.isCancelled else { return }
                self.isLoading = false
                self.error = error
                if response != nil {
                    Notice(error: error).post()
                }
            }
        }
    }

    func search() async throws -> ActivityLogsPaginatedResponse {
        try await makeResponse(searchText: searchText, parameters: parameters)
    }

    func fetchActivityGroups(after: Date? = nil, before: Date? = nil) async throws -> [WordPressKit.ActivityGroup] {
        guard let siteID = blog.dotComID?.intValue,
              let api = blog.wordPressComRestApi else {
            throw NSError(domain: "ActivityLogs", code: 0, userInfo: [NSLocalizedDescriptionKey: "Site ID or API not available"])
        }

        let service = ActivityServiceRemote(wordPressComRestApi: api)
        let groups = try await service.getActivityGroups(
            siteID: siteID,
            after: after,
            before: before
        )
        return groups.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func makeResponse(searchText: String?, parameters: GetActivityLogsParameters) async throws -> ActivityLogsPaginatedResponse {
        try await ActivityLogsPaginatedResponse { [blog] offset in
            guard let siteID = blog.dotComID?.intValue,
                  let api = blog.wordPressComRestApi else {
                throw NSError(domain: "ActivityLogs", code: 0, userInfo: [NSLocalizedDescriptionKey: SharedStrings.Error.generic])
            }
            let service = ActivityServiceRemote(wordPressComRestApi: api)
            let offset = offset ?? 0
            let (activities, hasMore) = try await service.getActivities(
                siteID: siteID,
                offset: offset,
                pageSize: 32,
                searchText: searchText,
                parameters: parameters
            )
            let viewModels = await makeViewModels(for: activities)
            return ActivityLogsPaginatedResponse.Page(
                items: viewModels,
                hasMore: hasMore,
                nextPage: hasMore ? offset + activities.count : nil
            )
        }
    }
}

private func makeViewModels(for activities: [Activity]) async -> [ActivityLogRowViewModel] {
    activities.map(ActivityLogRowViewModel.init)
}

struct GetActivityLogsParameters: Hashable {
    var startDate: Date?
    var endDate: Date?
    var activityTypes: Set<String> = []

    var isEmpty: Bool {
        startDate == nil && endDate == nil && activityTypes.isEmpty
    }
}

private extension ActivityServiceRemote {
    func getActivities(siteID: Int, offset: Int, pageSize: Int, searchText: String? = nil, parameters: GetActivityLogsParameters = .init()) async throws -> ([Activity], hasMore: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            getActivityForSite(
                siteID,
                offset: offset,
                count: pageSize,
                after: parameters.startDate,
                before: parameters.endDate,
                group: Array(parameters.activityTypes),
                searchText: searchText
            ) { activities, hasMore in
                continuation.resume(returning: (activities, hasMore))
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }

    func getActivityGroups(siteID: Int, after: Date? = nil, before: Date? = nil) async throws -> [WordPressKit.ActivityGroup] {
        try await withCheckedThrowingContinuation { continuation in
            getActivityGroupsForSite(
                siteID,
                after: after,
                before: before
            ) { groups in
                continuation.resume(returning: groups)
            } failure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
