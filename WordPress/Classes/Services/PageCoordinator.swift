import Foundation

class PageCoordinator {
    typealias TemplateSelectionCompletion = (_ layout: PageTemplateLayout?) -> Void

    static func showLayoutPickerIfNeeded(from controller: UIViewController, forBlog blog: Blog, completion: @escaping TemplateSelectionCompletion) {
        if blog.isGutenbergEnabled {
            showLayoutPicker(from: controller, forBlog: blog, completion)
        } else {
            completion(nil)
        }
    }

    private static func showLayoutPicker(from controller: UIViewController, forBlog blog: Blog, _ completion: @escaping TemplateSelectionCompletion) {
        let rootViewController = GutenbergLayoutPickerViewController(blog: blog, completion: completion)
        let navigationController = GutenbergLightNavigationController(rootViewController: rootViewController)
        navigationController.modalPresentationStyle = .pageSheet

        controller.present(navigationController, animated: true, completion: nil)
    }
}
