import Foundation

class SiteCreationFields {

    // MARK: - Properties

    var title = ""
    var tagline: String?
    var theme: Theme?
    var domain = ""

    private static var privateShared: SiteCreationFields?

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

}
