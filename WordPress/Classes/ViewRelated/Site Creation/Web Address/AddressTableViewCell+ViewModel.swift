import Foundation

extension AddressTableViewCell {

    struct ViewModel {
        let domain: String
        let tags: [Tag]
        let cost: String
        let saleCost: String?
    }

    enum Tag {
        case recommended
        case bestAlternative
        case sale

        var localizedString: String {
            switch self {
            case .recommended: return "Recommended"
            case .bestAlternative: return "Best Alternative"
            case .sale: return "Sale"
            }
        }
    }
}
