
import Foundation

@objc public class JSONLoader : NSObject {
    public typealias JSONDictionary = Dictionary<String, AnyObject>

    /**
    *  @brief      Loads the specified json file name and returns a dictionary representing it.
    *
    *  @param      path    The path of the json file to load.
    *
    *  @returns    A dictionary representing the contents of the json file.
    */
    public func loadFileWithName(name : String, type : String) -> JSONDictionary? {

        let path = Bundle(for: type(of: self)).path(forResource: name, ofType: type)

        if let unwrappedPath = path {
            return loadFileWithPath(path: unwrappedPath)
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
    public func loadFileWithPath(path : String) -> JSONDictionary? {

        if let contents = NSData(contentsOfFile: path) {
            return parseData(data: contents)
        }

        return nil
    }

    private func parseData(data : NSData) -> JSONDictionary? {
        let options : JSONSerialization.ReadingOptions = [.mutableContainers , .mutableLeaves]

        do {
            let parseResult = try JSONSerialization.jsonObject(with: data as Data, options: options)
            return parseResult as? JSONDictionary
        } catch {
            return nil
        }
    }
}
