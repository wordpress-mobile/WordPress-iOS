extension UINavigationController {
    func previousViewController() -> UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[viewControllers.count - 2]
    }

}
