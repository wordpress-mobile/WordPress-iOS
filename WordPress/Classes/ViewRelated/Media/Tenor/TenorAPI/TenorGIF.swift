// Encapsulates Tenor GIF API object
import Foundation

struct TenorGIF: Decodable {
    let id: String
    let created: Date?
    let title: String?

    let media: [TenorGIFCollection]

    enum CodingKeys: String, CodingKey {
        case id, created, title
        case media
    }
}
