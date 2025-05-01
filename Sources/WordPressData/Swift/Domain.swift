import Foundation
import CoreData
import WordPressKit

public typealias Domain = RemoteDomain

public extension Domain {
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

public class ManagedDomain: NSManagedObject {

    // MARK: - NSManagedObject

    public override class func entityName() -> String {
        return "Domain"
    }

    public struct Attributes {
        public static let domainName = "domainName"
        static let isPrimary = "isPrimary"
        static let domainType = "domainType"
        static let autoRenewing = "autoRenewing"
        static let autoRenewalDate = "autoRenewalDate"
        static let expirySoon = "expirySoon"
        static let expired = "expired"
        static let expiryDate = "expiryDate"
    }

    public struct Relationships {
        public static let blog = "blog"
    }

    @NSManaged public var domainName: String
    @NSManaged public var isPrimary: Bool
    @NSManaged public var domainType: DomainType
    @NSManaged public var blog: Blog
    @NSManaged public var autoRenewing: Bool
    @NSManaged public var autoRenewalDate: String
    @NSManaged public var expirySoon: Bool
    @NSManaged public var expired: Bool
    @NSManaged public var expiryDate: String

    public func updateWith(_ domain: Domain, blog: Blog) {
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

extension Domain: @retroactive Equatable {}

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
