import Foundation

/// `TaggedManagedObjectID` is a `NSManagedObjectID` wrapper that also contains the model type of the `NSManagedObjectID`.
///
/// By using this strongly typed `NSManagedObjectID`, we can declare APIs that're bound to specific model types, thus
/// preventing an incorrect object id being used as argument.
///
/// Take the following function as an example,
/// ```
/// func getPost(fromBlogID blogID: NSManagedObjectID)
/// ```
///
/// We can call the function with any `NSManagedObjectID`: `getPost(fromBlogID: themeObjectID)`. This usage is obviously
/// incorrect, but we won't be able to catch this error until something goes wrong at rumtime.
///
/// However, we can change the declaration to
/// ```
/// func getPost(fromBlogID: TaggedManagedObjectID<Blog>)
/// ```
///
/// Now the type `Blog` is built into the function signature, and Swift compiler would report an error if we call it using
/// `getPost(fromBlogID: themeObjectID)`.
///
/// The type name is inspired by the swift-tagged library. The reason we don't use that library is the library exposes
/// a public initliaser `init(rawValue:)` which is not what we want. With this public initialiser available for all users,
/// We can't perform the validation described in `init(objectID:)`.
///
/// - SeeAlso: swift-tagged: https://github.com/pointfreeco/swift-tagged
struct TaggedManagedObjectID<Model: NSManagedObject>: Equatable {
    var objectID: NSManagedObjectID

    // This initialzer is declared as `private`, because we want to prevent mismatch between `Model` and the type
    // that the `objectID` represents.
    //
    // When this private initialzer is called, we need to ensure the following requirements are satisfied at runtime:
    // - The `objectID` is a permanent id.
    // - The model associated with the given `objectID` is indeed `Model`.
    private init(objectID: NSManagedObjectID) {
        precondition(!objectID.isTemporaryID, "The `objectID` is not a permanent id. Call `obtainPermanentIDs` first.")
        self.objectID = objectID
    }

    /// Create an `TaggedManagedObjectID` instance of an object that's already saved.
    init(saved object: Model) {
        self = TaggedManagedObjectID<Model>(objectID: object.objectID)
    }

    /// Create an `TaggedManagedObjectID` instance of an object that's not yet saved.
    init(unsaved object: Model) throws {
        var objectID = object.objectID
        if objectID.isTemporaryID {
            let context = object.managedObjectContext!
            try context.obtainPermanentIDs(for: [object])
            objectID = object.objectID
        }

        self = TaggedManagedObjectID<Model>(objectID: objectID)
    }
}

extension NSManagedObjectContext {

    /// Find the object associated with this object id in the given `context`.
    ///
    /// - SeeAlso: `NSManagedObjectContext.existingObject(with:)`
    func existingObject<Model>(with id: TaggedManagedObjectID<Model>) throws -> Model {
        do {
            var result: Result<Model, Error>!

            // Catch an Objective-C `NSInvalidArgumentException` exception from `existingObject(with:)`.
            // See https://github.com/wordpress-mobile/WordPress-iOS/issues/20630
            try WPException.objcTry {
                result = Result {
                    let object = try self.existingObject(with: id.objectID)
                    guard let model = object as? Model else {
                        fatalError("Expecting \(Model.self) type from the object id (\(id.objectID), but got \(object)")
                    }
                    return model
                }
            }

            return try result.get()
        } catch {
            throw error
        }
    }

}
