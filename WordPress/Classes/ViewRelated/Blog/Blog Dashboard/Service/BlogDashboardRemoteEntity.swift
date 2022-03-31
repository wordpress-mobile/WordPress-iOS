import Foundation

struct BlogDashboardRemoteEntity: Decodable {

    var posts: BlogDashboardPosts?
    var todaysStats: BlogDashboardStats?

    struct BlogDashboardPosts: Decodable {
        var hasPublished: Bool?
        var draft: [BlogDashboardPost]?
        var scheduled: [BlogDashboardPost]?

        // We don't rely on the data from the API to show posts
        struct BlogDashboardPost: Decodable { }
    }

    struct BlogDashboardStats: Decodable {
        var views: Int?
        var visitors: Int?
        var likes: Int?
        var comments: Int?
    }

}
