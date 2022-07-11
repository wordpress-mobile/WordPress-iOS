//
//  SuggestionsViewModel.swift
//  WordPress
//
//  Created by Salim Braksa on 10/7/2022.
//  Copyright © 2022 WordPress. All rights reserved.
//

import Foundation

@objc final class SuggestionViewModel: NSObject {

    @objc let title: String?
    @objc let subtitle: String?
    @objc let imageURL: URL?

    init(suggestion: UserSuggestion) {
        self.title = suggestion.username
        self.subtitle = suggestion.displayName
        self.imageURL = suggestion.imageURL
    }

    init(suggestion: SiteSuggestion) {
        self.title = suggestion.subdomain
        self.subtitle = suggestion.title
        self.imageURL = suggestion.blavatarURL
    }

}
