import UIKit
import ImagePlayground

extension MediaPickerMenu {
    static var isImagePlaygroundAvailable: Bool {
        guard #available(iOS 18.1, *) else {
            return false
        }
        return ImagePlaygroundViewController.isAvailable
    }

    static var imagePlaygroundLocalizedTitle: String {
        Strings.imagePlayground
    }

    func makeImagePlaygroundAction(delegate: ImagePlaygroundPickerDelegate) -> UIAction? {
        guard MediaPickerMenu.isImagePlaygroundAvailable else {
            return nil
        }
        return UIAction(
            title: Strings.imagePlayground,
            image: UIImage(systemName: "apple.image.playground"),
            attributes: [],
            handler: { _ in showImagePlayground(delegate: delegate) }
        )
    }

    func showImagePlayground(delegate: ImagePlaygroundPickerDelegate) {
        guard let presentingViewController else { return }

        guard #available(iOS 18.1, *) else {
            return wpAssertionFailure("Not available on this platform. Use `isImagePlaygroundAvailable`.")
        }

        let controller = _ImagePlaygroundController()
        controller.delegate = delegate

        let imagePlaygroundVC = ImagePlaygroundViewController()
        imagePlaygroundVC.delegate = controller
        objc_setAssociatedObject(imagePlaygroundVC, &MediaPickerMenu.strongDelegateKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        presentingViewController.present(imagePlaygroundVC, animated: true)
    }

    /// ImagePlayground returns heic images that are not supported by many WordPress
    /// sites. The only exporter that currently supports transcoding images is
    /// ``ItemProviderMediaExporter``, which is why we use it and which is why
    /// we fallback to "public.heic" (should never happen as these URLs have
    /// proper extensions).
    static func makeItemProvider(with imageURL: URL) -> NSItemProvider {
        let provider = NSItemProvider()
        let typeIdentifier = imageURL.typeIdentifier ?? "public.heic"
        provider.registerFileRepresentation(forTypeIdentifier: typeIdentifier, visibility: .all) { completion in
            completion(imageURL, false, nil)
            return nil
        }
        return provider
    }

    private static var strongDelegateKey: UInt8 = 0
}

// Uses the following workaround https://mastodon.social/@_inside/113640137011009924
// to make it compatible with a mixed Objective-C and Swift target.
private final class _ImagePlaygroundController: NSObject {
    weak var delegate: ImagePlaygroundPickerDelegate?
}

@available(iOS 18.1, *)
extension _ImagePlaygroundController: ImagePlaygroundViewController.Delegate {
    func imagePlaygroundViewController(_ imagePlaygroundViewController: ImagePlaygroundViewController, didCreateImageAt imageURL: URL) {
        delegate?.imagePlaygroundViewController(imagePlaygroundViewController, didCreateImageAt: imageURL)
    }

    func imagePlaygroundViewControllerDidCancel(_ imagePlaygroundViewController: ImagePlaygroundViewController) {
        delegate?.imagePlaygroundViewControllerDidCancel(imagePlaygroundViewController)
    }
}

protocol ImagePlaygroundPickerDelegate: AnyObject {
    func imagePlaygroundViewController(_ viewController: UIViewController, didCreateImageAt imageURL: URL)
    func imagePlaygroundViewControllerDidCancel(_ viewController: UIViewController)
}

extension ImagePlaygroundPickerDelegate {
    func imagePlaygroundViewControllerDidCancel(_ viewController: UIViewController) {
        viewController.presentingViewController?.dismiss(animated: true)
    }
}

private enum Strings {
    static let imagePlayground = NSLocalizedString("mediaPicker.imagePlayground", value: "Image Playground", comment: "A name of the action in the context menu")
}
