
import Foundation

@objc open class JSONLoader: NSObject {
    public typealias JSONDictionary = Dictionary<String, AnyObject>

    /// Loads the specified JSON file and returns a dictionary representing it.
    ///
    /// - Parameters:
    ///   - name: The name of the file
    ///   - type: The extension of the file
    /// - Returns: A dictionary representing the contents of the JSON file.
    open func loadFile(_ name: String, type: String) -> JSONDictionary? {

        let path = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type)

        if let unwrappedPath = path {
            return loadFile(unwrappedPath)
        } else {
            return nil
        }
    }

    /// Loads the specified json file and returns a dictionary representing it.
    ///
    /// - Parameter path: The path of the json file to load.
    /// - Returns: A dictionary representing the contents of the json file.
    open func loadFile(_ path: String) -> JSONDictionary? {

        if let contents = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return parseData(contents)
        }

        return nil
    }

    /// Loads the specified json file and returns a dictionary representing it.
    ///
    /// - Parameter filename: The full name of the json file to load.
    /// - Returns: A dictionary representing the contents of the json file.
    open func loadFile(named filename: String) -> JSONDictionary? {
        return loadFile(
            (filename as NSString).deletingPathExtension,
            type: (filename as NSString).pathExtension
        )
    }

    fileprivate func parseData(_ data: Data) -> JSONDictionary? {
        let options: JSONSerialization.ReadingOptions = [.mutableContainers, .mutableLeaves]

        do {
            let parseResult = try JSONSerialization.jsonObject(with: data as Data, options: options)
            return parseResult as? JSONDictionary
        } catch {
            return nil
        }
    }
}
