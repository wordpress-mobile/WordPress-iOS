import Foundation
import CocoaLumberjack

/// Provides functionality for fetching, saving, and deleting search phrases
/// used to search for content in the reader.
///
@objc class ReaderSearchSuggestionService: LocalCoreDataService {

    /// Creates or updates an existing record for the specified search phrase.
    ///
    /// - Parameters:
    ///     - phrase: The search phrase in question.
    ///
    @objc func createOrUpdateSuggestionForPhrase(_ phrase: String) {
        var suggestion = findSuggestionForPhrase(phrase)
        if suggestion == nil {
            suggestion = NSEntityDescription.insertNewObject(forEntityName: ReaderSearchSuggestion.classNameWithoutNamespaces(),
                                                                             into: managedObjectContext) as? ReaderSearchSuggestion
            suggestion?.searchPhrase = phrase
        }
        suggestion?.date = Date()
        ContextManager.sharedInstance().save(managedObjectContext)
    }


    /// Find and return the ReaderSearchSuggestion matching the specified search phrase.
    ///
    /// - Parameters:
    ///     - phrase: The search phrase in question.
    ///
    /// - Returns: A matching search phrase or nil.
    ///
    @objc func findSuggestionForPhrase(_ phrase: String) -> ReaderSearchSuggestion? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
        fetchRequest.predicate = NSPredicate(format: "searchPhrase MATCHES[cd] %@", phrase)

        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.fetch(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogError("Error fetching search suggestion for phrase \(phrase) : \(error.localizedDescription)")
        }

        return suggestions.first
    }


    /// Finds and returns all ReaderSearchSuggestion starting with the specified search phrase.
    ///
    /// - Parameters:
    ///     - phrase: The search phrase in question.
    ///
    /// - Returns: An array of matching `ReaderSearchSuggestion`s.
    ///
    @objc func fetchSuggestionsLikePhrase(_ phrase: String) -> [ReaderSearchSuggestion] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
        fetchRequest.predicate = NSPredicate(format: "searchPhrase BEGINSWITH[cd] %@", phrase)

        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]

        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.fetch(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogError("Error fetching search suggestions for phrase \(phrase) : \(error.localizedDescription)")
        }

        return suggestions
    }


    /// Deletes the specified search suggestion.
    ///
    /// - Parameters:
    ///     - suggestion: The `ReaderSearchSuggestion` to delete.
    ///
    @objc func deleteSuggestion(_ suggestion: ReaderSearchSuggestion) {
        managedObjectContext.delete(suggestion)
        ContextManager.sharedInstance().saveContextAndWait(managedObjectContext)
    }


    /// Deletes all saved search suggestions.
    ///
    @objc func deleteAllSuggestions() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ReaderSearchSuggestion")
        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.fetch(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogError("Error fetching search suggestion : \(error.localizedDescription)")
        }
        for suggestion in suggestions {
            managedObjectContext.delete(suggestion)
        }
        ContextManager.sharedInstance().save(managedObjectContext)
    }

}
