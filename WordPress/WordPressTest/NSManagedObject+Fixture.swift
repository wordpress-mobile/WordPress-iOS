import CoreData

extension NSManagedObject {

    /// Loads the contents of any given JSON file into a new `NSManagedObject` instance.
    ///
    /// This helper method is useful for Unit Testing scenarios.
    ///
    /// - Parameters:
    ///   - filename: The name of the JSON file to be loaded
    ///   - context: The managed object context to use
    /// - Returns: A new instance with property values of the given JSON file.
    static func fixture(fromFile fileName: String, context: NSManagedObjectContext) -> Self {
        guard let jsonObject = JSONLoader().loadFile(named: filename) else {
            fatalError("Mockup data could not be parsed, the filename is \(filename)")
        }
        let model = Self.init(context: context)
        for (key, value) in jsonObject {
            model.setValue(value, forKey: key)
        }
        return model
    }

}
