import Foundation

/// An enum for returning validation errors.
enum SiteCreationFieldsValidation {
    case missingTitle
    case missingDomain
    case domainContainsWordPressDotCom
    case missingTheme
    case noError
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

    static func validateFields() -> SiteCreationFieldsValidation {

        if SiteCreationFields.sharedInstance.title.isEmpty {
            return .missingTitle
        }

        if SiteCreationFields.sharedInstance.domain.isEmpty {
            return .missingDomain
        }

        if SiteCreationFields.sharedInstance.domain.contains(".wordpress.com") {
            return .domainContainsWordPressDotCom
        }

        if SiteCreationFields.sharedInstance.theme == nil {
            return .missingTheme
        }

        return .noError
    }

}
