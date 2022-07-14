import Foundation

@testable import WordPress

final class SiteSuggestionServiceMock: SiteSuggestionService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    override func suggestions(for blog: Blog, completion: @escaping ([SiteSuggestion]?) -> Void) {
        do {
            let bundle = Bundle(for: SuggestionsListViewModelTests.self)
            guard let url = bundle.url(forResource: "site-suggestions", withExtension: "json") else {
                completion([])
                return
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
            let suggestions = try decoder.decode([SiteSuggestion].self, from: data)
            completion(suggestions)
        } catch _ {
            completion([])
        }
    }

}
