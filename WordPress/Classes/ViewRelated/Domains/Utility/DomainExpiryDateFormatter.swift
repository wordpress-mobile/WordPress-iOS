import Foundation

struct DomainExpiryDateFormatter {
    static func expiryDate(for domain: Domain) -> String {
        if domain.expiryDate.isEmpty {
            return Localized.neverExpires
        } else if domain.expired {
            return Localized.expired
        } else if domain.autoRenewing && domain.autoRenewalDate.isEmpty {
            return Localized.autoRenews
        } else if domain.autoRenewing {
            return String(format: Localized.renewsOn, domain.autoRenewalDate)
        } else {
            return String(format: Localized.expiresOn, domain.expiryDate)
        }
    }

    enum Localized {
        static let neverExpires = NSLocalizedString("Never expires", comment: "Label indicating that a domain name registration has no expiry date.")
        static let autoRenews = NSLocalizedString("Auto-renew enabled", comment: "Label indicating that a domain name registration will automatically renew")
        static let renewsOn = NSLocalizedString("Renews on %@", comment: "Label indicating the date on which a domain name registration will be renewed. The %@ placeholder will be replaced with a date at runtime.")
        static let expiresOn = NSLocalizedString("Expires on %@", comment: "Label indicating the date on which a domain name registration will expire. The %@ placeholder will be replaced with a date at runtime.")
        static let expired = NSLocalizedString("Expired", comment: "Label indicating that a domain name registration has expired.")
    }
}
