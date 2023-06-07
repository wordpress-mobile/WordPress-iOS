import Foundation

class DashboardActivityLogViewModel {

    // MARK: Private Variables

    private var apiResponse: BlogDashboardRemoteEntity

    // MARK: Initializer

    init(apiResponse: BlogDashboardRemoteEntity) {
        self.apiResponse = apiResponse
    }

    // MARK: Public Variables

    var activitiesToDisplay: [Activity] {
        let uniqueActivities = apiResponse.activity?.value?.current?.orderedItems?.deduplicated() ?? []
        return Array(uniqueActivities.prefix(Constants.maxActivitiesCount))
    }

    private enum Constants {
        static let maxActivitiesCount = 3
    }
}
