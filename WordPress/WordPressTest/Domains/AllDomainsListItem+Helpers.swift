import Foundation

@testable import WordPress

extension DomainsService.AllDomainsListItem {

    static func make(
        domain: String = Defaults.domain,
        blogId: Int = Defaults.blogId,
        blogName: String = Defaults.blogName,
        type: String = Defaults.type,
        isDomainOnlySite: Bool = Defaults.isDomainOnlySite,
        isWpcomStagingDomain: Bool = Defaults.isWpcomStagingDomain,
        hasRegistration: Bool = Defaults.hasRegistration,
        registrationDate: String? = Defaults.registrationDate,
        expiryDate: String? = Defaults.expiryDate,
        wpcomDomain: Bool = Defaults.wpcomDomain,
        currentUserIsOwner: Bool? = Defaults.currentUserIsOwner,
        siteSlug: String = Defaults.siteSlug,
        status: DomainStatus = Defaults.status
    ) throws -> Self {
        let json: [String: Any] = [
            "domain": domain,
            "blog_id": blogId,
            "blog_name": blogName,
            "type": type,
            "is_domain_only_site": isDomainOnlySite,
            "is_wpcom_staging_domain": isWpcomStagingDomain,
            "has_registration": hasRegistration,
            "registration_date": registrationDate as Any,
            "expiry": expiryDate as Any,
            "wpcom_domain": wpcomDomain,
            "current_user_is_owner": currentUserIsOwner as Any,
            "site_slug": siteSlug,
            "domain_status": ["status": status.value, "status_type": status.type.rawValue]
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Domain.self, from: data)
    }

    enum Defaults {
        static let domain: String = "example1.com"
        static let blogId: Int = 12345
        static let blogName: String = "Example Blog 1"
        static let type: String = "mapped"
        static let isDomainOnlySite: Bool = false
        static let isWpcomStagingDomain: Bool = false
        static let hasRegistration: Bool = true
        static let registrationDate: String? = "2022-01-01T00:00:00+00:00"
        static let expiryDate: String? = "2023-01-01T00:00:00+00:00"
        static let wpcomDomain: Bool = false
        static let currentUserIsOwner: Bool? = false
        static let siteSlug: String = "exampleblog1.wordpress.com"
        static let status: DomainStatus = .init(value: "Active", type: .success)
    }

    typealias Domain = DomainsService.AllDomainsListItem
    typealias DomainStatus = Domain.Status
}
