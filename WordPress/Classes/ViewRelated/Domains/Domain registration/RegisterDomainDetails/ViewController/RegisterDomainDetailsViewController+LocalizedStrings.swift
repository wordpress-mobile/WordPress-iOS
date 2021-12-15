import UIKit

enum RegisterDomainDetails {
    enum Localized {
        static let validationErrorFirstName = AppLocalizedString(
            "Please enter a valid First Name",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorLastName = AppLocalizedString(
            "Please enter a valid Last Name",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorOrganization = AppLocalizedString(
            "Please enter a valid Organization",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorEmail = AppLocalizedString(
            "Please enter a valid Email",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorCountry = AppLocalizedString(
            "Please enter a valid Country",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorPhone = AppLocalizedString(
            "Please enter a valid phone number",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorAddress = AppLocalizedString(
            "Please enter a valid address",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorCity = AppLocalizedString(
            "Please enter a valid City",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorState = AppLocalizedString(
            "Please enter a valid State",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let validationErrorPostalCode = AppLocalizedString(
            "Please enter a valid Postal Code",
            comment: "Register Domain - Domain contact information validation error message for an input field"
        )
        static let prefillError = AppLocalizedString(
            "Error occurred fetching domain contact information",
            comment: "Register Domain - Domain contact information error message shown to indicate an error during fetching domain contact information"
        )
        static let redemptionError = AppLocalizedString("Problem purchasing your domain. Please try again.",
             comment: "Register Domain - error displayed when there's a problem when purchasing the domain."
        )
        static let changingPrimaryDomainError = AppLocalizedString("We've had problems changing the primary domain on your site — but don't worry, your domain was successfully purchased.",
                                                                  comment: "Register Domain - error displayed when a domain was purchased succesfully, but there was a problem setting it to a primary domain for the site"
        )


        static let statesFetchingError = AppLocalizedString(
            "Error occurred fetching states",
            comment: "Register Domain - Domain contact information error message shown to indicate an error during fetching list of states"
        )
        static let buttonTitle = AppLocalizedString(
            "Register domain",
            comment: "Register domain - Title for the Register domain button"
        )
        static let unexpectedError = AppLocalizedString(
            "There has been an unexpected error while registering your domain",
            comment: "Register domain - Error message displayed whenever registering domain fails unexpectedly"
        )
        enum PrivacySection {
            static let title = AppLocalizedString(
                "Privacy Protection",
                comment: "Register Domain - Privacy Protection section header title"
            )
            static let description = AppLocalizedString(
                "Domain owners have to share contact information in a public database of all domains. With Privacy Protection, we publish our own information instead of yours and privately forward any communication to you.",
                comment: "Register Domain - Privacy Protection section header description"
            )
            static let registerPrivatelyRowText = AppLocalizedString(
                "Register Privately with Privacy Protection",
                comment: "Register Domain - Register Privately with Privacy Protection option title"
            )
            static let registerPubliclyRowText = AppLocalizedString(
                "Register publicly",
                comment: "Register Domain - Register publicly option title"
            )
            static let termsAndConditions = AppLocalizedString(
                "By registering this domain you agree to our <a>Terms&nbsp;and&nbsp;Conditions</a>.",
                comment: "Terms of Service link displayed when a user is registering domain. Text inside <a> tags will be highlighted."
            )
        }

        enum ContactInformation {
            static let title = AppLocalizedString(
                "Domain contact information",
                comment: "Register Domain - Domain contact information section header title"
            )
            static let description = AppLocalizedString(
                "For your convenience, we have pre-filled your WordPress.com contact information. Please review to be sure it’s the correct information you want to use for this domain.",
                comment: "Register Domain - Domain contact information section header description"
            )
            static let firstName = AppLocalizedString("First Name", comment: "Register Domain - Domain contact information field First name")
            static let lastName = AppLocalizedString("Last Name", comment: "Register Domain - Domain contact information field Last name")
            static let organization = AppLocalizedString("Organization", comment: "Register Domain - Domain contact information field Organization")
            static let organizationPlaceholder = AppLocalizedString("Organization (Optional)", comment: "Register Domain - Domain contact information field placeholder for Organization")
            static let email = AppLocalizedString("Email", comment: "Register Domain - Domain contact information field Email")
            static let phone = AppLocalizedString("phone number", comment: "Register Domain - Domain contact information field Phone")
            static let country = AppLocalizedString("Country", comment: "Register Domain - Domain contact information field Country")
            static let countryPlaceholder = AppLocalizedString("Select Country", comment: "Register Domain - Domain contact information field placeholder for Country")
        }

        enum PhoneNumber {
            static let headerTitle = AppLocalizedString("PHONE", comment: "Register Domain - Phone number section header title")
            static let countryCode = AppLocalizedString("Country Code", comment: "Register Domain - Address information field Country Code")
            static let countryCodePlaceholder = AppLocalizedString("eg. 44", comment: "Register Domain - Address information field Country Code placeholder")
            static let number = AppLocalizedString("Number", comment: "Register Domain - Address information field Number")
            static let numberPlaceholder = AppLocalizedString("eg. 1122334455", comment: "Register Domain - Address information field Number placeholder")
        }

        enum Address {
            static let headerTitle = AppLocalizedString("ADDRESS", comment: "Register Domain - Address information field section header title")
            static let addressLine = AppLocalizedString("Address line %@", comment: "Register Domain - Address information field Address line")
            static let addNewAddressLine = AppLocalizedString("+ Address line %@", comment: "Register Domain - Address information field add new address line")
            static let addressPlaceholder = AppLocalizedString("Address", comment: "Register Domain - Address information field placeholder for Address line")
            static let city = AppLocalizedString("City", comment: "Register Domain - Address information field City")
            static let postalCode = AppLocalizedString("Postal Code", comment: "Register Domain - Address information field Postal Code")
            static let state = AppLocalizedString("State", comment: "Register Domain - Domain Address field State")
            static let statePlaceHolder = AppLocalizedString("Select State", comment: "Register Domain - Address information field placeholder for State")
        }
    }
}
