import Foundation

/// Represents a support area/category that users can select when submitting a support request
public struct SupportFormArea: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?

    public init(id: String, title: String, description: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
    }
}

// MARK: - String Literal Support
extension SupportFormArea: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.id = value.lowercased().replacingOccurrences(of: " ", with: "_")
        self.title = value
        self.description = nil
    }
}

// MARK: - Common Areas
public extension SupportFormArea {
    static let application = SupportFormArea(id: "application", title: "Application", description: "Issues with the app functionality")
    static let jetpackConnection = SupportFormArea(id: "jetpack_connection", title: "Jetpack Connection", description: "Problems connecting to Jetpack")
    static let siteManagement = SupportFormArea(id: "site_management", title: "Site Management", description: "Issues managing your site")
    static let billing = SupportFormArea(id: "billing", title: "Billing & Subscriptions", description: "Payment and subscription issues")
    static let technical = SupportFormArea(id: "technical", title: "Technical Issues", description: "Bugs, crashes, and technical problems")
    static let other = SupportFormArea(id: "other", title: "Other", description: "Something else not covered above")
}
