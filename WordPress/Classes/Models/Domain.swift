import Foundation
import CoreData

@objc enum DomainType: Int16 {
    case registered
    case mapped
    case siteRedirect
    case wpCom

    var description: String {
        switch self {
        case .registered:
            return NSLocalizedString("Registered Domain", comment: "Describes a domain that was registered with WordPress.com")
        case .mapped:
            return NSLocalizedString("Mapped Domain", comment: "Describes a domain that was mapped to WordPress.com, but registered elsewhere")
        case .siteRedirect:
            return NSLocalizedString("Site Redirect", comment: "Describes a site redirect domain")
        case .wpCom:
            return NSLocalizedString("Included with Site", comment: "Describes a standard *.wordpress.com site domain")
        }
    }
}

struct Domain {
    let domainName: String
    let isPrimaryDomain: Bool
    let domainType: DomainType
}

extension Domain: CustomStringConvertible {
    var description: String {
        return "\(domainName) (\(domainType.description))"
    }
}

extension Domain {
    init(managedDomain: ManagedDomain) {
        domainName = managedDomain.domainName
        isPrimaryDomain = managedDomain.isPrimary
        domainType = managedDomain.domainType
    }
}

class ManagedDomain: NSManagedObject {

    struct Attributes {
        static let domainName = "domainName"
        static let isPrimary = "isPrimary"
        static let domainType = "domainType"
    }

    struct Relationships {
        static let blog = "blog"
    }

    @NSManaged var domainName: String
    @NSManaged var isPrimary: Bool
    @NSManaged var domainType: DomainType
    @NSManaged var blog: Blog

    func updateWith(_ domain: Domain, blog: Blog) {
        self.domainName = domain.domainName
        self.isPrimary = domain.isPrimaryDomain
        self.domainType = domain.domainType
        self.blog = blog
    }
}

extension Domain: Equatable {}

func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.domainName == rhs.domainName &&
    lhs.domainType == rhs.domainType &&
    lhs.isPrimaryDomain == rhs.isPrimaryDomain
}
