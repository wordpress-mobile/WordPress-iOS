
class BadgeContentStyles: FormattableContentStyles {

    let key: String
    let isTitle: Bool

    init(cachingKey: String, isTitle: Bool) {
        key = cachingKey
        self.isTitle = isTitle
    }

    var attributes: [NSAttributedString.Key: Any] {
        if FeatureFlag.milestoneNotifications.enabled && isTitle {
            return WPStyleGuide.Notifications.badgeTitleStyle
        }

        return WPStyleGuide.Notifications.badgeRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        if FeatureFlag.milestoneNotifications.enabled && isTitle {
            return WPStyleGuide.Notifications.badgeTitleBoldStyle
        }

        return WPStyleGuide.Notifications.badgeBoldStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        if FeatureFlag.milestoneNotifications.enabled && isTitle {
            return [
                .user: WPStyleGuide.Notifications.badgeTitleBoldStyle,
                .post: WPStyleGuide.Notifications.badgeTitleItalicsStyle,
                .comment: WPStyleGuide.Notifications.badgeTitleItalicsStyle,
                .blockquote: WPStyleGuide.Notifications.badgeTitleQuotedStyle,
                .site: WPStyleGuide.Notifications.badgeTitleBoldStyle,
                .strong: WPStyleGuide.Notifications.badgeTitleBoldStyle
            ]
        }

        return [
            .user: WPStyleGuide.Notifications.badgeBoldStyle,
            .post: WPStyleGuide.Notifications.badgeItalicsStyle,
            .comment: WPStyleGuide.Notifications.badgeItalicsStyle,
            .blockquote: WPStyleGuide.Notifications.badgeQuotedStyle,
            .site: WPStyleGuide.Notifications.badgeBoldStyle
        ]
    }

    var linksColor: UIColor? {
        return WPStyleGuide.Notifications.badgeLinkColor
    }
}
