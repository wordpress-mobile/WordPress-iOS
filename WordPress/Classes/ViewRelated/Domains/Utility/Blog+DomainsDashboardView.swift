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
}
