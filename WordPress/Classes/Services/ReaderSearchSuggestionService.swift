import Foundation

///
///
@objc class ReaderSearchSuggestionService : LocalCoreDataService
{

    ///
    ///
    func createOrUpdateSuggestionForPhrase(phrase: String) {
        var suggestion = findSuggestionForPhrase(phrase)
        if suggestion == nil {
            suggestion = NSEntityDescription.insertNewObjectForEntityForName(ReaderSearchSuggestion.classNameWithoutNamespaces(),
                                                                             inManagedObjectContext: managedObjectContext) as? ReaderSearchSuggestion
            suggestion?.searchPhrase = phrase
        }
        suggestion?.date = NSDate()
        ContextManager.sharedInstance().saveContext(managedObjectContext)
    }


    ///
    ///
    func findSuggestionForPhrase(phrase: String) -> ReaderSearchSuggestion? {
        let fetchRequest = NSFetchRequest(entityName: "ReaderSearchSuggestion")
        fetchRequest.predicate = NSPredicate(format: "searchPhrase MATCHES[cd] %@", phrase)

        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.executeFetchRequest(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching search suggestion for phrase \(phrase) : \(error.localizedDescription)")
        }

        return suggestions.first
    }


    ///
    ///
    func fetchSuggestionsLikePhrase(phrase: String) -> [ReaderSearchSuggestion] {
        let fetchRequest = NSFetchRequest(entityName: "ReaderSearchSuggestion")
        fetchRequest.predicate = NSPredicate(format: "searchPhrase BEGINSWITH[cd] %@", phrase)

        let sort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sort]

        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.executeFetchRequest(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching search suggestions for phrase \(phrase) : \(error.localizedDescription)")
        }

        return suggestions
    }


    ///
    ///
    func deleteSuggestion(suggestion: ReaderSearchSuggestion) {
        managedObjectContext.deleteObject(suggestion)
        ContextManager.sharedInstance().saveContext(managedObjectContext)
    }


    ///
    ///
    func deleteAllSuggestions() {
        let fetchRequest = NSFetchRequest(entityName: "ReaderSearchSuggestion")
        var suggestions = [ReaderSearchSuggestion]()
        do {
            suggestions = try managedObjectContext.executeFetchRequest(fetchRequest) as! [ReaderSearchSuggestion]
        } catch let error as NSError {
            DDLogSwift.logError("Error fetching search suggestion : \(error.localizedDescription)")
        }
        _ = suggestions.map({ (suggestion) in
            managedObjectContext.deleteObject(suggestion)
        })
        ContextManager.sharedInstance().saveContext(managedObjectContext)
    }

}
