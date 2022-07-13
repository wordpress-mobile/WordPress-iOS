//
//  SuggestionsServiceMock.swift
//  WordPressTest
//
//  Created by Salim Braksa on 12/7/2022.
//  Copyright © 2022 WordPress. All rights reserved.
//

import Foundation

@testable import WordPress

final class SuggestionsServiceMock: SuggestionService {

    override func suggestions(for blog: Blog, completion: @escaping ([UserSuggestion]?) -> Void) {
        do {
            let context = ContextManagerMock.shared.mainContext
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
