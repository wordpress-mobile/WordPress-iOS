import Foundation
import WordPressKit
import WordPressUI
import WordPressShared
import WordPressData

typealias ActivityLogsPaginatedResponse = DataViewPaginatedResponse<ActivityLogRowViewModel, Int>

@MainActor
final class ActivityLogsViewModel: ObservableObject {
    let blog: Blog
    let isBackupMode: Bool
    let backupTracker: DownloadableBackupTracker?

    @Published var searchText = ""
    @Published var parameters = GetActivityLogsParameters() {
        didSet {
            trackParameterChanges(oldValue: oldValue, newValue: parameters)
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

    init(blog: Blog, isBackupMode: Bool = false) {
        self.blog = blog
        self.isBackupMode = isBackupMode
        self.backupTracker = isBackupMode ? DownloadableBackupTracker(blog: blog) : nil
    }

    func onAppear() {
        backupTracker?.startTracking()

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

        backupTracker?.refreshBackupStatus()

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

    func onDisappear() {
        backupTracker?.stopTracking()
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
        try await ActivityLogsPaginatedResponse { [blog, isBackupMode] offset in
            guard let siteID = blog.dotComID?.intValue,
                  let api = blog.wordPressComRestApi else {
                throw NSError(domain: "ActivityLogs", code: 0, userInfo: [NSLocalizedDescriptionKey: SharedStrings.Error.generic])
            }
            let service = ActivityServiceRemote(wordPressComRestApi: api)
            let offset = offset ?? 0
            let pageSize = 32

            let (activities, hasMore) = try await service.getActivities(
                siteID: siteID,
                offset: offset,
                pageSize: pageSize,
                searchText: searchText,
                parameters: parameters,
                rewindable: isBackupMode ? true : nil
            )
            let viewModels = await makeViewModels(for: activities)
            return ActivityLogsPaginatedResponse.Page(
                items: viewModels,
                hasMore: hasMore,
                nextPage: hasMore ? offset + activities.count : nil
            )
        }
    }

    // MARK: - Analytics

    private func trackParameterChanges(oldValue: GetActivityLogsParameters, newValue: GetActivityLogsParameters) {
        // Track date range changes
        if oldValue.startDate != newValue.startDate || oldValue.endDate != newValue.endDate {
            if newValue.startDate != nil || newValue.endDate != nil {
                WPAnalytics.track(.activitylogFilterbarSelectRange)
            }
        }

        // Track activity type changes
        if oldValue.activityTypes != newValue.activityTypes {
            if newValue.activityTypes.isEmpty {
                WPAnalytics.track(.activitylogFilterbarResetType)
            } else {
                WPAnalytics.track(.activitylogFilterbarSelectType, properties: ["count": newValue.activityTypes.count])
            }
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
    func getActivities(siteID: Int, offset: Int, pageSize: Int, searchText: String? = nil, parameters: GetActivityLogsParameters = .init(), rewindable: Bool? = nil) async throws -> ([Activity], hasMore: Bool) {
        return try await withCheckedThrowingContinuation { continuation in
            getActivityForSite(
                siteID,
                offset: offset,
                count: pageSize,
                after: parameters.startDate,
                before: parameters.endDate,
                group: Array(parameters.activityTypes),
                rewindable: rewindable,
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
