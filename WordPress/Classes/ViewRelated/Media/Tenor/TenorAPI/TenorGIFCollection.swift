// Encapsulates Tenor GIFFormat API object

import Foundation

// Each GIF Object in Tenor is offered with different format (size)
struct TenorGIFCollection: Decodable {
    let gif: TenorMediaObject? // The lagest size
    let mediumGIF: TenorMediaObject?
    let tinyGIF: TenorMediaObject?

    enum CodingKeys: String, CodingKey {
        case tinyGIF = "tinygif"
        case gif
        case mediumGIF = "mediumgif"
    }
}
