import Foundation

class PageCoordinator {
    typealias TemplateSelectionCompletion = (String?) -> Void

    static func showLayoutPickerIfNeeded(from controller: UIViewController, forBlog blog: Blog, completion: @escaping TemplateSelectionCompletion) {
        if FeatureFlag.gutenbergModalLayoutPicker.enabled && blog.isGutenbergEnabled {
            showLayoutPicker(from: controller, completion)
        } else {
            completion(nil)
        }
    }

    private static func showLayoutPicker(from controller: UIViewController, _ completion: @escaping TemplateSelectionCompletion) {
        let storyboard = UIStoryboard(name: "LayoutPickerStoryboard", bundle: Bundle.main)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController,
            let rootView = navigationController.topViewController as? GutenbergLayoutPickerViewController  else {
            completion(nil)
            return
        }
        rootView.completion = completion
        navigationController.modalPresentationStyle = .pageSheet
        controller.present(navigationController, animated: true, completion: nil)
    }
}
