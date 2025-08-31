import Foundation

struct ReaderPostsEnvelope: Decodable {
    var posts: [RemoteReaderPost]
    var nextPageHandle: String?

    private enum CodingKeys: String, CodingKey {
        case posts
        case nextPageHandle = "next_page_handle"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let postDictionary = try container.decode([String: Any].self, forKey: .posts)
        posts = [RemoteReaderPost(dictionary: postDictionary)]
    }
}
