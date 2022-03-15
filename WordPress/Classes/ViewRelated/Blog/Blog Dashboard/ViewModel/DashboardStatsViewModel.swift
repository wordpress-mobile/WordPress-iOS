import Foundation

class DashboardStatsViewModel {

    // MARK: Variables

    private var apiResponse: BlogDashboardRemoteEntity

    // MARK: Initializer

    init(apiResponse: BlogDashboardRemoteEntity) {
        self.apiResponse = apiResponse
    }

    // MARK: Public Variables

    var todaysViews: String {
        apiResponse.todaysStats?.views?.abbreviatedString(forHeroNumber: true) ?? "0"
    }

    var todaysVisitors: String {
        apiResponse.todaysStats?.visitors?.abbreviatedString(forHeroNumber: true) ?? "0"
    }

    var todaysLikes: String {
        apiResponse.todaysStats?.likes?.abbreviatedString(forHeroNumber: true) ?? "0"
    }
}
