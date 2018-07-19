import UIKit

extension RegisterDomainDetailsViewController {
    enum Localized {
        enum PrivacySection {
            static let title = NSLocalizedString(
                "Privacy Protection",
                comment: "Register Domain - Privacy Protection section header title"
            )
            static let description = NSLocalizedString(
                "Domain owners have to share contact information in a public database of all domains. With Privacy Protection, we publish our own information instead of yours and privately forward any communication to you",
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

        enum ContactInfo {
            static let title = NSLocalizedString(
                "Domain contact information",
                comment: "Register Domain - Domain contact information section header title"
            )
            static let description = NSLocalizedString(
                "For your convenience, we have pre-filled your WordPress.com contact information. Please review to be sure it’s the correct information you want to use for this domain.",
                comment: "Register Domain - Domain contact information section header description"
            )
            static let firstName = NSLocalizedString("First name", comment: "Register Domain - Domain contact information field First name")
            static let lastName = NSLocalizedString("Last name", comment: "Register Domain - Domain contact information field Last name")
            static let email = NSLocalizedString("Email", comment: "Register Domain - Domain contact information field Email")
            static let phone = NSLocalizedString("Phone", comment: "Register Domain - Domain contact information field Phone")
            static let country = NSLocalizedString("Country", comment: "Register Domain - Domain contact information field Country")
            static let fields: [String] = [firstName,
                                           lastName,
                                           email,
                                           phone,
                                           country]
        }
    }
}
