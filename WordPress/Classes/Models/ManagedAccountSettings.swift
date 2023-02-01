import Foundation
import CoreData
import WordPressKit

// MARK: - Reflects the user's Account Settings, as stored in Core Data.
//
class ManagedAccountSettings: NSManagedObject {

    // MARK: - NSManagedObject

    override class func entityName() -> String {
        return "AccountSettings"
    }

    func updateWith(_ accountSettings: AccountSettings) {
        firstName = accountSettings.firstName
        lastName = accountSettings.lastName
        displayName = accountSettings.displayName
        aboutMe = accountSettings.aboutMe

        username = accountSettings.username
        usernameCanBeChanged = accountSettings.usernameCanBeChanged
        email = accountSettings.email
        emailPendingAddress = accountSettings.emailPendingAddress
        emailPendingChange = accountSettings.emailPendingChange
        primarySiteID = NSNumber(value: accountSettings.primarySiteID)
        webAddress = accountSettings.webAddress
        language = accountSettings.language
        tracksOptOut = accountSettings.tracksOptOut
        blockEmailNotifications = accountSettings.blockEmailNotifications
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
        case .tracksOptOut(let value):
            self.tracksOptOut = value
        }

        return reverse
    }

    fileprivate func reverseChange(_ change: AccountSettingsChange) -> AccountSettingsChange {
        switch change {
        case .firstName:
            return .firstName(self.firstName)
        case .lastName:
            return .lastName(self.lastName)
        case .displayName:
            return .displayName(self.displayName)
        case .aboutMe:
            return .aboutMe(self.aboutMe)
        case .email:
            return .emailRevertPendingChange
        case .emailRevertPendingChange:
            return .email(self.emailPendingAddress ?? String())
        case .primarySite:
            return .primarySite(self.primarySiteID.intValue)
        case .webAddress:
            return .webAddress(self.webAddress)
        case .language:
            return .language(self.language)
        case .tracksOptOut:
            return .tracksOptOut(self.tracksOptOut)
        }
    }
}

extension AccountSettings {
    init(managed: ManagedAccountSettings) {
        self.init(firstName: managed.firstName.stringByDecodingXMLCharacters(),
                  lastName: managed.lastName.stringByDecodingXMLCharacters(),
                  displayName: managed.displayName.stringByDecodingXMLCharacters(),
                  aboutMe: managed.aboutMe,
                  username: managed.username,
                  usernameCanBeChanged: managed.usernameCanBeChanged,
                  email: managed.email,
                  emailPendingAddress: managed.emailPendingAddress,
                  emailPendingChange: managed.emailPendingChange,
                  primarySiteID: managed.primarySiteID.intValue,
                  webAddress: managed.webAddress,
                  language: managed.language,
                  tracksOptOut: managed.tracksOptOut,
                  blockEmailNotifications: managed.blockEmailNotifications)
    }

    var emailForDisplay: String {
        let pendingEmail = emailPendingAddress?.nonEmptyString() ?? email
        return emailPendingChange ? pendingEmail : email
    }
}
