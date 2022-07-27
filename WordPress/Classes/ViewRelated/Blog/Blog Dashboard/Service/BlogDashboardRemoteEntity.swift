import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable {

    var posts: BlogDashboardPosts?
    var todaysStats: BlogDashboardStats?

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

}
