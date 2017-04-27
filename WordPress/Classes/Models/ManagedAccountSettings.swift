import Foundation
import CoreData

// MARK: - Reflects the user's Account Settings, as stored in Core Data.
//
class ManagedAccountSettings: NSManagedObject {

    // MARK: - NSManagedObject

    override class var entityName: String {
        return "AccountSettings"
    }

    func updateWith(_ accountSettings: AccountSettings) {
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
        displayName = accountSettings.displayName
        aboutMe = accountSettings.aboutMe

        username = accountSettings.username
        email = accountSettings.email
        emailPendingAddress = accountSettings.emailPendingAddress
        emailPendingChange = accountSettings.emailPendingChange
        primarySiteID = NSNumber(value: accountSettings.primarySiteID)
        webAddress = accountSettings.webAddress
        language = accountSettings.language
    }

    /// Applies a change to the account settings
    /// To change a setting, you create a change and apply it to the AccountSettings object.
    /// This method will return a new change object to apply if you want to revert the changes
    /// (for instance, if they failed to save)
    ///
    /// - Returns: the change object needed to revert this change
    ///
    func applyChange(_ change: AccountSettingsChange) -> AccountSettingsChange {
        let reverse = reverseChange(change)

        switch change {
        case .firstName(let value):
            self.firstName = value
        case .lastName(let value):
            self.lastName = value
        case .displayName(let value):
            self.displayName = value
        case .aboutMe(let value):
            self.aboutMe = value
        case .email(let value):
            self.emailPendingAddress = value
            self.emailPendingChange = true
        case .emailRevertPendingChange:
            self.emailPendingAddress = nil
            self.emailPendingChange = false
        case .primarySite(let value):
            self.primarySiteID = NSNumber(value: value)
        case .webAddress(let value):
            self.webAddress = value
        case .language(let value):
            self.language = value
        }

        return reverse
    }

    fileprivate func reverseChange(_ change: AccountSettingsChange) -> AccountSettingsChange {
        switch change {
        case .firstName(_):
            return .firstName(self.firstName)
        case .lastName(_):
            return .lastName(self.lastName)
        case .displayName(_):
            return .displayName(self.displayName)
        case .aboutMe(_):
            return .aboutMe(self.aboutMe)
        case .email(_):
            return .emailRevertPendingChange
        case .emailRevertPendingChange(_):
            return .email(self.emailPendingAddress ?? String())
        case .primarySite(_):
            return .primarySite(self.primarySiteID.intValue)
        case .webAddress(_):
            return .webAddress(self.webAddress)
        case .language(_):
            return .language(self.language)
        }
    }
}

enum AccountSettingsChange {
    case firstName(String)
    case lastName(String)
    case displayName(String)
    case aboutMe(String)
    case email(String)
    case emailRevertPendingChange
    case primarySite(Int)
    case webAddress(String)
    case language(String)

    var stringValue: String {
        switch self {
        case .firstName(let value):
            return value
        case .lastName(let value):
            return value
        case .displayName(let value):
            return value
        case .aboutMe(let value):
            return value
        case .email(let value):
            return value
        case .emailRevertPendingChange:
            return String(false)
        case .primarySite(let value):
            return String(value)
        case .webAddress(let value):
            return value
        case .language(let value):
            return value
        }
    }
}

typealias AccountSettingsChangeWithString = (String) -> AccountSettingsChange
typealias AccountSettingsChangeWithInt = (Int) -> AccountSettingsChange
