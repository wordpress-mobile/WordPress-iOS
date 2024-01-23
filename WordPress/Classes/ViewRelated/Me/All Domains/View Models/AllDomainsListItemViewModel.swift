import Foundation

struct AllDomainsListItemViewModel {

    // MARK: - Types

    private enum Strings {
        static let expired = NSLocalizedString(
            "domain.management.card.expired.label",
            value: "Expired",
            comment: "The expired label of the domain card in All Domains screen."
        )
        static let renews = NSLocalizedString(
            "domain.management.card.renews.label",
            value: "Renews",
            comment: "The renews label of the domain card in All Domains screen."
        )

        static let neverExpires = NSLocalizedString(
            "domain.management.card.neverExpires.label",
            value: "Never expires",
            comment: "Label indicating that a domain name registration has no expiry date."
        )
    }

    typealias Row = AllDomainsListCardView.ViewModel
    typealias Domain = DomainsService.AllDomainsListItem
    typealias StatusType = DomainsService.AllDomainsListItem.StatusType

    // MARK: - Properties

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    let domain: Domain
    let row: Row

    // MARK: - Init

    init(domain: Domain) {
        self.domain = domain
        self.row = .init(
            name: domain.domain,
            description: Self.description(from: domain),
            status: domain.status,
            expiryDate: Self.expiryDate(from: domain)
        )
    }

    // MARK: - Helpers

    static func description(from domain: Domain) -> String? {
        guard !domain.isDomainOnlySite else {
            return nil
        }
        return !domain.blogName.isEmpty ? domain.blogName : domain.siteSlug
    }

    static func expiryDate(from domain: Domain) -> String {
        guard let date = domain.expiryDate, domain.hasRegistration else {
            return Strings.neverExpires
        }
        let expired = date < Date()
        let notice = expired ? Strings.expired : Strings.renews
        let formatted = Self.dateFormatter.string(from: date)
        return "\(notice) \(formatted)"
    }
}
