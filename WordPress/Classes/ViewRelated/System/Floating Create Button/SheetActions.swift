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
}
