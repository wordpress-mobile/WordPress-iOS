
import Foundation

typealias JSONObject = Dictionary<String, AnyObject>

extension JSONObject {

    /// Loads the specified json file and returns a dictionary representing it.
    ///
    /// - Parameter fileName: The full name of the json file to load.
    /// - Returns: A dictionary representing the contents of the json file.
    static func loadFile(named fileName: String) -> JSONObject {
        return loadFile(
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
    static func loadFile(_ name: String, type: String) -> JSONObject {
        guard let url = Bundle(for: BundlerFinder.self).url(forResource: name, withExtension: type) else {
            fatalError("File not found in the test bundle: \(name).\(type)")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Can't read content of file: \(name).\(type)")
        }
        guard let parseResult = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves]) else {
            fatalError("Can't parse file as JSON: \(name).\(type)")
        }
        guard let result = parseResult as? JSONObject else {
            fatalError("File content isn't a JSON object: \(name).\(type)")
        }
        return result
    }

}

/// Class for finding the test bundler
private class BundlerFinder {
    // Empty
}
