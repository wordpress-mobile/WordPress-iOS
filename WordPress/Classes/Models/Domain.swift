import Foundation
import CoreData
import WordPressKit

public typealias Domain = RemoteDomain

extension Domain {
    init(managedDomain: ManagedDomain) {
        self.init(domainName: managedDomain.domainName,
                  isPrimaryDomain: managedDomain.isPrimary,
                  domainType: managedDomain.domainType,
                  autoRenewing: managedDomain.autoRenewing,
                  autoRenewalDate: managedDomain.autoRenewalDate,
                  expirySoon: managedDomain.expirySoon,
                  expired: managedDomain.expired,
                  expiryDate: managedDomain.expiryDate)
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
        static let autoRenewing = "autoRenewing"
        static let autoRenewalDate = "autoRenewalDate"
        static let expirySoon = "expirySoon"
        static let expired = "expired"
        static let expiryDate = "expiryDate"
    }

    struct Relationships {
        static let blog = "blog"
    }

    @NSManaged var domainName: String
    @NSManaged var isPrimary: Bool
    @NSManaged var domainType: DomainType
    @NSManaged var blog: Blog
    @NSManaged var autoRenewing: Bool
    @NSManaged var autoRenewalDate: String
    @NSManaged var expirySoon: Bool
    @NSManaged var expired: Bool
    @NSManaged var expiryDate: String

    func updateWith(_ domain: Domain, blog: Blog) {
        self.domainName = domain.domainName
        self.isPrimary = domain.isPrimaryDomain
        self.domainType = domain.domainType
        self.blog = blog

        self.autoRenewing = domain.autoRenewing
        self.autoRenewalDate = domain.autoRenewalDate
        self.expirySoon = domain.expirySoon
        self.expired = domain.expired
        self.expiryDate = domain.expiryDate
    }
}

extension Domain: Equatable {}

public func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.domainName == rhs.domainName &&
        lhs.domainType == rhs.domainType &&
        lhs.isPrimaryDomain == rhs.isPrimaryDomain &&
        lhs.autoRenewing == rhs.autoRenewing &&
        lhs.autoRenewalDate == rhs.autoRenewalDate &&
        lhs.expirySoon == rhs.expirySoon &&
        lhs.expired == rhs.expired &&
        lhs.expiryDate == rhs.expiryDate
}
