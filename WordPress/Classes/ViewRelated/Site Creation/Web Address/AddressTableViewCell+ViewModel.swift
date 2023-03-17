import Foundation

extension AddressTableViewCell {

    struct ViewModel {
        let domain: String
        let tags: [Tag]
        let cost: String
        let saleCost: String?

        enum Tag {
            case recommended
            case bestAlternative
            case sale

            var localizedString: String {
                switch self {
                case .recommended: return Strings.recommended
                case .bestAlternative: return Strings.bestAlternative
                case .sale: return Strings.sale
                }
            }
        }
    }
}

extension AddressTableViewCell.ViewModel {

    enum Strings {
        static let recommended = NSLocalizedString(
            "domain.suggestions.row.recommended",
            value: "Recommended",
            comment: "The 'Recommended' label under the domain name in 'Choose a domain' screen"
        )
        static let bestAlternative = NSLocalizedString(
            "domain.suggestions.row.best-alternative",
            value: "Best Alternative",
            comment: "The 'Best Alternative' label under the domain name in 'Choose a domain' screen"
        )
        static let sale = NSLocalizedString(
            "domain.suggestions.row.sale",
            value: "Sale",
            comment: "The 'Sale' label under the domain name in 'Choose a domain' screen"
        )
    }
}

extension AddressTableViewCell.ViewModel {

    init(model: DomainSuggestion, tags: [Tag] = []) {
        // Declare variables
        var tags = tags
        var costString: String = model.costString
        var saleCostString: String?

        // Format cost and sale cost
        if !model.isFree, let currencyCode = model.currencyCode {
            let formatter = Self.currencyFormatter(code: currencyCode)
            if let cost = model.cost, let formattedCost = formatter.string(from: .init(floatLiteral: cost)) {
                costString = formattedCost
            }
            if let saleCost = model.saleCost {
                tags.append(.sale)
                saleCostString = formatter.string(from: .init(floatLiteral: saleCost))
            }
            costString = "\(costString)/year"
            saleCostString = saleCostString.map { "\($0) for the first year" }
        }

        // Initialize instance
        self.init(
            domain: model.domainName,
            tags: tags,
            cost: costString,
            saleCost: saleCostString
        )
    }

    /// Returns a list of tags depending on the row's position in the list.
    /// - Parameter position: The position of the domin suggestion in the list.
    /// - Returns: A list of tags.
    static func tagsFromPosition(_ position: Int) -> [Tag] {
        switch position {
        case 0: return [.recommended]
        case 1: return [.bestAlternative]
        default: return []
        }
    }

    private static func currencyFormatter(code: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.currencyCode = code
        return formatter
    }
}
