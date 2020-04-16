// Parse a Tenor API response
import Foundation

class TenorResponseParser<T> where T: Decodable {
    private(set) var results: [T]?
    private(set) var next: String?

    func parse(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let response = try decoder.decode(TenorResponse<[T]>.self, from: data)

        results = response.results ?? []
        next = response.next
    }
}
