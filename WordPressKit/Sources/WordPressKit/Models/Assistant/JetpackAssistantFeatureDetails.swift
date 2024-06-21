import Foundation

public final class JetpackAssistantFeatureDetails: Codable {
    public let hasFeature: Bool
    /// Returns `true` if you are out of limit for the current plan.
    public let isOverLimit: Bool
    /// The all-time request count.
    public let requestsCount: Int
    /// The request limit for a free plan.
    public let requestsLimit: Int
    /// Contains data about the user plan.
    public let currentTier: Tier?
    public let usagePeriod: UsagePeriod?
    public let isSiteUpdateRequired: Bool?
    public let upgradeType: String?
    public let upgradeURL: String?
    public let nextTier: Tier?
    public let tierPlans: [Tier]?
    public let tierPlansEnabled: Bool?
    public let costs: Costs?

    public struct Tier: Codable {
        public let slug: String?
        public let limit: Int
        public let value: Int
        public let readableLimit: String?

        enum CodingKeys: String, CodingKey {
            case slug, limit, value
            case readableLimit = "readable-limit"
        }
    }

    public struct UsagePeriod: Codable {
        public let currentStart: String?
        public let nextStart: String?
        public let requestsCount: Int

        enum CodingKeys: String, CodingKey {
            case currentStart = "current-start"
            case nextStart = "next-start"
            case requestsCount = "requests-count"
        }
    }

    public struct Costs: Codable {
        public let jetpackAILogoGenerator: JetpackAILogoGenerator
        public let featuredPostImage: FeaturedPostImage

        enum CodingKeys: String, CodingKey {
            case jetpackAILogoGenerator = "jetpack-ai-logo-generator"
            case featuredPostImage = "featured-post-image"
        }
    }

    public struct FeaturedPostImage: Codable {
        public let image: Int
    }

    public struct JetpackAILogoGenerator: Codable {
        public let logo: Int
    }

    enum CodingKeys: String, CodingKey {
        case hasFeature = "has-feature"
        case isOverLimit = "is-over-limit"
        case requestsCount = "requests-count"
        case requestsLimit = "requests-limit"
        case usagePeriod = "usage-period"
        case isSiteUpdateRequired = "site-require-upgrade"
        case upgradeURL = "upgrade-url"
        case upgradeType = "upgrade-type"
        case currentTier = "current-tier"
        case nextTier = "next-tier"
        case tierPlans = "tier-plans"
        case tierPlansEnabled = "tier-plans-enabled"
        case costs
    }
}
