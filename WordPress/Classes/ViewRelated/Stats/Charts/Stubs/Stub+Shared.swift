
import Foundation

import Charts

// MARK: - Bundle support

extension Bundle {
    func jsonData(from fileName: String) -> Data? {
        guard let url = url(forResource: fileName, withExtension: "json") else {
            fatalError("Failed to locate \(fileName).json in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to parse \(fileName).json as Data.")
        }

        return data
    }
}

// MARK: - StubData

/// Stub structure informed by https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/stats/post/%24post_id/
/// Values approximate what's depicted in Zeplin
///
class DataStub<T: Decodable> {

    private(set) var data: Decodable

    init<T: Decodable>(_ type: T.Type, fileName: String) {
        let bundle = Bundle.main
        let decoder = StubDataJSONDecoder()

        guard let jsonData = bundle.jsonData(from: fileName),
            let decoded = try? decoder.decode(T.self, from: jsonData) else {

            fatalError("Failed to decode data from \(fileName).json")
        }

        self.data = decoded
    }
}

// MARK: - StubDataDateFormatter

private class StubDataDateFormatter: DateFormatter {
    override init() {
        super.init()

        self.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormat = "yyyy-MM-dd"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - StubDataJSONDecoder

private class StubDataJSONDecoder: JSONDecoder {
    override init() {
        super.init()

        let dateFormatter = StubDataDateFormatter()
        dateDecodingStrategy = .formatted(dateFormatter)
    }
}
