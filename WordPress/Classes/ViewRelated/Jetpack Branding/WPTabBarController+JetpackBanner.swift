
extension WPTabBarController {

    /// Encapsulates a `UIViewController` instance inside a `JetpackBannerContainerViewController`
    /// - Parameter contentController: the `UIViewController` instance to be encapsulated
    /// - Returns: the newly created instance of `JetpackBannerContainerViewController`
    @objc func makeJetpackContainerViewController(contentController: UIViewController) -> UIViewController {
        let controller = JetpackBannerContainerViewController(contentController: contentController)
        return controller
    }
}
