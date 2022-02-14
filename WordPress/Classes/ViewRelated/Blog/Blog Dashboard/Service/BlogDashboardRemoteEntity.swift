import Foundation

struct BlogDashboardRemoteEntity: Decodable {

    var posts: BlogDashboardPosts?
    var todaysStats: BlogDashboardStats?

    struct BlogDashboardPosts: Decodable {
        var hasPublished: Bool?
        var draft: [BlogDashboardPosts]?
        var scheduled: [BlogDashboardPosts]?

        // We don't rely on the data from the API to show posts
        struct BlogDashboardPosts: Decodable { }
    }

    struct BlogDashboardStats: Decodable {
        var views: Int?
        var visitors: Int?
        var likes: Int?
        var comments: Int?
    }

}
