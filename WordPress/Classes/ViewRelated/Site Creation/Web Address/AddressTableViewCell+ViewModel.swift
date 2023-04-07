import Foundation

extension AddressTableViewCell {

    struct ViewModel {
        let domain: String
        let tags: [Tag]
        let cost: Cost

        enum Cost {
            case free
            case regular(cost: String)
            case onSale(cost: String, sale: String)
        }

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
        static let free = NSLocalizedString(
            "domain.suggestions.row.free",
            value: "Free",
            comment: ""
        )
        static let yearly = NSLocalizedString(
            "domain.suggestions.row.yearly",
            value: "per year",
            comment: ""
        )
        static let firstYear = NSLocalizedString(
            "domain.suggestions.row.first-year",
            value: "for the first year",
            comment: ""
        )
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
        let cost: Cost

        // Format cost and sale cost
        if model.isFree {
            cost = .free
        } else if let formatter = Self.currencyFormatter(code: model.currencyCode),
                  let costValue = model.cost,
                  let formattedCost = formatter.string(from: .init(value: costValue)) {
            if let saleCost = model.saleCost, let formattedSaleCost = formatter.string(from: .init(value: saleCost)) {
                cost = .onSale(cost: formattedCost, sale: formattedSaleCost)
            } else {
                cost = .regular(cost: formattedCost)
            }
        } else {
            cost = .regular(cost: model.costString)
        }

        // Configure tags
        if case .onSale = cost {
            tags.append(.sale)
        }

        // Initialize instance
        self.init(
            domain: model.domainName,
            tags: tags,
            cost: cost
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

    private static func currencyFormatter(code: String?) -> NumberFormatter? {
        guard let code else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.currencyCode = code
        return formatter
    }
}
