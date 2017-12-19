
import Foundation

@objc open class JSONLoader: NSObject {
    public typealias JSONDictionary = Dictionary<String, AnyObject>

    /**
    *  @brief      Loads the specified json file name and returns a dictionary representing it.
    *
    *  @param      path    The path of the json file to load.
    *
    *  @returns    A dictionary representing the contents of the json file.
    */
    open func loadFile(_ name: String, type: String) -> JSONDictionary? {

        let path = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type)

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
    open func loadFile(_ path: String) -> JSONDictionary? {

        if let contents = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return parseData(contents)
        }

        return nil
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
