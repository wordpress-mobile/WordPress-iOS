import Foundation

class SiteCreationFields {

    // MARK: - Properties

    private static var privateShared: SiteCreationFields?

    var title = ""
    var tagline: String?
    var theme: Theme?
    var domain = ""

    /// An enum for returning validation Errors.
    private enum SiteCreationFieldsError: Error {
        case missingTitle
        case missingDomain
        case domainContainsWordPressDotCom
        case missingTheme
    }

    // MARK: - Init

    private init() {
    }

    // MARK: - Instance Methods

    static func sharedInstance() -> SiteCreationFields {
        if privateShared == nil {
            privateShared = SiteCreationFields()
        }
        return privateShared!
    }

    static func resetFields() {
        privateShared = nil
    }

    static func validateFields() -> Error? {

        if SiteCreationFields.sharedInstance().title.isEmpty {
            return SiteCreationFieldsError.missingTitle
        }

        if SiteCreationFields.sharedInstance().domain.isEmpty {
            return SiteCreationFieldsError.missingDomain
        }

        if SiteCreationFields.sharedInstance().domain.contains(".wordpress.com") {
            return SiteCreationFieldsError.domainContainsWordPressDotCom
        }

        if SiteCreationFields.sharedInstance().theme == nil {
            return SiteCreationFieldsError.missingTheme
        }

        return nil
    }

}
