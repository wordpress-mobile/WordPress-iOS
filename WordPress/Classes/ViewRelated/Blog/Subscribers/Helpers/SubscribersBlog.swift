import Foundation
import WordPressData
import WordPressShared
import WordPressKit

@MainActor
struct SubscribersBlog {
    var dotComSiteID: Int
    var getRestAPI: () -> WordPressComRestApi?

    /// Returns an instance if the blog is eligible to view subscribers.
    init?(blog: Blog) {
        guard let siteID = blog.dotComID else {
            return nil
        }
        self.dotComSiteID = siteID.intValue
        self.getRestAPI = { blog.wordPressComRestApi }
    }

    private init(dotComSiteID: Int, getRestAPI: @escaping () -> WordPressComRestApi?) {
        self.dotComSiteID = dotComSiteID
        self.getRestAPI = getRestAPI
    }

    static func mock() -> SubscribersBlog {
        SubscribersBlog(dotComSiteID: 1, getRestAPI: { nil })
    }

    func makeSubscribersService() throws -> SubscribersServiceRemote {
        guard let api = getRestAPI() else {
            throw URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: SharedStrings.Error.generic])
        }
        return SubscribersServiceRemote(wordPressComRestApi: api)
    }
}
