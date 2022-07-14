import Foundation
import CoreData

@testable import WordPress

final class SuggestionServiceMock: SuggestionService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    override func suggestions(for blog: Blog, completion: @escaping ([UserSuggestion]?) -> Void) {
        do {
            let bundle = Bundle(for: SuggestionsListViewModelTests.self)
            guard let url = bundle.url(forResource: "user-suggestions", withExtension: "json") else {
                completion([])
                return
            }
            let data = try Data(contentsOf: url)
            let result = try JSONSerialization.jsonObject(with: data, options: [])
            guard let array = result as? [[String: Any]] else {
                completion([])
                return
            }
            let suggestions = array.map { UserSuggestion(dictionary: $0, context: context)! }
            completion(suggestions)
        } catch _ {
            completion([])
        }
    }

    override func shouldShowSuggestions(for blog: Blog) -> Bool {
        return true
    }

}
