import Foundation

/// An enum for returning validation errors.
enum SiteCreationFieldsError {
    case missingTitle
    case missingDomain
    case domainContainsWordPressDotCom
    case missingTheme
}

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

    // MARK: - Instance Methods

    static func resetSharedInstance() {
        sharedInstance = SiteCreationFields()
    }

    static func validateFields() -> SiteCreationFieldsError? {

        if SiteCreationFields.sharedInstance.title.isEmpty {
            return SiteCreationFieldsError.missingTitle
        }

        if SiteCreationFields.sharedInstance.domain.isEmpty {
            return SiteCreationFieldsError.missingDomain
        }

        if SiteCreationFields.sharedInstance.domain.contains(".wordpress.com") {
            return SiteCreationFieldsError.domainContainsWordPressDotCom
        }

        if SiteCreationFields.sharedInstance.theme == nil {
            return SiteCreationFieldsError.missingTheme
        }

        return nil
    }

}
