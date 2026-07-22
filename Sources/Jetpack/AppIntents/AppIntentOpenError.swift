import AppIntents
import Foundation

/// Errors surfaced to the system when an open intent cannot proceed.
enum AppIntentOpenError: Error, CustomLocalizedStringResourceConvertible {
    case notLoggedIn
    case siteNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLoggedIn:
            return LocalizedStringResource(
                "ios-appintents.openError.notLoggedIn",
                defaultValue: "Sign in to the app first to use this action.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when an App Intent runs while no account is signed in."
            )
        case .siteNotFound:
            return LocalizedStringResource(
                "ios-appintents.openError.siteNotFound",
                defaultValue: "The site could not be found.",
                table: "AppIntents",
                comment:
                    "Error shown by Siri or the Shortcuts app when the site an App Intent should act on no longer exists."
            )
        }
    }
}
