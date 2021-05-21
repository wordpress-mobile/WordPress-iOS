/// Extension on String containing the literals for the Stock Photos feature
extension String {
    // MARK: - Entry point: alert controller
    static var freePhotosLibrary: String {
        return NSLocalizedString("Free Photo Library", comment: "One of the options when selecting More in the Post Editor's format bar")
    }

    static var otherApps: String {
        return NSLocalizedString("Other Apps", comment: "Menu option used for adding media from other applications.")
    }

    static var closePicker: String {
        return NSLocalizedString("Close", comment: "Dismiss the media picker for Stock Photos")
    }

    static var cancelMoreOptions: String {
        return NSLocalizedString("Dismiss", comment: "Dismiss the AlertView")
    }

    // MARK: - Placeholder
    static var freePhotosPlaceholderTitle: String {
        return NSLocalizedString("Search to find free photos to add to your Media Library!", comment: "Title for placeholder in Free Photos")
    }

    static var freePhotosPlaceholderSubtitle: String {
        return NSLocalizedString("Photos provided by Pexels", comment: "Subtitle for placeholder in Free Photos. The company name 'Pexels' should always be written as it is.")
    }

    static var freePhotosSearchNoResult: String {
        return NSLocalizedString("No media matching your search", comment: "Phrase to show when the user search for images but there are no result to show.")
    }

    static var freePhotosSearchLoading: String {
        return NSLocalizedString("Loading Photos...", comment: "Phrase to show when the user has searched for images and they are being loaded.")
    }
}
