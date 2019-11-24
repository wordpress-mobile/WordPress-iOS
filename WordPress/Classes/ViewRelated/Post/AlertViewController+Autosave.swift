import UIKit

extension UIAlertController {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private class func dateAndTime(for date: Date) -> String {
        return dateFormatter.string(from: date) + " @ " + timeFormatter.string(from: date)
    }

    /// A dialog giving the user the choice between loading the current version a post or its autosaved version.
    static func autosaveOptionsViewController(forSaveDate saveDate: Date, autosaveDate: Date, didTapSaveOption: @escaping () -> Void, didTapAutosaveOption: @escaping () -> Void) -> UIAlertController {

        let title = NSLocalizedString("Which version would you like to edit?", comment: "Title displayed in popup when user has the option to load unsaved changes")

        let saveDateFormatted = dateAndTime(for: saveDate)
        let autosaveDateFormatted = dateAndTime(for: autosaveDate)
        let message = String(format: NSLocalizedString("You recently made changes to this post but didn't save them. Choose a version to load:\n\nFrom this device\nSaved on %@\n\nFrom another device\nSaved on %@\n", comment: "Message displayed in popup when user has the option to load unsaved changes"), saveDateFormatted, autosaveDateFormatted)
        
        let loadSaveButtonTitle = NSLocalizedString("From this device", comment: "Button title displayed in popup indicating date of change on device")
        let fromAutosaveButtonTitle = NSLocalizedString("From another device", comment: "Button title displayed in popup indicating date of change on another device")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: loadSaveButtonTitle, style: .default) { _ in
            didTapSaveOption()
        })
        alertController.addAction(UIAlertAction(title: fromAutosaveButtonTitle, style: .default) { _ in
            didTapAutosaveOption()
        })

        return alertController
    }
}
