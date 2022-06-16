import Foundation
import XCTest

typealias JSONObject = Dictionary<String, AnyObject>

extension JSONObject {

    /// Create a dictionary represented by the specified json file.
    ///
    /// - Parameter fileName: The name of the json file to load. The "json" file extension can be omitted.
    init(fromFileNamed fileName: String) throws {
        let type = (fileName as NSString).pathExtension
        if type != "" && type != "json" {
            throw NSError(
                domain: "JSONObject",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "File extension should be 'json': \(fileName)"
                ]
            )
        }

        let testBundle = Bundle(for: BundlerFinder.self)
        let candidates = [
            testBundle.url(forResource: fileName, withExtension: nil),
            testBundle.url(forResource: fileName, withExtension: "json"),
        ]
        guard let url = candidates.compactMap({ $0 }).first else {
            throw NSError(
                domain: "JSONObject",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Can't find JSON file named \(fileName) or \(fileName).json"
                ]
            )
        }
        let data = try Data(contentsOf: url)
        let parseResult = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves])
        self = try XCTUnwrap(parseResult as? JSONObject)
    }

}

/// Class for finding the test bundler
private class BundlerFinder {
    // Empty
}
