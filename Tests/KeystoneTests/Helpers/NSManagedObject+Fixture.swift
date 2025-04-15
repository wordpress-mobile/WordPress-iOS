import CoreData

extension NSManagedObject {

    /// Loads the contents of any given JSON file into a new `NSManagedObject` instance.
    ///
    /// - Parameters:
    ///   - filename: The name of the JSON file to be loaded
    ///   - context: The managed object context to use
    /// - Returns: A new instance with property values of the given JSON file.
    static func fixture(fromFile fileName: String, insertInto context: NSManagedObjectContext) throws -> Self {
        let jsonObject = try JSONObject(fromFileNamed: fileName)
        let model = Self.init(context: context)
        for (key, value) in jsonObject {
            model.setValue(value, forKey: key)
        }
        return model
    }

}
