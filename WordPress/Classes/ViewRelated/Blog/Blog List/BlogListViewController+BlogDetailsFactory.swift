/// Factory method(s) for BlogDetailsViewController
extension BlogListViewController {
    /// returns an instance of BlogDetailsViewController initialized with a ScenePresenter (concrete) type
    @objc func makeBlogDetailsViewController() -> BlogDetailsViewController {
        return BlogDetailsViewController(meScenePresenter: makeMeScenePresenter())
    }

    func makeMeScenePresenter() -> ScenePresenter {
        return self.meScenePresenter
    }
}
