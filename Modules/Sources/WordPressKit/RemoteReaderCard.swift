import Foundation

struct ReaderCardEnvelope: Decodable {
    var cards: [RemoteReaderCard]
    var nextPageHandle: String?

    private enum CodingKeys: String, CodingKey {
        case cards
        case nextPageHandle = "next_page_handle"
    }
}

public struct RemoteReaderCard: Decodable {
    public enum CardType: String {
        case post
        case interests = "interests_you_may_like"
        case sites = "recommended_blogs"
        case unknown
    }

    public var type: CardType
    public var post: RemoteReaderPost?
    public var interests: [RemoteReaderInterest]?
    public var sites: [RemoteReaderSiteInfo]?

    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        type = CardType(rawValue: typeString) ?? .unknown

        switch type {
        case .post:
            let postDictionary = try container.decode([String: Any].self, forKey: .data)
            post = RemoteReaderPost(dictionary: postDictionary)
        case .interests:
            interests = try container.decode([RemoteReaderInterest].self, forKey: .data)
        case .sites:
            let sitesArray = try container.decode([Any].self, forKey: .data)

            sites = sitesArray.compactMap {
                guard let dict = $0 as? NSDictionary else {
                    return nil
                }

                return RemoteReaderSiteInfo.siteInfo(forSiteResponse: dict, isFeed: false)
            }

        default:
            post = nil
        }
    }
}
