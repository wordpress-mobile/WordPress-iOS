import Foundation

/// Shared localizable strings that can be used in different contexts.
enum SharedStrings {
    enum Button {
        static let ok = NSLocalizedString("shared.button.ok", value: "OK", comment: "A shared button title used in different contexts")
        static let cancel = NSLocalizedString("shared.button.cancel", value: "Cancel", comment: "A shared button title used in different contexts")
        static let close = NSLocalizedString("shared.button.close", value: "Close", comment: "A shared button title used in different contexts")
        static let done = NSLocalizedString("shared.button.done", value: "Done", comment: "A shared button title used in different contexts")
        static let edit = NSLocalizedString("shared.button.edit", value: "Edit", comment: "A shared button title used in different contexts")
        static let add = NSLocalizedString("shared.button.add", value: "Add", comment: "A shared button title used in different contexts")
        static let remove = NSLocalizedString("shared.button.remove", value: "Remove", comment: "A shared button title used in different contexts")
        static let save = NSLocalizedString("shared.button.save", value: "Save", comment: "A shared button title used in different contexts")
        static let view = NSLocalizedString("shared.button.view", value: "View", comment: "A shared button title used in different contexts")
        static let share = NSLocalizedString("shared.button.share", value: "Share", comment: "A shared button title used in different contexts")
        static let copy = NSLocalizedString("shared.button.copy", value: "Copy", comment: "A shared button title used in different contexts")
        static let copyLink = NSLocalizedString("shared.button.copyLink", value: "Copy Link", comment: "A shared button title used in different contexts")
        static let `continue` = NSLocalizedString("shared.button.continue", value: "Continue", comment: "A shared button title used in different contexts")
        static let undo = NSLocalizedString("shared.button.undo", value: "Undo", comment: "A shared button title used in different contexts")
    }

    enum Error {
        static let generic = NSLocalizedString("shared.error.geneirc", value: "Something went wrong", comment: "A generic error message")
    }
}
