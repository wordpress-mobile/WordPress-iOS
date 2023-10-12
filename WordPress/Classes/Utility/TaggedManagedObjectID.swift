import Foundation

/// `TaggedManagedObjectID` is an `NSManagedObjectID` wrapper that also contains the model type of the `NSManagedObjectID`.
///
/// By using this strongly typed `NSManagedObjectID`, we can declare APIs that are bound to specific model types, thus
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
/// Now the type `Blog` is built into the function signature, and the Swift compiler would report an error if we call it
/// using `getPost(fromBlogID: themeObjectID)`.
///
/// The type name is inspired by the swift-tagged library. The reason we don't use that library is the library exposes
/// a public initliaser `init(rawValue:)` which is not what we want. With this public initialiser available for all users,
/// we can't perform the validation described in `init(objectID:)`.
///
/// - SeeAlso: swift-tagged: https://github.com/pointfreeco/swift-tagged
struct TaggedManagedObjectID<Model: NSManagedObject>: Equatable {
    let objectID: NSManagedObjectID

    /// Create an `TaggedManagedObjectID` instance of the given object.
    init(_ object: Model) {
        var objectID = object.objectID

        if objectID.isTemporaryID {
            let context = object.managedObjectContext!
            do {
                try context.obtainPermanentIDs(for: [object])
            } catch {
                // It should be okay to let the app crash when `obtainPermanentIDs` fails. Because, we crash the app
                // intentionally when `save()` fails (see the `ContextManager.internalSave` function). Also, if the
                // `obtainPermanentIDs` call fails (which may mean SQLite failing to update the database file),
                // then the save call followed (because we typically save newly added model objects) probably is going
                // to fail too. Finally, there aren't many save crashes on Sentry and `obtainPermanentIDs` should be
                // less likely to throw errors than `NSManagedObjectContext.save` function.
                //
                // However, just to be safe, we'll log and monitor this error (if it ever happens) for a few releases.
                // We can decide later if we'd like to change the assertion to a fatal error.
                WordPressAppDelegate.crashLogging?.logError(error)
                assertionFailure("Failed to obtain permanent id for \(objectID). Error: \(error)")
            }
            objectID = object.objectID
        }

        self = TaggedManagedObjectID<Model>(objectID: objectID)
    }

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
