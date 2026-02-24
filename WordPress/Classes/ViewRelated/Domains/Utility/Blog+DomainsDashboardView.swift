import WordPressData
import WordPressKit

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
        (self.domains ?? [])
            .filter { $0.domainType != .wpCom }
            .sorted(by: { $0.domainName > $1.domainName })
            .map { DomainRepresentation(domain: Domain(managedDomain: $0)) }

    }

    var canRegisterDomainWithPaidPlan: Bool {
        (isHostedAtWPcom || isAtomic) && hasDomainCredit
    }

    var freeDomain: Domain? {
        guard let freeDomain = self.domains?.first(where: { $0.domainType == .wpCom }) else {
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
        guard let freeDomain = self.domains?.first(where: { $0.isPrimary }) else {
            return nil
        }
        return Domain(managedDomain: freeDomain)
    }

    var primaryDomainAddress: String {
        primaryDomain?.domainName ?? ""
    }
}
