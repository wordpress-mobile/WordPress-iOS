import Foundation

class DashboardStatsViewModel {

    // MARK: Private Variables

    private var apiResponse: BlogDashboardRemoteEntity

    // MARK: Initializer

    init(apiResponse: BlogDashboardRemoteEntity) {
        self.apiResponse = apiResponse
    }

    // MARK: Public Variables

    var todaysViews: String {
        apiResponse.todaysStats?.value?.views?.abbreviatedString(forHeroNumber: true) ?? "0"
    }

    var todaysVisitors: String {
        apiResponse.todaysStats?.value?.visitors?.abbreviatedString(forHeroNumber: true) ?? "0"
    }

    var todaysLikes: String {
        apiResponse.todaysStats?.value?.likes?.abbreviatedString(forHeroNumber: true) ?? "0"
    }

    var shouldDisplayNudge: Bool {
        guard let todaysStats = apiResponse.todaysStats?.value else {
            return false
        }

        return todaysStats.views == 0 && todaysStats.visitors == 0 && todaysStats.likes == 0
    }
}
