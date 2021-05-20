/// Common Actions used by CreateButtonActionSheet

struct PostAction: ActionSheetItem {
    let handler: () -> Void
    let source: String

    private let action = "create_new_post"

    func makeButton() -> ActionSheetButton {
        let highlight: Bool = QuickStartTourGuide.shared.shouldSpotlight(.newpost)
        return ActionSheetButton(title: NSLocalizedString("Blog post", comment: "Create new Blog Post button title"),
                                 image: .gridicon(.posts),
                                 identifier: "blogPostButton",
                                 highlight: highlight,
                                 action: {
                                    WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                                    handler()
                                 })
    }
}

struct PageAction: ActionSheetItem {
    let handler: () -> Void
    let source: String

    private let action = "create_new_page"

    func makeButton() -> ActionSheetButton {
        let highlight: Bool = QuickStartTourGuide.shared.shouldSpotlight(.newPage)
        return ActionSheetButton(title: NSLocalizedString("Site page", comment: "Create new Site Page button title"),
                                            image: .gridicon(.pages),
                                            identifier: "sitePageButton",
                                            highlight: highlight,
                                            action: {
                                                WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                                                handler()
                                            })
    }
}

struct StoryAction: ActionSheetItem {

    private enum Constants {
        enum Badge {
            static let font = UIFont.preferredFont(forTextStyle: .caption1)
            static let insets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
            static let cornerRadius: CGFloat = 2
            static let backgroundColor = UIColor.muriel(color: MurielColor(name: .red, shade: .shade50))
        }
    }

    let handler: () -> Void
    let source: String

    private let action = "create_new_story"

    func makeButton() -> ActionSheetButton {
        return ActionSheetButton(title: NSLocalizedString("Story post", comment: "Create new Story button title"),
                                            image: .gridicon(.story),
                                            identifier: "storyButton",
                                            action: {
                                                WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                                                handler()
                                            })
    }

    static func newBadge(title: String) -> UIButton {
        let badge = UIButton(type: .custom)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.setTitle(title, for: .normal)
        badge.titleLabel?.font = Constants.Badge.font
        badge.contentEdgeInsets = Constants.Badge.insets
        badge.layer.cornerRadius = Constants.Badge.cornerRadius
        badge.isUserInteractionEnabled = false
        badge.backgroundColor = Constants.Badge.backgroundColor
        return badge
    }
}
