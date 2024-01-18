import Foundation
import CocoaLumberjack

/// Provides functionality for fetching, saving, and deleting search phrases
/// used to search for content in the reader.
///
@objc class ReaderSearchSuggestionService: NSObject {

    private let coreDataStack: CoreDataStack

    @objc init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        super.init()
    }

    /// Creates or updates an existing record for the specified search phrase.
    ///
    /// - Parameters:
    ///     - phrase: The search phrase in question.
    ///
    @objc(createOrUpdateSuggestionForPhrase:)
    func createOrUpdateSuggestion(forPhrase phrase: String) {
        self.coreDataStack.performAndSave { context in
            var suggestion = self.findSuggestion(forPhrase: phrase, in: context)
            if suggestion == nil {
                suggestion = NSEntityDescription.insertNewObject(
                    forEntityName: ReaderSearchSuggestion.classNameWithoutNamespaces(),
                    into: context
                ) as? ReaderSearchSuggestion
                suggestion?.searchPhrase = phrase
            }
            suggestion?.date = Date()
        }
    }

    /// Find and return the ReaderSearchSuggestion matching the specified search phrase.
    ///
    /// - Parameters:
    ///     - phrase: The search phrase in question.
    ///
    /// - Returns: A matching search phrase or nil.
    ///
    private func findSuggestion(forPhrase phrase: String, in context: NSManagedObjectContext) -> ReaderSearchSuggestion? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
        fetchRequest.predicate = NSPredicate(format: "searchPhrase MATCHES[cd] %@", phrase)

        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try context.fetch(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogError("Error fetching search suggestion for phrase \(phrase) : \(error.localizedDescription)")
        }

        return suggestions.first
    }

    /// Deletes all saved search suggestions.
    ///
    @objc func deleteAllSuggestions() {
        self.coreDataStack.performAndSave { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
            do {
                let suggestions = try context.fetch(fetchRequest) as! [ReaderSearchSuggestion]
                suggestions.forEach(context.delete(_:))
            } catch let error as NSError {
                DDLogError("Error fetching search suggestion : \(error.localizedDescription)")
            }
        }
    }

}
