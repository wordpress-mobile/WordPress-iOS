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
                case .recommended: return "Recommended"
                case .bestAlternative: return "Best Alternative"
                case .sale: return "Sale"
                }
            }
        }
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
