import Foundation

extension SiteVisibility {
    static func eligiblePickerValues(for blog: Blog) -> [SettingsPickerValue<SiteVisibility>] {
        eligibleValues(for: blog).map {
            SettingsPickerValue(title: $0.localizedTitle, id: $0, hint: $0.localizedHint)
        }
    }

    static func eligibleValues(for blog: Blog) -> [SiteVisibility] {
        var values: [SiteVisibility] = [.public, .hidden]
        if blog.supports(.private) {
            values.append(.private)
        }
        return values
    }

    var localizedTitle: String {
        switch self {
        case .private:
            return NSLocalizedString("siteVisibility.private.title", value: "Private", comment: "Text for privacy settings: Private")
        case .hidden:
            return NSLocalizedString("siteVisibility.hidden.title", value: "Hidden", comment: "Text for privacy settings: Hidden")
        case .public:
            return NSLocalizedString("siteVisibility.public.title", value: "Public", comment: "Text for privacy settings: Public")
        case .unknown:
            return NSLocalizedString("siteVisibility.unknown.title", value: "Unknown", comment: "Text for unknown privacy setting")
        @unknown default:
            return NSLocalizedString("siteVisibility.unknown.title", value: "Unknown", comment: "Text for unknown privacy setting")
        }
    }

    var localizedHint: String {
        switch self {
        case .private:
            return NSLocalizedString("siteVisibility.private.hint", value: "Your site is only visible to you and users you approve.", comment: "Hint for users when private privacy setting is set")
        case .hidden:
            return NSLocalizedString("siteVisibility.hidden.hint", value: "Your site is hidden from visitors behind a \"Coming Soon\" notice until it is ready for viewing.", comment: "Hint for users when hidden privacy setting is set")
        case .public:
            return NSLocalizedString("siteVisibility.public.hint", value: "Your site is visible to everyone, and it may be indexed by search engines.", comment: "Hint for users when public privacy setting is set")
        case .unknown:
            return NSLocalizedString("siteVisibility.unknown.hint", value: "Unknown", comment: "Text for unknown privacy setting")
        @unknown default:
            return NSLocalizedString("siteVisibility.unknown.hint", value: "Unknown", comment: "Text for unknown privacy setting")
        }
    }
}
