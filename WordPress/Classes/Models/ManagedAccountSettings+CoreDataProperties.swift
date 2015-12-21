import Foundation
import CoreData

extension ManagedAccountSettings {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var displayName: String
    @NSManaged var aboutMe: String

    @NSManaged var username: String
    @NSManaged var email: String
    @NSManaged var primarySiteID: NSNumber
    @NSManaged var webAddress: String
    @NSManaged var language: String

    @NSManaged var account: WPAccount
}
