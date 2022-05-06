import Foundation
import XCTest

typealias JSONObject = Dictionary<String, AnyObject>

extension JSONObject {

    /// Loads the specified json file and returns a dictionary representing it.
    ///
    /// - Parameter fileName: The name of the json file to load. The "json" file extension can be omitted.
    /// - Returns: A dictionary representing the contents of the json file.
    static func loadJSONFile(named fileName: String) throws -> JSONObject {
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
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Can't find JSON file named \(fileName) or \(fileName).json"
                ]
            )
        }
        let data = try Data(contentsOf: url)
        let parseResult = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves])
        return try XCTUnwrap(parseResult as? JSONObject)
    }

}

/// Class for finding the test bundler
private class BundlerFinder {
    // Empty
}
