import Foundation

// Extension on String containing the literals for the Tenor feature
extension String {
    // MARK: - Entry point: alert controller

    static var tenor: String {
        return NSLocalizedString("Free GIF Library", comment: "One of the options when selecting More in the Post Editor's format bar")
    }
}

enum GIFAlertStrings {
    static let title = NSLocalizedString("Warning", comment: "Editing GIF alert title.")
    static let message = NSLocalizedString("Editing this GIF will remove its animation.", comment: "Editing GIF alert message.")
    static let cancel = NSLocalizedString("Cancel", comment: "Editing GIF alert cancel action button.")
    static let edit = NSLocalizedString("Edit", comment: "Editing GIF alert default action button.")
}
