import UIKit

enum RegisterDomainDetails {
    enum Localized {
        static let validationError = NSLocalizedString(
            "Please enter a valid %@",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let prefillError = NSLocalizedString(
            "Error occurred fetching domain contact information",
            comment: "Register Domain - Domain contact information error message shown to indicate an error during fetching domain contact information"
        )
        static let buttonTitle = NSLocalizedString(
            "Register domain",
            comment: "Register domain - Title for the Register domain button"
        )
        static let unexpectedError = NSLocalizedString(
            "There has been an unexpected error while registering your domain",
            comment: "Register domain - Error message displayed whenever registering domain fails unexpectedly"
        )
        enum PrivacySection {
            static let title = NSLocalizedString(
                "Privacy Protection",
                comment: "Register Domain - Privacy Protection section header title"
            )
            static let description = NSLocalizedString(
                "Domain owners have to share contact information in a public database of all domains. With Privacy Protection, we publish our own information instead of yours and privately forward any communication to you.",
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
            static let termsAndConditions = NSLocalizedString(
                "By registering this domain you agree to our <a>Terms&nbsp;and&nbsp;Conditions</a>.",
                comment: "Terms of Service link displayed when a user is registering domain. Text inside <a> tags will be highlighted."
            )
        }

        enum ContactInformation {
            static let title = NSLocalizedString(
                "Domain contact information",
                comment: "Register Domain - Domain contact information section header title"
            )
            static let description = NSLocalizedString(
                "For your convenience, we have pre-filled your WordPress.com contact information. Please review to be sure it’s the correct information you want to use for this domain.",
                comment: "Register Domain - Domain contact information section header description"
            )
            static let firstName = NSLocalizedString("First Name", comment: "Register Domain - Domain contact information field First name")
            static let lastName = NSLocalizedString("Last Name", comment: "Register Domain - Domain contact information field Last name")
            static let organization = NSLocalizedString("Organization", comment: "Register Domain - Domain contact information field Organization")
            static let organizationPlaceholder = NSLocalizedString("Organization (Optional)", comment: "Register Domain - Domain contact information field placeholder for Organization")
            static let email = NSLocalizedString("Email", comment: "Register Domain - Domain contact information field Email")
            static let phone = NSLocalizedString("Phone", comment: "Register Domain - Domain contact information field Phone")
            static let country = NSLocalizedString("Country", comment: "Register Domain - Domain contact information field Country")
            static let countryPlaceholder = NSLocalizedString("Select Country", comment: "Register Domain - Domain contact information field placeholder for Country")
        }

        enum Address {
            static let headerTitle = NSLocalizedString("ADDRESS", comment: "Register Domain - Address information field section header title")
            static let addressLine = NSLocalizedString("Address line %@", comment: "Register Domain - Address information field Address line")
            static let addNewAddressLine = NSLocalizedString("+ Address line %@", comment: "Register Domain - Address information field add new address line")
            static let addressPlaceholder = NSLocalizedString("Address", comment: "Register Domain - Address information field placeholder for Address line")
            static let city = NSLocalizedString("City", comment: "Register Domain - Address information field City")
            static let postalCode = NSLocalizedString("Postal Code", comment: "Register Domain - Address information field Postal Code")
            static let state = NSLocalizedString("State", comment: "Register Domain - Domain Address field State")
            static let statePlaceHolder = NSLocalizedString("Select State", comment: "Register Domain - Address information field placeholder for State")
        }
    }
}
