// Encapsulates Tenor GIF API object
import Foundation

struct TenorGIF: Decodable {
    let id: String
    let created: Date?
    let title: String?

    let media: [TenorGIFCollection]

    let url: URL        // a short URL to view the post on tenor.com - we may not need this
    let itemURL: URL    // the full URL to view the post on tenor.com - we may not need this

    enum CodingKeys: String, CodingKey {
        case id, created, title
        case media
        case url, itemURL = "itemurl"
    }
}
