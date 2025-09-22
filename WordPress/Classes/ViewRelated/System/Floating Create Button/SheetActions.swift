import WordPressShared

/// Common Actions used by CreateButtonActionSheet

struct PostAction: ActionSheetItem {
    let handler: () -> Void
    let source: String

    private let action = "create_new_post"

    func makeButton() -> ActionSheetButton {
        return ActionSheetButton(
            title: Strings.post,
            image: UIImage(named: "wpl-posts")?.withRenderingMode(.alwaysTemplate) ?? .init(),
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
        return ActionSheetButton(
            title: Strings.postFromAudio,
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
        return ActionSheetButton(
            title: Strings.page,
            image: UIImage(named: "wpl-pages")?.withRenderingMode(.alwaysTemplate) ?? .init(),
            identifier: "sitePageButton",
            action: {
                WPAnalytics.track(.createSheetActionTapped, properties: ["source": source, "action": action])
                handler()
            })
    }
}

private enum Strings {
    static let post = NSLocalizedString("createSheet.post", value: "Post", comment: "Create Sheet button title")
    static let postFromAudio = NSLocalizedString("createSheet.postFromAudio", value: "Post from Audio", comment: "Create Sheet button title")
    static let page = NSLocalizedString("createSheet.page", value: "Page", comment: "Create Sheet button title")
}
