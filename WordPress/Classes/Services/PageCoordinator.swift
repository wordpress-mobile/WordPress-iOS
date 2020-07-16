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

        let font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold)
        let tintColor = UIColor(light: .black, dark: .white)

        navigationController.navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.font: font.withSize(34),
            NSAttributedString.Key.foregroundColor: tintColor
        ]

        navigationController.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: font.withSize(17),
            NSAttributedString.Key.foregroundColor: tintColor
        ]

        navigationController.modalPresentationStyle = .pageSheet
        controller.present(navigationController, animated: true, completion: nil)
    }
}
