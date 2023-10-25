import Foundation

struct AllDomainsListItemViewModel {

    let name: String
    let description: String?
    let status: Status?
    let expiryDate: String?
}

// MARK: - Convenience Inits

extension AllDomainsListItemViewModel {

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
            expiryDate: Self.expiryDate(from: domain)
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
}

// MARK: - Types

extension AllDomainsListItemViewModel {

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
<<<<<<<< HEAD:WordPress/Classes/ViewRelated/Me/All Domains/View Models/AllDomainsListItemViewModel.swift
========

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
>>>>>>>> 91edbe6f29 (Replace all occurences of My Domains to All Domains):WordPress/Classes/ViewRelated/Me/All Domains/AllDomainsListItemViewModel.swift
