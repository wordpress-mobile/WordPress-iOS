import Foundation
import WordPressShared

class DashboardStatsViewModel {

    // MARK: Private Variables

    private var apiResponse: BlogDashboardRemoteEntity

    // MARK: Initializer

    init(apiResponse: BlogDashboardRemoteEntity) {
        self.apiResponse = apiResponse
    }

    // MARK: Public Variables

    var todaysViews: AbbreviatedNumber {
        (apiResponse.todaysStats?.value?.views ?? 0).abbreviated(forHeroNumber: true)
    }

    var todaysVisitors: AbbreviatedNumber {
        (apiResponse.todaysStats?.value?.visitors ?? 0).abbreviated(forHeroNumber: true)
    }

    var todaysLikes: AbbreviatedNumber {
        (apiResponse.todaysStats?.value?.likes ?? 0).abbreviated(forHeroNumber: true)
    }

    var shouldDisplayNudge: Bool {
        guard let todaysStats = apiResponse.todaysStats?.value else {
            return false
        }

        return todaysStats.views == 0 && todaysStats.visitors == 0 && todaysStats.likes == 0
    }
}
