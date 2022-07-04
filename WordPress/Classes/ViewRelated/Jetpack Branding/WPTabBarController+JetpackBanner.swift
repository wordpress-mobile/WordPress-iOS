
extension WPTabBarController {

    /// Encapsulates a `UIViewController` instance inside a `JetpackBannerContainerViewController`
    /// - Parameter contentController: the `UIViewController` instance to be encapsulated
    /// - Parameter title: optional title to assign to the container controller
    /// - Returns: the newly created instance of `JetpackBannerContainerViewController`
    @objc func makeJetpackContainerViewController(contentController: UIViewController, title: String? = nil) -> UIViewController {
        let controller = JetpackBannerContainerViewController(contentController: contentController)
        controller.title = title
        return controller
    }
}
