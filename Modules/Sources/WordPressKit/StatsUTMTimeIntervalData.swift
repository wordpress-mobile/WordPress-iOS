import Foundation

public struct StatsUTMTimeIntervalData: Decodable {
    public let utmMetrics: [StatsUTMMetric]

    enum CodingKeys: String, CodingKey {
        case topUTMValues = "top_utm_values"
        case topPosts = "top_posts"
    }

    public init(utmMetrics: [StatsUTMMetric]) {
        self.utmMetrics = utmMetrics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode top UTM values (backend may return [] instead of {} when empty)
        let topUTMValues: [String: Int]
        if let dict = try? container.decode([String: Int].self, forKey: .topUTMValues) {
            topUTMValues = dict
        } else if let array = try? container.decode([Int].self, forKey: .topUTMValues), array.isEmpty {
            // Backend returned empty array instead of empty dict
            topUTMValues = [:]
        } else {
            throw DecodingError.typeMismatch(
                [String: Int].self,
                DecodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.topUTMValues],
                    debugDescription: "Expected dictionary or empty array for top_utm_values"
                )
            )
        }

        // Decode top posts (backend may return [] instead of {} when empty)
        let topPosts: [String: [UTMPost]]
        if let dict = try? container.decode([String: [UTMPost]].self, forKey: .topPosts) {
            topPosts = dict
        } else if let array = try? container.decode([UTMPost].self, forKey: .topPosts), array.isEmpty {
            // Backend returned empty array instead of empty dict
            topPosts = [:]
        } else {
            // Field is missing or null
            topPosts = [:]
        }

        // Parse and sort UTM metrics by view count
        var metrics: [StatsUTMMetric] = []

        for (key, viewsCount) in topUTMValues {
            // Parse the JSON key to extract values
            let values = Self.parseUTMKey(key)
            let label = values.joined(separator: " / ")

            // Get top posts for this UTM combination
            let postsArray = topPosts[key] ?? []
            let posts = postsArray.map { $0.toStatsTopPost() }

            metrics.append(StatsUTMMetric(
                label: label,
                values: values,
                viewsCount: viewsCount,
                posts: posts
            ))
        }

        // Sort by view count descending
        self.utmMetrics = metrics.sorted { $0.viewsCount > $1.viewsCount }
    }
}

public struct StatsUTMMetric {
    public let label: String
    public let values: [String]
    public let viewsCount: Int
    public let posts: [StatsTopPost]

    public init(label: String,
                values: [String],
                viewsCount: Int,
                posts: [StatsTopPost]) {
        self.label = label
        self.values = values
        self.viewsCount = viewsCount
        self.posts = posts
    }
}

// Helper struct for decoding posts
private struct UTMPost: Decodable {
    let id: Int
    let title: String
    let views: Int
    let href: String

    func toStatsTopPost() -> StatsTopPost {
        StatsTopPost(
            title: title,
            date: nil,
            postID: id,
            postURL: URL(string: href),
            viewsCount: views,
            kind: .post
        )
    }
}

// MARK: - Helpers

extension StatsUTMTimeIntervalData {
    /// Parses a UTM key from the API response
    /// - Examples:
    ///   - `"google"` -> `["google"]`
    ///   - `["google","cpc"]` -> `["google", "cpc"]`
    ///   - `["spring-sale","google","cpc"]` -> `["spring-sale", "google", "cpc"]`
    private static func parseUTMKey(_ key: String) -> [String] {
        let decoder = JSONDecoder()
        guard let data = key.data(using: .utf8) else {
            return [] // Should never happen
        }
        if let values = try? decoder.decode([String].self, from: data) {
            return values
        }
        if let string = try? decoder.decode(String.self, from: data) {
            return [string] // Defensive code, should never happen
        }
        return []
    }
}
