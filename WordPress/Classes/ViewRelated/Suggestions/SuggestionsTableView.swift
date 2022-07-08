import Foundation

extension SuggestionType {
    var trigger: String {
        switch self {
        case .mention: return "@"
        case .xpost: return "+"
        }
    }
}

@objc public extension SuggestionsTableView {

    // MARK: - API

    /// Returns the a list of prominent suggestions excluding the current user.
    static func prominentSuggestions(fromPostAuthorId postAuthorId: NSNumber?, commentAuthorId: NSNumber?, defaultAccountId: NSNumber?) -> [NSNumber] {
        return [postAuthorId, commentAuthorId].compactMap { $0 != defaultAccountId ? $0 : nil }
    }

    /// Show suggestions for the given word.
    /// - Parameters:
    ///   - word: Used to find the suggestions that contain this word.
    ///   - completionHandler: The completion handler takes a boolean that's true when at least one suggestion is being shown.
    /// - Returns: True when at least one suggestion is being shown.
    func showSuggestions(forWord word: String, completionHandler: ShowSuggestionsCompletionHandler? = nil) {
        guard self.enabled else {
            completionHandler?(false)
            return
        }
        
        // Cancel previous search operation
        self.searchOperationQueue.cancelAllOperations()

        // Perform search in a background thread
        self.searchOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            if word.hasPrefix(self.suggestionTrigger) {
                let searchQuery = NSString(string: word).substring(from: self.suggestionTrigger.count)
                self.searchText = word
                self.searchResults = self.searchResults(
                    searchQuery: searchQuery,
                    suggestions: self.suggestions ?? [],
                    suggestionType: self.suggestionType
                )
            } else {
                self.searchText = ""
                self.searchResults = []
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.setNeedsUpdateConstraints()
                completionHandler?(self.searchResults.count > 0)
            }
        }
    }

    // MARK: - Internal

    func userSuggestions(for siteID: NSNumber, completion: @escaping ([UserSuggestion]?) -> Void) {
        guard let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return }
        SuggestionService.shared.suggestions(for: blog, completion: completion)
    }

    func siteSuggestions(for siteID: NSNumber, completion: @escaping ([SiteSuggestion]?) -> Void) {
        guard let blog = Blog.lookup(withID: siteID, in: ContextManager.shared.mainContext) else { return }
        SiteSuggestionService.shared.suggestions(for: blog, completion: completion)
    }

    var suggestionTrigger: String { return suggestionType.trigger }

    func predicate(for searchQuery: String) -> NSPredicate {
        switch suggestionType {
        case .mention:
            return NSPredicate(format: "(displayName contains[c] %@) OR (username contains[c] %@)", searchQuery, searchQuery)
        case .xpost:
            return NSPredicate(format: "(title contains[cd] %@) OR (siteURL.absoluteString contains[cd] %@)", searchQuery, searchQuery)
        }
    }

    func title(for suggestion: AnyObject) -> String? {
        let title: String?
        switch (suggestionType, suggestion) {
        case (.mention, let suggestion as UserSuggestion):
            title = suggestion.username
        case (.xpost, let suggestion as SiteSuggestion):
            title = suggestion.subdomain
        default:
            return nil
        }
        return title.map { suggestionType.trigger.appending($0) }
    }

    func subtitle(for suggestion: AnyObject) -> String? {
        switch (suggestionType, suggestion) {
        case (.mention, let suggestion as UserSuggestion):
            return suggestion.displayName
        case (.xpost, let suggestion as SiteSuggestion):
            return suggestion.title
        default:
            return nil
        }
    }

    // MARK: - Private

    private func imageURLForSuggestion(at indexPath: IndexPath) -> URL? {
        let suggestion = searchResults[indexPath.row]

        switch (suggestionType, suggestion) {
        case (.mention, let suggestion as UserSuggestion):
            return suggestion.imageURL
        case (.xpost, let suggestion as SiteSuggestion):
            return suggestion.blavatarURL
        default:
            return nil
        }
    }

    func loadImage(for suggestion: AnyObject, in cell: SuggestionsTableViewCell, at indexPath: IndexPath) {
        cell.iconImageView.image = UIImage(named: "gravatar")
        guard let imageURL = imageURLForSuggestion(at: indexPath) else { return }
        cell.imageDownloadHash = imageURL.hashValue

        retrieveIcon(for: imageURL) { image in
            guard indexPath.row < self.searchResults.count else { return }
            if let reloadedImageURL = self.imageURLForSuggestion(at: indexPath), reloadedImageURL.hashValue == cell.imageDownloadHash {
                cell.iconImageView.image = image
            }
        }
    }

    func fetchSuggestions(for siteID: NSNumber) {
        switch self.suggestionType {
        case .mention:
            userSuggestions(for: siteID) { userSuggestions in
                self.suggestions = userSuggestions
                self.showSuggestions(forWord: self.searchText)
            }
        case .xpost:
            siteSuggestions(for: siteID) { siteSuggestions in
                self.suggestions = siteSuggestions
                self.showSuggestions(forWord: self.searchText)
            }
        }
    }

    private func searchResults(searchQuery: String, suggestions: [Any], suggestionType: SuggestionType) -> [Any] {
        var searchResults: [Any]
        if !searchQuery.isEmpty {
            let predicate = self.predicate(for: searchQuery)
            searchResults = NSMutableArray(array: suggestions).filtered(using: predicate)
        } else {
            searchResults = suggestions
        }
        if suggestionType == .mention, let userSuggestionsResult = searchResults as? [UserSuggestion] {
            searchResults = self.moveProminentSuggestionsToTop(searchResults: userSuggestionsResult, prominentSuggestionsIds: prominentSuggestionsIds ?? [])
        }
        return searchResults
    }

    private func moveProminentSuggestionsToTop(searchResults: [UserSuggestion], prominentSuggestionsIds ids: [NSNumber]) -> [UserSuggestion] {
        // Do not proceed if `searchResults` or `prominentSuggestionsIds` is empty.
        guard !(searchResults.isEmpty || ids.isEmpty) else { return searchResults }

        // Loop through `searchResults` and find the following data:
        //
        // 1. suggestionIndexesToRemove: User Suggestions should be removed from their old position.
        //
        // 2. suggestionsToInsert: User Suggestions to insert at the beginning of `searchResults`
        //                         while maintaining their order from `prominentSuggestionsIds`.
        //
        var suggestionIndexesToRemove = [Int]()
        var suggestionsToInsert: [UserSuggestion?] = Array(repeating: nil, count: ids.count)
        for (index, suggestion) in searchResults.enumerated() {
            guard let position = ids.firstIndex(where: { suggestion.userID == $0 }) else { continue }
            suggestionIndexesToRemove.append(index)
            suggestionsToInsert[position] = suggestion
        }

        // Move suggestions to the beginning of `searchResults` array.
        var searchResults = searchResults
        if !suggestionsToInsert.isEmpty && suggestionIndexesToRemove.count > 0 {
            let suggestionsToInsert = suggestionsToInsert.compactMap { $0 }
            suggestionIndexesToRemove.forEach { searchResults.remove(at: $0) }
            searchResults = suggestionsToInsert + searchResults
        }
        return searchResults
    }

    private func suggestionText(for suggestion: Any) -> String? {
        switch (suggestionType, suggestion) {
        case (.mention, let suggestion as UserSuggestion):
            return suggestion.username
        case (.xpost, let suggestion as SiteSuggestion):
            return suggestion.subdomain
        default: return nil
        }
    }

    private func retrieveIcon(for imageURL: URL?, success: @escaping (UIImage?) -> Void) {
        let imageSize = CGSize(width: SuggestionsTableViewCellIconSize, height: SuggestionsTableViewCellIconSize)

        if let image = cachedIcon(for: imageURL, with: imageSize) {
            success(image)
        } else {
            fetchIcon(for: imageURL, with: imageSize, success: success)
        }
    }

    private func cachedIcon(for imageURL: URL?, with size: CGSize) -> UIImage? {
        var hash: NSString?
        let type = avatarSourceType(for: imageURL, with: &hash)

        if let hash = hash, let type = type {
            return WPAvatarSource.shared()?.cachedImage(forAvatarHash: hash as String, of: type, with: size)
        }
        return nil
    }

    private func fetchIcon(for imageURL: URL?, with size: CGSize, success: @escaping ((UIImage?) -> Void)) {
        var hash: NSString?
        let type = avatarSourceType(for: imageURL, with: &hash)

        if let hash = hash, let type = type {
            WPAvatarSource.shared()?.fetchImage(forAvatarHash: hash as String, of: type, with: size, success: success)
        } else {
            success(nil)
        }
    }
    
    // MARK: - Types
    
    typealias ShowSuggestionsCompletionHandler = (Bool) -> Void
    
}

extension SuggestionsTableView {
    func avatarSourceType(for imageURL: URL?, with hash: inout NSString?) -> WPAvatarSourceType? {
        if let imageURL = imageURL {
            return WPAvatarSource.shared()?.parseURL(imageURL, forAvatarHash: &hash)
        }
        return .unknown
    }
}

extension SuggestionsTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let suggestion = searchResults[indexPath.row]
        let text = suggestionText(for: suggestion)
        let currentSearchText = String(searchText.dropFirst())
        suggestionsDelegate?.suggestionsTableView?(self, didSelectSuggestion: text, forSearchText: currentSearchText)
    }
}
