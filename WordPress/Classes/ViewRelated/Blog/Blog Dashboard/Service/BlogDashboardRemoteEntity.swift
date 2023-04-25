import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable {

    var posts: FailableDecodable<BlogDashboardPosts>?
    var todaysStats: FailableDecodable<BlogDashboardStats>?
    var pages: FailableDecodable<[BlogDashboardPage]>?
    var activity: FailableDecodable<[BlogDashboardActivity]>? // FIXME: Replace this after `WordPressKit.Activity` is made Codable

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

    // FIXME: Remove this after `WordPressKit.Activity` is made Codable
    struct BlogDashboardActivity: Decodable, Hashable { }

}
