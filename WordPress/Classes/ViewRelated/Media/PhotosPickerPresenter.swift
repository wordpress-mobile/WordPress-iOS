import Photos
import PhotosUI
import UIKit
import WordPressShared

/// Receives the result of picking media from the device's Photos library.
protocol DevicePhotosPickerDelegate: AnyObject {
    /// - parameter assets: Empty if the user cancelled.
    func devicePhotosPicker(didPick assets: [PhotosPickerAsset])
}

/// Presents a picker for the device's Photos library, choosing the one that works in the
/// current Lockdown Mode state.
///
/// Two pickers, because they answer different questions:
///
/// - **Outside Lockdown Mode**, `PHPickerViewController` runs out-of-process, needs no
///   Photos authorization, and hands back an `NSItemProvider`. That's the best experience
///   and it's what the app has always used.
/// - **Under Lockdown Mode**, the file has to be read through `PHAssetResourceManager`
///   (see `PhotoLibraryFileLoader`), which only works for assets the app can actually
///   resolve. `PHPickerViewController` is the wrong tool for that: even when it's backed
///   by the shared library it displays the *whole* library regardless of what the app has
///   been granted, so under limited authorization it offers items that then can't be read.
///
/// No system picker shows only the granted assets. The legacy `UIImagePickerController`
/// is not an escape hatch: it runs out-of-process too (it presents
/// `_UIImagePickerPlaceholderViewController`, a remote view controller host), and since
/// limited authorization was introduced in iOS 14 it leaves
/// `UIImagePickerController.InfoKey.phAsset` nil whenever access is `.limited` — even for
/// an asset the app *is* allowed to read. So it can only supply an asset under full
/// authorization, which is precisely the case where this picker already works. Scoping a
/// grid to what the app can read would mean building one on `PHAsset.fetchAssets`.
enum PhotosPickerPresenter {
    /// Presents the appropriate picker from `viewController`.
    static func present(
        from viewController: UIViewController,
        filter: MediaPickerMenu.MediaFilter?,
        isMultipleSelectionEnabled: Bool,
        delegate: DevicePhotosPickerDelegate
    ) {
        guard LockdownHelper.isDeviceLockdownModeEnabled else {
            presentSystemPicker(
                from: viewController,
                filter: filter,
                isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                delegate: delegate
            )
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak viewController, weak delegate] status in
            DispatchQueue.main.async {
                guard let viewController, let delegate else { return }
                switch status {
                case .authorized:
                    presentSystemPicker(
                        from: viewController,
                        filter: filter,
                        isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                        delegate: delegate,
                        photoLibrary: .shared()
                    )
                case .limited:
                    // Limited access isn't enough here: the picker shows the whole library
                    // whatever the app has been granted, so letting it open would mostly
                    // offer items that can't then be read. Ask for full access instead.
                    showFullAccessRequiredAlert(from: viewController)
                default:
                    // Without authorization there's no library to read from, so fall back
                    // to the permission-free picker. A file too large to materialize then
                    // surfaces a Lockdown-specific error rather than hanging.
                    presentSystemPicker(
                        from: viewController,
                        filter: filter,
                        isMultipleSelectionEnabled: isMultipleSelectionEnabled,
                        delegate: delegate
                    )
                }
            }
        }
    }

    // MARK: - PHPickerViewController

    private static func presentSystemPicker(
        from viewController: UIViewController,
        filter: MediaPickerMenu.MediaFilter?,
        isMultipleSelectionEnabled: Bool,
        delegate: DevicePhotosPickerDelegate,
        photoLibrary: PHPhotoLibrary? = nil
    ) {
        // Backed by the library only under Lockdown Mode: that's what makes results carry
        // an `assetIdentifier`, which is what `PhotoLibraryFileLoader` needs.
        var configuration = photoLibrary.map(PHPickerConfiguration.init) ?? PHPickerConfiguration()
        configuration.preferredAssetRepresentationMode = .current
        if let filter {
            switch filter {
            case .images: configuration.filter = .images
            case .videos: configuration.filter = .videos
            }
        }
        if isMultipleSelectionEnabled {
            configuration.selectionLimit = 0
            configuration.selection = .ordered
        }
        let picker = PHPickerViewController(configuration: configuration)
        let adapter = SystemPickerAdapter(delegate: delegate)
        picker.delegate = adapter
        retain(adapter, on: picker)
        viewController.present(picker, animated: true)
    }

    private final class SystemPickerAdapter: NSObject, PHPickerViewControllerDelegate {
        private weak var delegate: DevicePhotosPickerDelegate?

        init(delegate: DevicePhotosPickerDelegate) {
            self.delegate = delegate
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.presentingViewController?.dismiss(animated: true)
            delegate?.devicePhotosPicker(didPick: results.map(PhotosPickerAsset.init))
        }
    }

    // MARK: - Limited access

    /// Explains that full access is required under Lockdown Mode and offers to open
    /// Settings. There's no "continue anyway": with limited access the picker would offer
    /// items the app can't read, which is the failure this whole path exists to avoid.
    private static func showFullAccessRequiredAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: Strings.limitedAccessTitle,
            message: Strings.limitedAccessMessage,
            preferredStyle: .alert
        )
        let openSettings = UIAlertAction(title: Strings.openSettings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return wpAssertionFailure("Failed to create the Open Settings URL")
            }
            UIApplication.shared.open(url)
        }
        alert.addAction(openSettings)
        alert.addAction(UIAlertAction(title: SharedStrings.Button.cancel, style: .cancel))
        alert.preferredAction = openSettings
        viewController.present(alert, animated: true)
    }

    // MARK: - Helpers

    /// The picker holds its delegate weakly, so the adapter has to live on the picker.
    private static func retain(_ adapter: NSObject, on picker: UIViewController) {
        objc_setAssociatedObject(picker, &adapterKey, adapter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private nonisolated(unsafe) static var adapterKey: UInt8 = 0
}

private enum Strings {
    static let limitedAccessTitle = NSLocalizedString(
        "mediaPicker.limitedAccess.title",
        value: "Allow Full Access",
        comment: "Title of an alert shown when the app only has access to some photos and needs Full Access"
    )
    static let limitedAccessMessage = NSLocalizedString(
        "mediaPicker.limitedAccess.message",
        value: "While Lockdown Mode is on, adding media requires Full Access enabled. You can change this in Settings.",
        comment: "Message of an alert shown when the app only has access to some photos and needs Full Access. \"Full Access\" matches the option name in the iOS Settings app."
    )
    static let openSettings = NSLocalizedString(
        "mediaPicker.limitedAccess.openSettings",
        value: "Open Settings",
        comment: "Button that opens the Settings app"
    )
}
