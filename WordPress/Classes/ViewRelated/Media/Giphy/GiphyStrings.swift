/// Extension on String containing the literals for the Giphy feature
extension String {
    // MARK: - Entry point: alert controller
    static var giphy: String {
        return NSLocalizedString("Giphy", comment: "One of the options when selecting More in the Post Editor's format bar")
    }

    // MARK: - Placeholder
    static var giphyPlaceholderTitle: String {
        return NSLocalizedString("Search to find GIFs to add to your Media Library!", comment: "Title for placeholder in Giphy picker")
    }

    static var giphyPlaceholderSubtitle: String {
        return NSLocalizedString("Powered by Giphy", comment: "Subtitle for placeholder in Giphy picker. `The company name 'Giphy' should always be written as it is.")
    }

    static var giphySearchNoResult: String {
        return NSLocalizedString("No GIFs match your search for:", comment: "Phrase to show when the user searches for GIFs but there are no result to show. This will be followed by the phrase the user used to search. (i.e. No GIFs match your search for cute kitten). This search phrase will be always appended at the end.")
    }

    static var giphySearchLoading: String {
        return NSLocalizedString("Loading GIFs...", comment: "Phrase to show when the user has searched for GIFs and they are being loaded.")
    }

}
