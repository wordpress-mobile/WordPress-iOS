import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable {

    var posts: BlogDashboardPosts?
    var todaysStats: BlogDashboardStats?
    var pages: [BlogDashboardPage]?
    var activity: [Activity]? // FIXME: Replace this after `WordPressKit.Activity` is made Codable

    struct BlogDashboardPosts: Decodable, Hashable {
        var hasPublished: Bool?
        var draft: [BlogDashboardPost]?
        var scheduled: [BlogDashboardPost]?
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

}

extension Activity: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(activityID)
    }
}
