import CoreData

// Imported from CoreData.CoreDataErrors
private let coreDataKnownErrorCodes = [
    NSCoreDataError: "General Core Data error",
    NSEntityMigrationPolicyError: "Migration failed during processing of the entity migration policy ",
    NSExternalRecordImportError: "General error encountered while importing external records",
    NSInferredMappingModelError: "Inferred mapping model creation error",
    NSManagedObjectConstraintMergeError: "Merge policy failed - unable to complete merging due to multiple conflicting constraint violations",
    NSManagedObjectConstraintValidationError: "One or more uniqueness constraints were violated",
    NSManagedObjectContextLockingError: "Can't acquire a lock in a managed object context",
    NSManagedObjectExternalRelationshipError: "An object being saved has a relationship containing an object from another store",
    NSManagedObjectMergeError: "Merge policy failed - unable to complete merging",
    NSManagedObjectReferentialIntegrityError: "Attempt to fire a fault pointing to an object that does not exist (we can see the store, we can't see the object)",
    NSManagedObjectValidationError: "Generic validation error",
    NSMigrationCancelledError: "Migration failed due to manual cancellation",
    NSMigrationConstraintViolationError: "Migration failed due to a violated uniqueness constraint",
    NSMigrationError: "General migration error",
    NSMigrationManagerDestinationStoreError: "Migration failed due to a problem with the destination data store",
    NSMigrationManagerSourceStoreError: "Migration failed due to a problem with the source data store",
    NSMigrationMissingMappingModelError: "Migration failed due to missing mapping model",
    NSMigrationMissingSourceModelError: "Migration failed due to missing source data model",
    NSPersistentHistoryTokenExpiredError: "The history token passed to NSPersistentChangeRequest was invalid",
    NSPersistentStoreCoordinatorLockingError: "Can't acquire a lock in a persistent store coordinator",
    NSPersistentStoreIncompatibleSchemaError: "Store returned an error for save operation (database level errors ie missing table, no permissions)",
    NSPersistentStoreIncompatibleVersionHashError: "Entity version hashes incompatible with data model",
    NSPersistentStoreIncompleteSaveError: "One or more of the stores returned an error during save (stores/objects that failed will be in userInfo)",
    NSPersistentStoreInvalidTypeError: "Unknown persistent store type/format/version",
    NSPersistentStoreOpenError: "An error occurred while attempting to open the persistent store",
    NSPersistentStoreOperationError: "The persistent store operation failed",
    NSPersistentStoreSaveConflictsError: "An unresolved merge conflict was encountered during a save.  userInfo has NSPersistentStoreSaveConflictsErrorKey",
    NSPersistentStoreSaveError: "Unclassified save error - something we depend on returned an error",
    NSPersistentStoreTimeoutError: "Failed to connect to the persistent store within the specified timeout (see NSPersistentStoreTimeoutOption)",
    NSPersistentStoreTypeMismatchError: "Returned by persistent store coordinator if a store is accessed that does not match the specified type",
    NSPersistentStoreUnsupportedRequestTypeError: "An NSPersistentStore subclass was passed an NSPersistentStoreRequest that it did not understand",
    NSSQLiteError: "General SQLite error ",
    NSValidationDateTooLateError: "Some date value is too late",
    NSValidationDateTooSoonError: "Some date value is too soon",
    NSValidationInvalidDateError: "Some date value fails to match date pattern",
    NSValidationInvalidURIError: "Some URI value cannot be represented as a string",
    NSValidationMissingMandatoryPropertyError: "Non-optional property with a nil value",
    NSValidationMultipleErrorsError: "Generic message for error containing multiple validation errors",
    NSValidationNumberTooLargeError: "Some numerical value is too large",
    NSValidationNumberTooSmallError: "Some numerical value is too small",
    NSValidationRelationshipDeniedDeleteError: "Some relationship with NSDeleteRuleDeny is non-empty",
    NSValidationRelationshipExceedsMaximumCountError: "Bounded, to-many relationship with too many destination objects",
    NSValidationRelationshipLacksMinimumCountError: "To-many relationship with too few destination objects",
    NSValidationStringPatternMatchingError: "Some string value fails to match some pattern",
    NSValidationStringTooLongError: "Some string value is too long",
    NSValidationStringTooShortError: "Some string value is too short",
]

private extension NSExceptionName {
    static let coreDataSaveMainException = NSExceptionName("Unresolved Core Data save error (Main Context)")
    static let coreDataSaveDerivedException = NSExceptionName("Unresolved Core Data save error (Derived Context)")
}

extension ContextManager {
    @objc(handleSaveError:inContext:)
    func handleSaveError(_ error: NSError, in context: NSManagedObjectContext) {
        let isMainContext = context == mainContext
        let exceptionName: NSExceptionName = isMainContext ? .coreDataSaveMainException : .coreDataSaveDerivedException
        let reason = reasonForError(error)
        DDLogError("Unresolved Core Data save error: \(error)")
        DDLogError("Generating exception with reason:\n\(reason)")
        // Sentry is choking when userInfo is too big and not sending crash reports
        // For debugging we can still see the userInfo details since we're logging the full error above
        let exception = NSException(name: exceptionName, reason: reason, userInfo: nil)
        exception.raise()
    }
}

private extension ContextManager {
    func reasonForError(_ error: NSError) -> String {
        if error.code == NSValidationMultipleErrorsError {
            guard let errors = error.userInfo[NSDetailedErrorsKey] as? [NSError] else {
                return "Multiple errors without details"
            }
            return reasonForMultipleErrors(errors)
        } else {
            return reasonForIndividualError(error)
        }
    }

    func reasonForMultipleErrors(_ errors: [NSError]) -> String {
        return "Multiple errors:\n" + errors.enumerated().map({ (index, error) in
            return "  \(index + 1): " + reasonForIndividualError(error)
        }).joined(separator: "\n")
    }

    func reasonForIndividualError(_ error: NSError) -> String {
        let entity = entityName(for: error) ?? "null"
        let property = propertyName(for: error) ?? "null"
        let message = coreDataKnownErrorCodes[error.code] ?? "Unknown error (domain: \(error.domain) code: \(error.code), \(error.localizedDescription)"
        return "\(message) on \(entity).\(property)"
    }

    func entityName(for error: NSError) -> String? {
        guard let managedObject = error.userInfo[NSValidationObjectErrorKey] as? NSManagedObject else {
            return nil
        }
        return managedObject.entity.name
    }

    func propertyName(for error: NSError) -> String? {
        return error.userInfo[NSValidationKeyErrorKey] as? String
    }

}
