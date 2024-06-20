import Foundation
import WordPressShared

public struct StatsEmailsSummaryData: Decodable, Equatable {
    public let posts: [Post]

    public init(posts: [Post]) {
        self.posts = posts
    }

    private enum CodingKeys: String, CodingKey {
        case posts = "posts"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        posts = try container.decode([Post].self, forKey: .posts)
    }

    public struct Post: Codable, Equatable {
        public let id: Int
        public let link: URL
        public let date: Date
        public let title: String
        public let type: PostType
        public let opens: Int
        public let clicks: Int

        public init(id: Int, link: URL, date: Date, title: String, type: PostType, opens: Int, clicks: Int) {
            self.id = id
            self.link = link
            self.date = date
            self.title = title
            self.type = type
            self.opens = opens
            self.clicks = clicks
        }

        public enum PostType: String, Codable {
            case post = "post"
        }

        private enum CodingKeys: String, CodingKey {
            case id = "id"
            case link = "href"
            case date = "date"
            case title = "title"
            case type = "type"
            case opens = "opens"
            case clicks = "clicks"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            link = try container.decode(URL.self, forKey: .link)
            title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
            type = (try? container.decodeIfPresent(PostType.self, forKey: .type)) ?? .post
            opens = (try? container.decodeIfPresent(Int.self, forKey: .opens)) ?? 0
            clicks = (try? container.decodeIfPresent(Int.self, forKey: .clicks)) ?? 0
            self.date = try container.decode(Date.self, forKey: .date)
        }
    }
}

extension StatsEmailsSummaryData {
    public static var pathComponent: String {
        return "stats/emails/summary"
    }

    public init?(jsonDictionary: [String: AnyObject]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
            let decoder = JSONDecoder.apiDecoder
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            return nil
        }
    }

    public static func queryProperties(quantity: Int, sortField: SortField, sortOrder: SortOrder) -> [String: String] {
        return ["quantity": String(quantity), "sort_field": sortField.rawValue, "sort_order": sortOrder.rawValue]
    }

    public enum SortField: String {
        case opens = "opens"
        case postId = "post_id"
    }

    public enum SortOrder: String {
        case descending = "desc"
        case ascending = "ASC"
    }
}
