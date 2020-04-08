// Encapsulates Tenor API response

import Foundation

struct TenorResponse<T>: Decodable where T: Decodable {
    let webURL: URL?
    let results: T?
    let next: String?

    enum CodingKeys: String, CodingKey {
        case webURL = "weburl"
        case results
        case next
    }
}
