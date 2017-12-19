import Foundation
import CoreData
import WordPressKit

public typealias Domain = RemoteDomain

extension Domain {
    init(managedDomain: ManagedDomain) {
        domainName = managedDomain.domainName
        isPrimaryDomain = managedDomain.isPrimary
        domainType = managedDomain.domainType
    }
}

class ManagedDomain: NSManagedObject {

    // MARK: - NSManagedObject

    override class func entityName() -> String {
        return "Domain"
    }

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

public func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.domainName == rhs.domainName &&
        lhs.domainType == rhs.domainType &&
        lhs.isPrimaryDomain == rhs.isPrimaryDomain
}
