import Foundation
import CoreData

// MARK: - Encapsulates all of the ManagedAccountSettings Core Data properties.
//
extension ManagedAccountSettings {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var displayName: String
    @NSManaged var aboutMe: String

    @NSManaged var username: String
    @NSManaged var usernameCanBeChanged: Bool
    @NSManaged var email: String
    @NSManaged var emailPendingAddress: String?
    @NSManaged var emailPendingChange: Bool
    @NSManaged var primarySiteID: NSNumber
    @NSManaged var webAddress: String
    @NSManaged var language: String
    @NSManaged var tracksOptOut: Bool
    @NSManaged var blockEmailNotifications: Bool

    @NSManaged var account: WPAccount
}
