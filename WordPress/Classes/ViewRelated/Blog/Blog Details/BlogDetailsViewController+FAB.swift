
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

        var actions: [ActionSheetItem] = [PostAction(handler: newPost), PageAction(handler: newPage)]
        if shouldShowNewStory {
            actions.append(StoryAction(handler: newStory))
        }
        let coordinator = CreateButtonCoordinator(self, actions: actions)
        return coordinator
    }

    //TODO: Can be removed after stories launches
    private var shouldShowNewStory: Bool {
        return Feature.enabled(.stories) && blog.supports(.stories)
    }
}
