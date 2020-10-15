
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

        let coordinator = CreateButtonCoordinator(self, newPost: newPost, newPage: newPage, newStory: shouldShowNewStory ? newStory : nil)
        return coordinator
    }

    //TODO: Can be removed after stories launches
    private var shouldShowNewStory: Bool {
        return Feature.enabled(.stories) && blog.supports(.stories)
    }
}
