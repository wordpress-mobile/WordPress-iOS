import Foundation

@objc public enum DomainType: Int16 {
    case registered
    case mapped
    case siteRedirect
    case wpCom
    
    public var description: String {
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

public struct RemoteDomain {
    public let domainName: String
    public let isPrimaryDomain: Bool
    public let domainType: DomainType

    public init(domainName: String,
                isPrimaryDomain: Bool,
                domainType: DomainType) {
        self.domainName = domainName
        self.isPrimaryDomain = isPrimaryDomain
        self.domainType = domainType
    }
}

extension RemoteDomain: CustomStringConvertible {
    public var description: String {
        return "\(domainName) (\(domainType.description))"
    }
}
