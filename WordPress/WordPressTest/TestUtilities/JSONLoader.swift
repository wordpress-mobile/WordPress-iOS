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
        
        let path = NSBundle(forClass: self.dynamicType).pathForResource(name, ofType: type)
        
        if let unwrappedPath = path {
            return loadFileWithPath(unwrappedPath)
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
            return parseData(contents)
        }
        
        return nil
    }

    private func parseData(data : NSData) -> JSONDictionary? {
        let options : NSJSONReadingOptions = .MutableContainers | .MutableLeaves
        var error : NSErrorPointer = nil
        
        if let parseResult : AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: options, error: error) {
            
            return parseResult as? JSONDictionary
        }
        
        return nil
    }
}
