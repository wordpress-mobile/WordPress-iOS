import Foundation
import UIKit
import PhotosUI
import SVProgressHUD

final class AvatarMenuController: PHPickerViewControllerDelegate, ImagePickerControllerDelegate {
    private weak var presentingViewController: UIViewController?

    var onAvatarSelected: ((UIImage) -> Void)?

    init(viewController: UIViewController) {
        self.presentingViewController = viewController
    }

    func makeMenu() -> UIMenu {
        guard let presentingViewController else {
            assertionFailure("Presenting view controller missing")
            return UIMenu()
        }
        let mediaPickerMenu = MediaPickerMenu(viewController: presentingViewController, filter: .images)
        return UIMenu(title: Strings.menuTitle, children: [
            mediaPickerMenu.makePhotosAction(delegate: self),
            mediaPickerMenu.makeCameraAction(camera: .front, delegate: self)
        ])
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        presentingViewController?.dismiss(animated: true)

        guard let result = results.first else {
            return
        }
        PHPickerResult.loadImage(for: result) { [weak self] image, _ in
            if let image {
                self?.showCropViewController(with: image)
            } else {
                self?.showError()
            }
        }
    }

    // MARK: - ImagePickerControllerDelegate

    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        presentingViewController?.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.showCropViewController(with: image)
            }
        }
    }

    // MARK: - Helpers

    private func showCropViewController(with image: UIImage) {
        guard let topViewController else {
            return
        }
        let cropViewController = ImageCropViewController(image: image)
        cropViewController.shouldShowCancelButton = true
        cropViewController.onCancel = { [weak topViewController] in
            topViewController?.dismiss(animated: true)
        }
        cropViewController.onCompletion = { [weak self] image, _ in
            self?.didComplete(with: image)
        }
        let navigationController = UINavigationController(rootViewController: cropViewController)
        topViewController.present(navigationController, animated: true)
    }

    private func didComplete(with avatar: UIImage?) {
        presentingViewController?.dismiss(animated: true) {
            if let avatar {
                self.onAvatarSelected?(avatar)
            }
        }
    }

    private func showError() {
        SVProgressHUD.showDismissibleError(withStatus: Strings.errorTitle)
    }

    private func dismiss() {
        presentingViewController?.dismiss(animated: true)
    }

    private var topViewController: UIViewController? {
        presentingViewController?.topmostPresentedViewController
    }
}

private enum Strings {
    static let errorTitle = NSLocalizedString("avatarMenu.failedToSetAvatarAlertMessage", value: "Unable to load the image. Please choose a different one or try again later.", comment: "Alert message when something goes wrong with the selected image.")
    static let menuTitle = NSLocalizedString("avatarMenu.title", value: "Update Gravatar", comment: "Title for menu that is shown when you tap your gravatar")
}
