
/// Encapsulates logic related to Blogging Prompts in RootViewCoordinator.
///
extension RootViewCoordinator {

    @objc func makeBloggingPromptCoordinator() -> BloggingPromptCoordinator {
        return BloggingPromptCoordinator()
    }

    @objc func updatePromptsIfNeeded() {
        guard let blog = Self.sharedPresenter.currentOrLastBlog() else {
            return
        }

        bloggingPromptCoordinator.updatePromptsIfNeeded(for: blog)
    }

    /// Shows prompt answering flow when a prompt notification is tapped.
    ///
    /// - Parameter userInfo: Notification payload.
    func showPromptAnsweringFlow(with userInfo: NSDictionary) {
        guard AppConfiguration.bloggingPromptsEnabled,
              let siteID = userInfo[BloggingPrompt.NotificationKeys.siteID] as? Int,
              let blog = accountSites?.first(where: { $0.dotComID == NSNumber(value: siteID) }),
              let viewController = Self.sharedPresenter.currentViewController else {
            return
        }

        // When the promptID is nil, it's most likely a static prompt notification.
        let promptID = userInfo[BloggingPrompt.NotificationKeys.promptID] as? Int
        let source: BloggingPromptCoordinator.Source = {
            if promptID != nil {
                return .promptNotification
            }
            return .promptStaticNotification
        }()

        bloggingPromptCoordinator.showPromptAnsweringFlow(from: viewController, promptID: promptID, blog: blog, source: source)
    }

}

private extension RootViewCoordinator {

    var accountSites: [Blog]? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.visibleBlogs
    }

    struct Constants {
        static let featureIntroDisplayedUDKey = "wp_intro_shown_blogging_prompts"
    }

}
