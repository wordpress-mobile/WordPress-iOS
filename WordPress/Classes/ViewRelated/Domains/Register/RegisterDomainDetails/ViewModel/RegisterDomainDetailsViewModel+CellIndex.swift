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
            case phone
            case country

            var indexPath: IndexPath {
                return IndexPath(row: rawValue,
                                 section: SectionIndex.contactInformation.rawValue)
            }

            var keyboardType: UIKeyboardType {
                switch self {
                case .email:
                    return .emailAddress
                case .phone:
                    return .phonePad
                default:
                    return UIKeyboardType.default
                }
            }
        }

        enum AddressField {
            case addressLine
            case addNewAddressLine
            case city
            case state
            case postalCode
        }

        struct AddressSectionIndexHelper {
            static let addressLine = 0
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
                }
                return .addressLine
            }
        }
    }
}
