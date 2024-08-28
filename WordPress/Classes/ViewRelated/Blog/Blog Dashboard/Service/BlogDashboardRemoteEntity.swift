import Foundation

struct BlogDashboardRemoteEntity: Decodable, Hashable, Sendable {

    let posts: FailableDecodable<BlogDashboardPosts>?
    let todaysStats: FailableDecodable<BlogDashboardStats>?
    let pages: FailableDecodable<[BlogDashboardPage]>?
    let activity: FailableDecodable<BlogDashboardActivity>?
    let dynamic: FailableDecodable<[BlogDashboardDynamic]>?

    struct BlogDashboardPosts: Decodable, Hashable, Sendable {
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
    struct BlogDashboardPost: Decodable, Hashable, Sendable { }

    struct BlogDashboardStats: Decodable, Hashable, Sendable {
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

    struct BlogDashboardDynamic: Decodable, Hashable, Sendable {

        let id: String
        let title: String?
        let featuredImage: String?
        let featuredImageSize: ImageSize?
        let url: String?
        let action: String?
        let order: Order?
        let rows: [Row]?

        enum Order: String, Decodable, Sendable {
            case top
            case bottom
        }

        struct Row: Decodable, Hashable, Sendable {
            let title: String?
            let description: String?
            let icon: String?
        }

        struct ImageSize: Decodable, Hashable, Sendable {
            let width: Int?
            let height: Int?

            var widthToHeightRatio: CGFloat? {
                guard let width, let height else {
                    return nil
                }
                return CGFloat(width) / CGFloat(height)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case featuredImage = "featured_image"
            case featuredImageSize = "featured_image_size"
            case url
            case action
            case order
            case rows
        }
    }
}

extension Activity: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(activityID)
    }
}
