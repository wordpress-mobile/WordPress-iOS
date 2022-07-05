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

    /// Show suggestions for the given word.
    /// - Parameters:
    ///   - word: Used to find the suggestions that contain this word.
    ///   - completionHandler: Completion handler that indicates  whether at least one suggestion is being shown.
    func showSuggestions(forWord word: String, completionHandler: ((Bool) -> Void)? = nil) {
        guard self.enabled else {
            completionHandler?(false)
            return
        }

        // Cancel previous operation
        self.searchOperationQueue.cancelAllOperations()

        // Perform search
        self.searchOperationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            self.searchText = word.hasPrefix(self.suggestionTrigger) ? word : ""
            self.searchResults = self.searchResults(fromWord: word)
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

    private func searchResults(fromWord word: String) -> NSMutableArray {
        guard word.hasPrefix(self.suggestionTrigger) else { return NSMutableArray() }
        let suggestions = NSMutableArray(array: self.suggestions ?? [])
        var searchResults: NSMutableArray
        if word.count > 1 {
            let searchQuery = NSString(string: word).substring(from: 1)
            let predicate = self.predicate(for: searchQuery)
            searchResults = NSMutableArray(array: suggestions.filtered(using: predicate))
        } else {
            searchResults = suggestions
        }
        self.moveProminentSuggestionsToTop(searchResults: searchResults)
        return searchResults
    }

    private func moveProminentSuggestionsToTop(searchResults: NSMutableArray) {
        // This method only works for "mention" suggestion types
        // And when both "searchResults" and "prominentSuggestionsIds" are not empty
        guard
            self.suggestionType == .mention &&
            searchResults.count > 0,
            let ids = self.prominentSuggestionsIds,
            !ids.isEmpty
        else { return }

        // Finds the suggestions to move to the top of the "searchResults" array.
        //
        // Also, the order of the prominent suggestions in "searchResults" should be
        // the same order as "prominentSuggestionsIds".
        var suggestionsToInsert: [Any?] = Array(repeating: nil, count: ids.count)
        let indexesToRemove = NSMutableIndexSet()
        for (index, item) in (searchResults as NSArray).enumerated() {
            guard
                let suggestion = item as? UserSuggestion,
                let position = ids.firstIndex(where: { suggestion.id == $0 })
            else { continue }
            suggestionsToInsert[position] = suggestion
            indexesToRemove.add(index)
        }

        // Move suggestions to the beginning of the list
        if !suggestionsToInsert.isEmpty && indexesToRemove.count > 0 {
            let suggestionsToInsert = suggestionsToInsert.compactMap { $0 }
            searchResults.removeObjects(at: indexesToRemove as IndexSet)
            searchResults.insert(suggestionsToInsert, at: IndexSet(0..<suggestionsToInsert.count))
        }
    }

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
