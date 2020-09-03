import Foundation

class PageCoordinator {
    typealias TemplateSelectionCompletion = (String?) -> Void

    static func showLayoutPickerIfNeeded(from controller: UIViewController, forBlog blog: Blog, completion: @escaping TemplateSelectionCompletion) {
        if FeatureFlag.gutenbergModalLayoutPicker.enabled && blog.isGutenbergEnabled {
            showLayoutPicker(from: controller, forBlog: blog, completion)
        } else {
            completion(nil)
        }
    }

    private static func showLayoutPicker(from controller: UIViewController, forBlog blog: Blog, _ completion: @escaping TemplateSelectionCompletion) {
        let storyboard = UIStoryboard(name: "LayoutPickerStoryboard", bundle: Bundle.main)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController,
            let rootView = navigationController.topViewController as? GutenbergLayoutPickerViewController  else {
            completion(nil)
            return
        }
        rootView.completion = completion
        rootView.blog = blog

        if #available(iOS 13.0, *) {
            navigationController.modalPresentationStyle = .pageSheet
        } else {
            // Specifically using fullScreen instead of pageSheet to get the desired behavior on Max devices running iOS 12 and below.
             navigationController.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .pageSheet : .fullScreen
        }

        controller.present(navigationController, animated: true, completion: nil)
    }
}
