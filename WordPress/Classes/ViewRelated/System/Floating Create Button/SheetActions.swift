import WordPressShared

/// Common Actions used by CreateButtonActionSheet

struct PostAction: ActionSheetItem {
    let handler: () -> Void
    let source: String

    private let action = "create_new_post"

    func makeButton() -> ActionSheetButton {
        return ActionSheetButton(title: NSLocalizedString("Blog post", comment: "Create new Blog Post button title"),
                                 image: .gridicon(.posts),
                                 identifier: "blogPostButton",
                                 action: {
                                    WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                                    handler()
                                 })
    }
}

struct PostFromAudioAction: ActionSheetItem {
    let handler: () -> Void
    let source: String

    private let action = "create_new_post_from_audio"

    func makeButton() -> ActionSheetButton {
        return ActionSheetButton(title: NSLocalizedString("createFAB.postFromAudio", value: "Post from Audio", comment: "Create new Blog Post from Audio button title"),
                                 image: .gridicon(.microphone),
                                 identifier: "blogPostFromAudioButton",
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
        return ActionSheetButton(title: NSLocalizedString("Site page", comment: "Create new Site Page button title"),
                                            image: .gridicon(.pages),
                                            identifier: "sitePageButton",
                                            action: {
                                                WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                                                handler()
                                            })
    }
}
