/// Collection of convenience properties used in the Domains Dashboard
extension Blog {

    static let noPrimaryURLFound = NSLocalizedString("No primary site address found",
                                                     comment: "String to display in place of the site address, in case it was not retrieved from the backend.")

    struct DomainRepresentation: Identifiable {
        let domain: Domain
        let id = UUID()
    }

    var hasDomains: Bool {
        !domainsList.isEmpty
    }

    var domainsList: [DomainRepresentation] {
        guard let domainsSet = domains as? Set<ManagedDomain> else {
            return []
        }
        return domainsSet
            .filter { $0.domainType != .wpCom }
            .map { DomainRepresentation(domain: Domain(managedDomain: $0)) }

    }

    var canRegisterDomainWithPaidPlan: Bool {
        (isHostedAtWPcom || isAtomic()) && hasDomainCredit
    }

    var siteAddress: String {
        (displayURL as String?) ?? Self.noPrimaryURLFound
    }

    var freeSiteAddress: String {
        (hostname as String?) ?? Self.noPrimaryURLFound
    }

    var primarySiteAddress: String? {
        guard let domainsSet = domains as? Set<ManagedDomain>,
                let primaryDomain = (domainsSet.first { $0.isPrimary }) else {
            return nil
        }
        return Domain(managedDomain: primaryDomain).domainName
    }

    var displayURLIsPrimary: Bool {
        return freeSiteAddress == primarySiteAddress
    }
}
