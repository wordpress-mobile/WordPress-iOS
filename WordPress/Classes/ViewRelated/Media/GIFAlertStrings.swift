import Foundation

/// Strings for the alert shown when the user tries to edit a GIF attachment
/// (editing removes the animation).
enum GIFAlertStrings {
    static let title = NSLocalizedString("Warning", comment: "Editing GIF alert title.")
    static let message = NSLocalizedString(
        "Editing this GIF will remove its animation.",
        comment: "Editing GIF alert message."
    )
    static let cancel = NSLocalizedString("Cancel", comment: "Editing GIF alert cancel action button.")
    static let edit = NSLocalizedString("Edit", comment: "Editing GIF alert default action button.")
}
