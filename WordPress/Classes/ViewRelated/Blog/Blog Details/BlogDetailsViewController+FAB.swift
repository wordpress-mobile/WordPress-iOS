
extension BlogDetailsViewController {

    /// Make a create button coordinator with
    /// - Returns: CreateButtonCoordinator with new post, page, and story actions.
    @objc func makeCreateButtonCoordinator() -> CreateButtonCoordinator {

        let newPage = { [weak self] in
            let controller = self?.tabBarController as? WPTabBarController
            let blog = controller?.currentOrLastBlog()
            controller?.showPageEditor(forBlog: blog)
        }

        let newPost = { [weak self] in
            let controller = self?.tabBarController as? WPTabBarController
            controller?.showPostTab(completion: {
                self?.startAlertTimer()
            })
        }

        let newStory = { [weak self] in
            let controller = self?.tabBarController as? WPTabBarController
            let blog = controller?.currentOrLastBlog()
            controller?.showStoryEditor(forBlog: blog)
        }

        let source = "my_site"

        var actions: [ActionSheetItem] = [PostAction(handler: newPost, source: source), PageAction(handler: newPage, source: source)]
        if shouldShowNewStory {
            actions.append(StoryAction(handler: newStory, source: source))
        }
        let coordinator = CreateButtonCoordinator(self, actions: actions, source: source)
        return coordinator
    }

    //TODO: Can be removed after stories launches
    private var shouldShowNewStory: Bool {
        return Feature.enabled(.stories) && blog.supports(.stories)
    }
}
