import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable {

    var posts: BlogDashboardPosts?
    var todaysStats: BlogDashboardStats?
    var pages: [BlogDashboardPage]?
    var activity: [Activity]?

    struct BlogDashboardPosts: Decodable, Hashable {
        var hasPublished: Bool?
        var draft: [BlogDashboardPost]?
        var scheduled: [BlogDashboardPost]?
        
        enum CodingKeys: String, CodingKey {
            case hasPublished = "has_published"
            case draft
            case scheduled
        }
    }

    // We don't rely on the data from the API to show posts
    struct BlogDashboardPost: Decodable, Hashable { }

    struct BlogDashboardStats: Decodable, Hashable {
        var views: Int?
        var visitors: Int?
        var likes: Int?
        var comments: Int?
    }

    // We don't rely on the data from the API to show pages
    struct BlogDashboardPage: Decodable, Hashable { }

    enum CodingKeys: String, CodingKey {
        case posts
        case todaysStats = "todays_stats"
        case pages
        case activity
    }
}

extension Activity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(activityID)
    }
}
