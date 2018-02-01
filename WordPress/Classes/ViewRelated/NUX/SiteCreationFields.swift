import Foundation

/// Singleton class to contain options selected by the user
/// during the Site Creation process.
///
class SiteCreationFields {

    // MARK: - Properties

    static var sharedInstance: SiteCreationFields = SiteCreationFields()

    var title = ""
    var tagline: String?
    var theme: Theme?
    var domain = ""

    /// An enum for returning validation error messages.
    private enum SiteCreationFieldsError: String {
        case missingTitle
        case missingDomain
        case domainContainsWordPressDotCom
        case missingTheme

        var description: String {
            switch self {
            case .missingTitle:
                return NSLocalizedString("The Site Title is missing.", comment: "Error shown during site creation process when the site title is missing.")
            case .missingDomain:
                return NSLocalizedString("The Site Domain is missing.", comment: "Error shown during site creation process when the site domain is missing.")
            case .domainContainsWordPressDotCom:
                return NSLocalizedString("The Site Domain contains wordpress.com.", comment: "Error shown during site creation process when the site domain contains wordpress.com.")
            case .missingTheme:
                return NSLocalizedString("The Site Theme is missing.", comment: "Error shown during site creation process when the site theme is missing.")
            }
        }
    }

    // MARK: - Instance Methods

    static func resetSharedInstance() {
        sharedInstance = SiteCreationFields()
    }

    static func validateFields() -> String? {

        SiteCreationFields.sharedInstance.title = ""
        if SiteCreationFields.sharedInstance.title.isEmpty {
            return SiteCreationFieldsError.missingTitle.description
        }

        if SiteCreationFields.sharedInstance.domain.isEmpty {
            return SiteCreationFieldsError.missingDomain.description
        }

        if SiteCreationFields.sharedInstance.domain.contains(".wordpress.com") {
            return SiteCreationFieldsError.domainContainsWordPressDotCom.description
        }

        if SiteCreationFields.sharedInstance.theme == nil {
            return SiteCreationFieldsError.missingTheme.description
        }

        return nil
    }

}
