import Foundation
import CoreData

class ManagedAccountSettings: NSManagedObject {
    static let entityName = "AccountSettings"

    func updateWith(accountSettings: AccountSettings) {
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
        displayName = accountSettings.displayName
        aboutMe = accountSettings.aboutMe

        username = accountSettings.username
        email = accountSettings.email
        primarySiteID = accountSettings.primarySiteID
        webAddress = accountSettings.webAddress
        language = accountSettings.language
    }

    /**
     Applies a change to the account settings

     To change a setting, you create a change and apply it to the AccountSettings object.
     This method will return a new change object to apply if you want to revert the changes (for instance, if they failed to save)

     - returns: the change object needed to revert this change
     */
    func applyChange(change: AccountSettingsChange) -> AccountSettingsChange {
        let reverse = reverseChange(change)

        switch change {
        case .FirstName(let value):
            self.firstName = value
        case .LastName(let value):
            self.lastName = value
        case .DisplayName(let value):
            self.displayName = value
        case .AboutMe(let value):
            self.aboutMe = value
        case .Email(let value):
            self.email = value
        case .PrimarySite(let value):
            self.primarySiteID = value
        case .WebAddress(let value):
            self.webAddress = value
        case .Language(let value):
            self.language = value
        }

        return reverse
    }

    private func reverseChange(change: AccountSettingsChange) -> AccountSettingsChange {
        switch change {
        case .FirstName(_):
            return .FirstName(self.firstName)
        case .LastName(_):
            return .LastName(self.lastName)
        case .DisplayName(_):
            return .DisplayName(self.displayName)
        case .AboutMe(_):
            return .AboutMe(self.aboutMe)
        case .Email(_):
            return .Email(self.email)
        case .PrimarySite(_):
            return .PrimarySite(self.primarySiteID.integerValue)
        case .WebAddress(_):
            return .WebAddress(self.webAddress)
        case .Language(_):
            return .Language(self.language)
        }
    }
}

enum AccountSettingsChange {
    case FirstName(String)
    case LastName(String)
    case DisplayName(String)
    case AboutMe(String)
    case Email(String)
    case PrimarySite(Int)
    case WebAddress(String)
    case Language(String)

    var stringValue: String {
        switch self {
        case .FirstName(let value):
            return value
        case .LastName(let value):
            return value
        case .DisplayName(let value):
            return value
        case .AboutMe(let value):
            return value
        case .Email(let value):
            return value
        case .PrimarySite(let value):
            return String(value)
        case .WebAddress(let value):
            return value
        case .Language(let value):
            return value
        }
    }
}

typealias AccountSettingsChangeWithString = String -> AccountSettingsChange
typealias AccountSettingsChangeWithInt = Int -> AccountSettingsChange
