
/// Encapsulates logic related to Blogging Prompts in WPTabBarController.
///
extension WPTabBarController {

    @objc func makeBloggingPromptCoordinator() -> BloggingPromptCoordinator {
        return BloggingPromptCoordinator()
    }

    @objc func renewPromptRemindersIfNeeded() {
        guard let blog = currentOrLastBlog() else {
            return
        }

        bloggingPromptCoordinator.renewPromptRemindersIfNeeded(for: blog)
    }

    func showPromptAnsweringFlow(siteID: Int, promptID: Int?, source: BloggingPromptCoordinator.Source) {
        guard Feature.enabled(.bloggingPrompts),
              let blog = accountSites?.first(where: { $0.dotComID == NSNumber(value: siteID) }),
              let viewController = viewControllers?[selectedIndex] else {
            return
        }

        bloggingPromptCoordinator.showPromptAnsweringFlow(from: viewController, promptID: promptID, blog: blog, source: source)
    }

}

private extension WPTabBarController {

    var accountSites: [Blog]? {
        AccountService(managedObjectContext: ContextManager.shared.mainContext).defaultWordPressComAccount()?.visibleBlogs
    }

}
