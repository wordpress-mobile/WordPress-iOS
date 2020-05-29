// Encapsulates Tenor GIF Media object

import Foundation

struct TenorMediaObject: Decodable {
    let url: URL
    let dimension: [Int]
    let preview: URL
    let size: Int64

    enum CodingKeys: String, CodingKey {
        case url
        case dimension = "dims"
        case preview
        case size
    }

    var mediaSize: CGSize {
        guard dimension.count == 2 else {
            return .zero
        }

        return CGSize(width: dimension[0], height: dimension[1])
    }
}
