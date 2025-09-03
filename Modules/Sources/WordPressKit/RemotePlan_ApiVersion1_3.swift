import Foundation

/// This is for getPlansForSite service in api version v1.3.
/// There are some huge differences between v1.3 and v1.2 so a new
/// class is created for v1.3.
@objc public class RemotePlan_ApiVersion1_3: NSObject, Codable {
    public var autoRenew: Bool?
    public var freeTrial: Bool?
    public var interval: Int?
    public var rawDiscount: Double?
    public var rawPrice: Double?
    public var hasDomainCredit: Bool?
    public var currentPlan: Bool?
    public var userIsOwner: Bool?
    public var isDomainUpgrade: Bool?
    @objc public var autoRenewDate: Date?
    @objc public var currencyCode: String?
    @objc public var discountReason: String?
    @objc public var expiry: Date?
    @objc public var formattedDiscount: String?
    @objc public var formattedOriginalPrice: String?
    @objc public var formattedPrice: String?
    @objc public var planID: String?
    @objc public var productName: String?
    @objc public var productSlug: String?
    @objc public var subscribedDate: Date?
    @objc public var userFacingExpiry: Date?

    @objc public var isAutoRenew: Bool {
        return autoRenew ?? false
    }

    @objc public var isCurrentPlan: Bool {
        return currentPlan ?? false
    }

    @objc public var isFreeTrial: Bool {
        return freeTrial ?? false
    }

    @objc public var doesHaveDomainCredit: Bool {
        return hasDomainCredit ?? false
    }
}
