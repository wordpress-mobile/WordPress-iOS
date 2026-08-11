import Foundation

struct AllDomainsListItemViewModel {

    // MARK: - Types

    private enum Strings {
        static let expired = NSLocalizedString(
            "domain.management.card.expiredDate.label",
            value: "Expired %1$@",
            comment:
                "The expiry line of the domain card in All Domains screen, e.g. 'Expired Jan 1, 2023'. %1$@ is the formatted expiry date."
        )
        static let expiresOn = NSLocalizedString(
            "domain.management.card.expiresOn.label",
            value: "Expires on %1$@",
            comment:
                "The expiry line of the domain card in All Domains screen, e.g. 'Expires on Oct 17, 2027'. %1$@ is the formatted expiry date."
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
        // The API sends `expiry` as a midnight UTC timestamp encoding the
        // registry's expiry date, a calendar date that is UTC by registry
        // convention. Format it in UTC to preserve that date. Formatting in
        // the device timezone would print the previous day west of UTC.
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
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

    static func expiryDate(from domain: Domain) -> String? {
        guard let date = domain.expiryDate else {
            // Only WP.com-provided subdomains (*.wordpress.com and staging
            // addresses) genuinely never expire. For other domains a missing
            // expiry means the date is unknown (registered elsewhere) or
            // doesn't apply (subdomains), so show nothing.
            return (domain.type == .wpCom || domain.isWpcomStagingDomain) ? Strings.neverExpires : nil
        }
        let expired = date < Date()
        let format = expired ? Strings.expired : Strings.expiresOn
        let formatted = Self.dateFormatter.string(from: date)
        return String.localizedStringWithFormat(format, formatted)
    }
}
