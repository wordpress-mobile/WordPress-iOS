import Foundation

@objc public enum DomainType: Int16 {
    case registered
    case mapped
    case siteRedirect
    case transfer
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
        case .transfer:
            return NSLocalizedString("Transferred Domain", comment: "Describes a domain that was transferred from elsewhere to wordpress.com")
        }
    }

    init(domainJson: [String: Any]) {
        self.init(
            type: domainJson["domain"] as? String,
            wpComDomain: domainJson["wpcom_domain"] as? Bool,
            hasRegistration: domainJson["has_registration"] as? Bool
        )
    }

    init(type: String?, wpComDomain: Bool?, hasRegistration: Bool?) {
        if type == "redirect" {
            self = .siteRedirect
        } else if type == "transfer" {
            self = .transfer
        } else if wpComDomain == true {
            self = .wpCom
        } else if hasRegistration == true {
            self = .registered
        } else {
            self = .mapped
        }
    }
}

public struct RemoteDomain {
    public let domainName: String
    public let isPrimaryDomain: Bool
    public let domainType: DomainType

    // Renewals / Expiry
    public let autoRenewing: Bool
    public let autoRenewalDate: String
    public let expirySoon: Bool
    public let expired: Bool
    public let expiryDate: String

    public init(domainName: String,
                isPrimaryDomain: Bool,
                domainType: DomainType,
                autoRenewing: Bool? = nil,
                autoRenewalDate: String? = nil,
                expirySoon: Bool? = nil,
                expired: Bool? = nil,
                expiryDate: String? = nil) {
        self.domainName = domainName
        self.isPrimaryDomain = isPrimaryDomain
        self.domainType = domainType
        self.autoRenewing = autoRenewing ?? false
        self.autoRenewalDate = autoRenewalDate ?? ""
        self.expirySoon = expirySoon ?? false
        self.expired = expired ?? false
        self.expiryDate = expiryDate ?? ""
    }
}

extension RemoteDomain: CustomStringConvertible {
    public var description: String {
        return "\(domainName) (\(domainType.description))"
    }
}
