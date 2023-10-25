import Foundation

struct AllDomainsListItemViewModel {

    let name: String
    let description: String?
    let status: Status?
    let expiryDate: String?

    private enum Strings {
        static let expired = NSLocalizedString(
            "domain.management.card.expired.label",
            value: "Expired",
            comment: "The expired label of the domain card in My Domains screen."
        )
        static let renews = NSLocalizedString(
            "domain.management.card.renews.label",
            value: "Renews",
            comment: "The renews label of the domain card in My Domains screen."
        )
    }

    typealias Domain = DomainsService.AllDomainsListItem
    typealias Status = Domain.Status
    typealias StatusType = DomainsService.AllDomainsListItem.StatusType
}

extension AllDomainsListItemViewModel {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(domain: Domain) {
        let description: String? = {
            guard !domain.isDomainOnlySite else {
                return nil
            }
            return !domain.blogName.isEmpty ? domain.blogName : domain.siteSlug
        }()
        let expiryDate: String? = { () -> String? in
            guard let date = domain.expiryDate, domain.hasRegistration else {
                return nil
            }
            let expired = date < Date()
            let notice = expired ? Strings.expired : Strings.renews
            let formatted = Self.dateFormatter.string(from: date)
            return "\(notice) \(formatted)"
        }()
        self.init(
            name: domain.domain,
            description: description,
            status: domain.status,
            expiryDate: expiryDate
        )
    }
}
