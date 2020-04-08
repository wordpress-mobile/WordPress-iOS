// Encapsulates Tenor GIFFormat API object

import Foundation

// Each GIF Object in Tenor is offered with different format (size)
struct TenorGIFCollection: Decodable {
    let gif: TenorMediaObject? // The largest size returned by Tenor
    let mediumGIF: TenorMediaObject?
    let tinyGIF: TenorMediaObject?
    let nanoGIF: TenorMediaObject?

    enum CodingKeys: String, CodingKey {
        case nanoGIF = "nanogif"
        case tinyGIF = "tinygif"
        case gif
        case mediumGIF = "mediumgif"
    }
}
