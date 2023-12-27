import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable {

    var posts: FailableDecodable<BlogDashboardPosts>?
    var todaysStats: FailableDecodable<BlogDashboardStats>?
    var pages: FailableDecodable<[BlogDashboardPage]>?
    var activity: FailableDecodable<BlogDashboardActivity>?
    var dynamic: FailableDecodable<[BlogDashboardDynamic]>?

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

    struct BlogDashboardActivity: Decodable, Hashable {
        var current: CurrentActivity?

        struct CurrentActivity: Decodable, Hashable {
            var orderedItems: [Activity]?
        }
    }

    enum CodingKeys: String, CodingKey {
        case posts
        case todaysStats = "todays_stats"
        case pages
        case activity
        case dynamic
    }
}

// MARK: - Dynamic Card

extension BlogDashboardRemoteEntity {

    struct BlogDashboardDynamic: Decodable, Hashable {

        let id: String
        let remoteFeatureFlag: String
        let title: String?
        let featuredImage: String?
        let url: String?
        let action: String?
        let order: Order?
        let rows: [Row]?

        enum Order: String, Decodable {
            case top
            case bottom
        }

        struct Row: Decodable, Hashable {
            let title: String?
            let description: String?
            let icon: String?
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case remoteFeatureFlag = "remote_feature_flag"
            case featuredImage = "featured_image"
            case url
            case action
            case order
            case rows
        }
    }
}

extension Activity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(activityID)
    }
}
