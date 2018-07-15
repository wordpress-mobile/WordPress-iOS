import UIKit

extension RegisterDomainDetailsViewController {
    enum Localized {
        enum PrivacySection {
            static let title = NSLocalizedString(
                "Privacy Protection",
                comment: "Register Domain - Privacy Protection section header title"
            )
            static let description = NSLocalizedString(
                "Domain owners have to share contact information in a public database of all domains. With Privacy Protection, we publish our own informations instead of yours and privately forward any comminucation to you",
                comment: "Register Domain - Privacy Protection section header description"
            )
            static let registerPrivatelyRowText = NSLocalizedString(
                "Register Privately with Privacy Protection",
                comment: "Register Domain - Register Privately with Privacy Protection option title"
            )
            static let registerPubliclyRowText = NSLocalizedString(
                "Register publicly",
                comment: "Register Domain - Register publicly option title"
            )
        }
    }
}
