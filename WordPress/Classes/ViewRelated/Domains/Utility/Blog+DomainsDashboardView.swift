/// Collection of convenience properties used in the Domains Dashboard
extension Blog {
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
            .sorted(by: { $0.domainName > $1.domainName })
            .map { DomainRepresentation(domain: Domain(managedDomain: $0)) }

    }

    var canRegisterDomainWithPaidPlan: Bool {
        (isHostedAtWPcom || isAtomic()) && hasDomainCredit
    }

    var freeDomain: Domain? {
        guard let domainsSet = domains as? Set<ManagedDomain>,
              let freeDomain = (domainsSet.first { $0.domainType == .wpCom }) else {
            return nil
        }
        return Domain(managedDomain: freeDomain)
    }

    var freeSiteAddress: String {
        freeDomain?.domainName ?? ""
    }

    var freeDomainIsPrimary: Bool {
        freeDomain?.isPrimaryDomain ?? false
    }

    var primaryDomain: Domain? {
        guard let domainsSet = domains as? Set<ManagedDomain>,
              let freeDomain = (domainsSet.first { $0.isPrimary == true }) else {
            return nil
        }
        return Domain(managedDomain: freeDomain)
    }

    var primaryDomainAddress: String {
        primaryDomain?.domainName ?? ""
    }
}
