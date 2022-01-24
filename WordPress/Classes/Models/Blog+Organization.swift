import Foundation

extension Blog {
    var isAutomatticP2: Bool {
        SiteOrganizationType(rawValue: organizationID.intValue) == .automattic
    }
}
