import Foundation

class JSONLoader
{
    typealias JSONDictionary = Dictionary<String, AnyObject>
    
    /**
     *  @brief      Loads the specified json file name and returns a dictionary representing it.
     *
     *  @param      filepath        The path of the json file to load.
     *
     *  @returns    A dictionary representing the contents of the json file.
     */
    func load(filepath : String) -> JSONDictionary? {
        
        var parseResult : JSONDictionary?
        
        if let contents = NSData(contentsOfFile: filepath) {
            let options : NSJSONReadingOptions = .MutableContainers | .MutableLeaves
            var error : NSErrorPointer = nil

            parseResult = NSJSONSerialization.JSONObjectWithData(contents, options: options, error: error) as? JSONDictionary
        }
        
        return parseResult
    }
}
