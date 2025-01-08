import UIKit

extension MediaPickerMenu {
    /// Returns an action for selecting media from the media uploaded by the user
    /// to their site.
    func makeSiteMediaAction(blog: Blog, delegate: SiteMediaPickerViewControllerDelegate) -> UIAction {
        UIAction(
            title: Strings.pickFromMedia,
            image: UIImage(systemName: "photo.stack"),
            attributes: [],
            handler: { _ in showSiteMediaPicker(blog: blog, delegate: delegate) }
        )
    }

    func showSiteMediaPicker(blog: Blog, delegate: SiteMediaPickerViewControllerDelegate) {
        let viewController = SiteMediaPickerViewController(
            blog: blog,
            filter: filter.map { [$0.mediaType] },
            allowsMultipleSelection: isMultipleSelectionEnabled,
            initialSelection: initialSelection
        )
        viewController.delegate = delegate
        let navigation = UINavigationController(rootViewController: viewController)
        presentingViewController?.present(navigation, animated: true)
    }
}

private enum Strings {
    static let pickFromMedia = NSLocalizedString("mediaPicker.pickFromMediaLibrary", value: "Choose from Media", comment: "The name of the action in the context menu (user's WordPress Media Library")
}
