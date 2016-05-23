import Foundation
import CoreData

@objc enum DomainType: Int16 {
    case Registered
    case Mapped
    case SiteRedirect
    case WPCom

    var description: String {
        switch self {
        case .Registered:
            return NSLocalizedString("Registered Domain", comment: "Describes a domain that was registered with WordPress.com")
        case .Mapped:
            return NSLocalizedString("Mapped Domain", comment: "Describes a domain that was mapped to WordPress.com, but registered elsewhere")
        case .SiteRedirect:
            return NSLocalizedString("Site Redirect", comment: "Describes a site redirect domain")
        case .WPCom:
            return NSLocalizedString("Included with Site", comment: "Describes a standard *.wordpress.com site domain")
        }
    }
}

struct Domain {
    let domain: String
    let isPrimaryDomain: Bool
    let domainType: DomainType

    static let entityName = "Domain"
}

extension Domain: CustomStringConvertible {
    var description: String {
        return "\(domain) (\(domainType.description))"
    }
}

extension Domain {
    init(managedDomain: ManagedDomain) {
        domain = managedDomain.domain
        isPrimaryDomain = managedDomain.isPrimary
        domainType = managedDomain.domainType
    }
}

class ManagedDomain: NSManagedObject {
    @NSManaged var domain: String
    @NSManaged var isPrimary: Bool
    @NSManaged var domainType: DomainType
    @NSManaged var blog: Blog

    func updateWith(domain: Domain, blog: Blog) {
        self.domain = domain.domain
        self.isPrimary = domain.isPrimaryDomain
        self.domainType = domain.domainType
        self.blog = blog
    }
}

extension Domain: Equatable {}

func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.domain == rhs.domain &&
    lhs.domainType == rhs.domainType &&
    lhs.isPrimaryDomain == rhs.isPrimaryDomain
}
