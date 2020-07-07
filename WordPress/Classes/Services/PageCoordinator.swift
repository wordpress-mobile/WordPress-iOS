import Foundation

class PageCoordinator {

    static func showLayoutPickerIfNeeded(from controller: UIViewController, forBlog blog: Blog, completion:(()->Void)) {
        if Feature.enabled(.gutenbergModalLayoutPicker) && blog.isGutenbergEnabled {
            showLayoutPicker(from: controller, completion)
        } else {
            completion()
        }
    }

    private static func showLayoutPicker(from controller: UIViewController, _ completion:(()->Void)) {
        let storyboard = UIStoryboard(name: "LayoutPickerStoryboard", bundle: Bundle.main)
        guard let rootView = storyboard.instantiateInitialViewController() else {
            completion()
            return
        }
        rootView.modalPresentationStyle = .pageSheet
        controller.present(rootView, animated: true, completion: nil)
    }
}
