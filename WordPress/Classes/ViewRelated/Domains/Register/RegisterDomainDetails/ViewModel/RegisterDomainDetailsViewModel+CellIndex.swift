import Foundation

extension RegisterDomainDetailsViewModel {

    enum CellIndex {

        enum PrivacyProtection: Int {
            case privately
            case publicly

            var jsonKey: String {
                return "privacyProtection"
            }
        }

        enum ContactInformation: Int {
            case firstName
            case lastName
            case organization
            case email
            case country

            var indexPath: IndexPath {
                return IndexPath(row: rawValue,
                                 section: SectionIndex.contactInformation.rawValue)
            }

            var keyboardType: UIKeyboardType {
                switch self {
                case .email:
                    return .emailAddress
                default:
                    return UIKeyboardType.default
                }
            }
        }

        enum PhoneNumber: Int {
            case countryCode
            case number

            var indexPath: IndexPath {
                return IndexPath(row: rawValue,
                                 section: SectionIndex.phone.rawValue)
            }
        }

        enum AddressField {
            case addressLine1
            case addressLine2
            case addNewAddressLine
            case city
            case state
            case postalCode
        }

        struct AddressSectionIndexHelper {
            var addressLine1: Int {
                return 0
            }
            private(set) var extraAddressLineCount = 0
            var isAddNewAddressVisible = false

            mutating func addNewAddressField() {
                extraAddressLineCount += 1
            }

            private var totalExtra: Int {
                return isAddNewAddressVisible ? extraAddressLineCount + 1 : extraAddressLineCount
            }
            var addNewAddressIndex: Int {
                return totalExtra
            }
            var cityIndex: Int {
                return 1 + totalExtra
            }
            var stateIndex: Int {
                return 2 + totalExtra
            }
            var postalCodeIndex: Int {
                return 3 + totalExtra
            }

            func addressField(for index: Int) -> AddressField {
                if isAddNewAddressVisible && index == totalExtra {
                    return .addNewAddressLine
                }
                if cityIndex == index {
                    return .city
                } else if stateIndex == index {
                    return .state
                } else if postalCodeIndex == index {
                    return .postalCode
                } else if addressLine1 == index {
                    return .addressLine1
                }
                return .addressLine2
            }
        }
    }
}
