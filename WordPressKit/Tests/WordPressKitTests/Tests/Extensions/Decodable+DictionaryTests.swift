import XCTest

@testable import WordPressKit

class DecodableDictionaryTests: XCTestCase {
    // Decode a JSON into a Dictionary using Decodable
    //
    func testDecodableToDictionary() {
        let json = """
            {
                "data": {
                    "int": 5,
                    "bool": true,
                    "string": "foo",
                    "array": [1.0, 2.0],
                    "obj": {
                        "foo": "bar"
                    }
                }
            }
        """
        let data = json.data(using: .utf8)!

        let dictionary = try! JSONDecoder().decode(Dict.self, from: data)

        XCTAssertTrue(dictionary.data["int"] as? Int == 5)
        XCTAssertTrue(dictionary.data["bool"] as? Bool == true)
        XCTAssertTrue(dictionary.data["string"] as? String == "foo")
        XCTAssertTrue(dictionary.data["array"] as? [Double] == [1.0, 2.0])
        XCTAssertTrue((dictionary.data["obj"] as? [String: Any])?["foo"] as? String == "bar")
    }
}

private struct Dict: Decodable {
    var data: [String: Any]

    private enum CodingKeys: String, CodingKey {
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([String: Any].self, forKey: .data)
    }
}
