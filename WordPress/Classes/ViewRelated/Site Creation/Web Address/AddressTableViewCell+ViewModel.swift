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
            case freeWithPaidPlan(cost: String)
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
            comment: "The text to display for free domains in 'Site Creation > Choose a domain' screen"
        )
        static let yearly = NSLocalizedString(
            "domain.suggestions.row.yearly",
            value: "per year",
            comment: "The text to display for paid domains in 'Site Creation > Choose a domain' screen"
        )
        static let firstYear = NSLocalizedString(
            "domain.suggestions.row.first-year",
            value: "for the first year",
            comment: "The text to display for paid domains on sale in 'Site Creation > Choose a domain' screen"
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
        static let freeWithPaidPlan = NSLocalizedString(
            "domain.suggestions.row.free-with-plan",
            value: "Free for a year with a plan",
            comment: "The text to display for paid domains that are free for the first year with the paid plan in 'Site Creation > Choose a domain' screen"
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
            cost = .freeWithPaidPlan(cost: formattedCost)
        } else {
            cost = .freeWithPaidPlan(cost: model.costString)
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

        let formatter = Self.Cache.currencyFormatter ?? {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            return formatter
        }()

        if formatter.currencyCode != code {
            formatter.currencyCode = code
        }

        Self.Cache.currencyFormatter = formatter

        return formatter
    }

    private enum Cache {
        static var currencyFormatter: NumberFormatter?
    }
}
