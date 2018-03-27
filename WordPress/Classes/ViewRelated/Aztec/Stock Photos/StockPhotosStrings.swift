/// Extension on String containing the literals for the Stock Photos feature
extension String {
    // MARK: - Entry point: alert controller
    static var freePhotosLibrary: String {
        return NSLocalizedString("Free Photo Library", comment: "One of the options when selecting More in the Post Editor's format bar")
    }

    static var files: String {
        return NSLocalizedString("Files", comment: "Label for the action Open Files in the post composer")
    }

    static var cancelMoreOptions: String {
        return NSLocalizedString("Cancel", comment: "Dismisses the Alert from Screen")
    }
}
