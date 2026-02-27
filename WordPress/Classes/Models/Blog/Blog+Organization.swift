import Foundation
import WordPressData

extension Blog {
    var isAutomatticP2: Bool {
        guard let organizationID = organizationID?.intValue else {
            return nil
        }
        return SiteOrganizationType(rawValue: organizationID) == .automattic
    }
}
