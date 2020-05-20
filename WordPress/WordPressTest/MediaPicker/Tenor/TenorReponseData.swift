
import Foundation

class TenorReponseData {
    static let validSearchResponse: Data = {
        dataFromJsonResource("tenor-search-response")
    }()

    static let invalidSearchResponse: Data = {
        dataFromJsonResource("tenor-invalid-search-reponse")
    }()

    static let emptyMediaSearchResponse =
        """
        {
          "weburl": "https://tenor.com/search/cat-gifs",
          "results": [
          ],
        }
        """
        .data(using: .utf8)!

    fileprivate static func dataFromJsonResource(_ resource: String) -> Data {
        let json = Bundle(for: TenorReponseData.self).url(forResource: resource, withExtension: "json")!
        let data = try! Data(contentsOf: json)
        return data
    }
}
