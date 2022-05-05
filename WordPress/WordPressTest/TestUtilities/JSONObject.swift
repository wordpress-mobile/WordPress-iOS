import Foundation
import XCTest

typealias JSONObject = Dictionary<String, AnyObject>

extension JSONObject {

    /// Loads the specified json file and returns a dictionary representing it.
    ///
    /// - Parameter fileName: The full name of the json file to load.
    /// - Returns: A dictionary representing the contents of the json file.
    static func loadFile(named fileName: String) throws -> JSONObject {
        return try loadFile(
            (fileName as NSString).deletingPathExtension,
            type: (fileName as NSString).pathExtension
        )
    }

    /// Loads the specified JSON file and returns a dictionary representing it.
    ///
    /// - Parameters:
    ///   - name: The name of the file
    ///   - type: The extension of the file
    /// - Returns: A dictionary representing the contents of the JSON file.
    static func loadFile(_ name: String, type: String) throws -> JSONObject {
        let url = try XCTUnwrap(Bundle(for: BundlerFinder.self).url(forResource: name, withExtension: type))
        let data = try Data(contentsOf: url)
        let parseResult = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves])
        return try XCTUnwrap(parseResult as? JSONObject)
    }

}

/// Class for finding the test bundler
private class BundlerFinder {
    // Empty
}
