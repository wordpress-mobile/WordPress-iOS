import Foundation
import Combine
import WordPressKit

struct StatsSubscribersStore {
    enum State<Value: Equatable>: Equatable {
        case idle
        case loading
        case success(Value)
        case error
    }

    private let statsService: StatsServiceRemoteV2 = {
        let siteID = SiteStatsInformation.sharedInstance.siteID?.intValue ?? 0
        let timeZone = SiteStatsInformation.sharedInstance.siteTimeZone ?? .current
        let wpApi = WordPressComRestApi.defaultApi(oAuthToken: SiteStatsInformation.sharedInstance.oauth2Token, userAgent: WPUserAgent.wordPress())
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: timeZone)
    }()

    var emailsSummary: CurrentValueSubject<State<StatsEmailsSummaryData>, Never> = .init(.idle)

    func updateEmailsSummary() {
        guard emailsSummary.value != .loading else { return }

        emailsSummary.send(.loading)
        statsService.getData(quantity: 10, sortField: .postId, sortOrder: .descending) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.emailsSummary.send(.success(data))
                case .failure:
                    self.emailsSummary.send(.error)
                }
            }
        }
    }
}
