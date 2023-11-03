import Foundation

struct AllDomainsListItemViewModel {

    let name: String
    let description: String?
    let status: Status?
    let expiryDate: String?
    let wpcomDetailsURL: URL?
}

// MARK: - Convenience Inits

extension AllDomainsListItemViewModel {

    private static let domainManagementBasePath = "https://wordpress.com/domains/manage/all"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(domain: Domain) {
        self.init(
            name: domain.domain,
            description: Self.description(from: domain),
            status: domain.status,
            expiryDate: Self.expiryDate(from: domain),
            wpcomDetailsURL: Self.wpcomDetailsURL(from: domain)
        )
    }

    private static func description(from domain: Domain) -> String? {
        guard !domain.isDomainOnlySite else {
            return nil
        }
        return !domain.blogName.isEmpty ? domain.blogName : domain.siteSlug
    }

    private static func expiryDate(from domain: Domain) -> String? {
        guard let date = domain.expiryDate, domain.hasRegistration else {
            return nil
        }
        let expired = date < Date()
        let notice = expired ? Strings.expired : Strings.renews
        let formatted = Self.dateFormatter.string(from: date)
        return "\(notice) \(formatted)"
    }

    private static func wpcomDetailsURL(from domain: Domain) -> URL? {
        let viewSlug = {
            switch domain.type {
            case .siteRedirect: return "redirect"
            case .transfer: return "/transfer/in"
            default: return "edit"
            }
        }()

        let url = "\(Self.domainManagementBasePath)/\(domain.domain)/\(viewSlug)/\(domain.siteSlug)"

        if let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: url)
        } else {
            return nil
        }
    }
}

// MARK: - Types

extension AllDomainsListItemViewModel {

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
    }

    typealias Domain = DomainsService.AllDomainsListItem
    typealias Status = Domain.Status
    typealias StatusType = DomainsService.AllDomainsListItem.StatusType
}
