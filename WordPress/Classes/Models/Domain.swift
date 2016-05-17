import Foundation
import CoreData

struct Domain {
    let domain: String
    let isPrimaryDomain: Bool

    static let entityName = "Domain"
}

extension Domain: CustomStringConvertible {
    var description: String {
        return domain
    }
}

extension Domain {
    init(managedDomain: ManagedDomain) {
        domain = managedDomain.domain
        isPrimaryDomain = managedDomain.isPrimary
    }
}

class ManagedDomain: NSManagedObject {
    @NSManaged var domain: String
    @NSManaged var isPrimary: Bool
    @NSManaged var blog: Blog

    func updateWith(domain: Domain, blog: Blog) {
        self.domain = domain.domain
        self.isPrimary = domain.isPrimaryDomain
        self.blog = blog
    }
}

extension Domain: Equatable {}

func ==(lhs: Domain, rhs: Domain) -> Bool {
    return lhs.domain == rhs.domain
}
