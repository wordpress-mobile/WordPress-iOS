import UIKit


/// Contains helper methods to add a UIBarButtonItem
/// to the nav bar, to present the Me scene
extension BlogDetailsViewController {

    func makeAvatarImage() -> UIImage? {
        return UIImage(named: "icon-tab-me")
    }

    func makeMeBarButton() -> UIBarButtonItem {
        guard let image = makeAvatarImage() else {
            /// Fall back to text in case image fails
            return UIBarButtonItem(title: NSLocalizedString("Me",
                                                            comment: "Fallback title for the Me button in Blog Details"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(presentHandler))
        }

        return UIBarButtonItem(image: image,
                               style: .plain,
                               target: self,
                               action: #selector(presentHandler))
    }

    @objc
    func addMeButtonToNavigationBar() {
        navigationItem.rightBarButtonItem = makeMeBarButton()
    }

    @objc
    func presentHandler() {
        scenePresenter.present(on: self)
    }
}
