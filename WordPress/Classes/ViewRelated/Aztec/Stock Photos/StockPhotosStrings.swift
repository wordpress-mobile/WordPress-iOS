/// Extension on String containing the literals for the Stock Photos feature
extension String {
    // MARK: - Entry point: alert controller
    static var freePhotosLibrary: String {
        return NSLocalizedString("Free Photo Library", comment: "One of the options when selecting More in the Post Editor's format bar")
    }

    static var files: String {
        return NSLocalizedString("Other Apps", comment: "Menu option used for adding media from other applications.")
    }

    static var cancelMoreOptions: String {
        return NSLocalizedString("Dismiss", comment: "Dismiss the AlertView")
    }
}
