import Foundation

@objc open class JSONLoader: NSObject {
    public typealias JSONDictionary = [String: AnyObject]

    /**
    *  @brief      Loads the specified json file name and returns a dictionary representing it.
    *
    *  @returns    A dictionary representing the contents of the json file.
    */
    @objc open func loadFile(_ name: String, type: String) -> JSONDictionary? {

        let path = JSONLoader.bundle.path(forResource: name, ofType: type)

        if let unwrappedPath = path {
            return loadFile(unwrappedPath)
        } else {
            return nil
        }
    }

    /**
     *  @brief      Loads the specified json file name and returns a dictionary representing it.
     *
     *  @param      path    The path of the json file to load.
     *
     *  @returns    A dictionary representing the contents of the json file.
     */
    @objc open func loadFile(_ path: String) -> JSONDictionary? {

        if let contents = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return parseData(contents)
        }

        return nil
    }

    private func parseData(_ data: Data) -> JSONDictionary? {
        let options: JSONSerialization.ReadingOptions = [.mutableContainers, .mutableLeaves]

        do {
            let parseResult = try JSONSerialization.jsonObject(with: data as Data, options: options)
            return parseResult as? JSONDictionary
        } catch {
            return nil
        }
    }

    public static func data(named name: String, ext: String = "json") throws -> Data {
        guard let url = Bundle(for: JSONLoader.self).url(forResource: name, withExtension: ext) else {
            throw URLError(.badURL)
        }
        return try Data(contentsOf: url)
    }

    private static var bundle: Bundle {
        Bundle(for: JSONLoader.self)
    }
}
