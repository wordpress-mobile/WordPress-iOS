import Foundation
import SVProgressHUD
import WordPressShared
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
final class SiteIconPickerPresenter: NSObject {

    // MARK: - Public Properties

    @objc var blog: Blog
    /// Will be invoked with a Media item from the user library or an error
    @objc var onCompletion: ((Media?, Error?) -> Void)?
    @objc var onIconSelection: (() -> Void)?
    @objc var originalMedia: Media?

    // MARK: - Private Properties

    private var dataSource: AnyObject?
    private var mediaCapturePresenter: AnyObject?

    // MARK: - Public methods

    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - blog: The current blog.
    ///
    @objc init(blog: Blog) {
        self.blog = blog
        super.init()
    }

    // MARK: - Private Methods

    fileprivate func showLoadingMessage() {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show(withStatus: NSLocalizedString("Loading...",
                                                         comment: "Text displayed in HUD while a media item is being loaded."))
    }

    fileprivate func showErrorLoadingImageMessage() {
        SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Unable to load the image. Please choose a different one or try again later.",
                                                                         comment: "Text displayed in HUD if there was an error attempting to load a media image."))
    }

    /// Shows a new ImageCropViewController for the given image.
    ///
    func showImageCropViewController(_ image: UIImage, presentingViewController: UIViewController) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.maskShape = .square
            imageCropViewController.onCompletion = { [weak self] image, modified in
                guard let self = self else {
                    return
                }
                self.onIconSelection?()
                if !modified, let media = self.originalMedia {
                    self.onCompletion?(media, nil)
                } else {
                    let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                    let importService = MediaImportService(coreDataStack: ContextManager.sharedInstance())

                    WPAnalytics.track(.siteSettingsSiteIconCropped)

                    importService.createMedia(
                        with: image,
                        blog: self.blog,
                        post: nil,
                        receiveUpdate: nil,
                        thumbnailCallback: nil
                    ) { (media, error) in
                        guard let media = media, error == nil else {
                            WPAnalytics.track(.siteSettingsSiteIconUploadFailed)
                            self.onCompletion?(nil, error)
                            return
                        }
                        var uploadProgress: Progress?
                        mediaService.uploadMedia(media,
                                                 automatedRetry: false,
                                                 progress: &uploadProgress,
                                                 success: {
                            WPAnalytics.track(.siteSettingsSiteIconUploaded)
                            self.onCompletion?(media, nil)
                        }, failure: { (error) in
                            WPAnalytics.track(.siteSettingsSiteIconUploadFailed)
                            self.onCompletion?(nil, error)
                        })
                    }
                }
            }
            imageCropViewController.shouldShowCancelButton = true
            imageCropViewController.onCancel = { [weak presentingViewController] in
                // Dismiss the crop controller but not the picker
                presentingViewController?.dismiss(animated: true)
            }
            let navigationController = UINavigationController(rootViewController: imageCropViewController)
            presentingViewController.present(navigationController, animated: true)
        }
    }
}

extension SiteIconPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.presentingViewController?.dismiss(animated: true)
            return
        }
        WPAnalytics.track(.siteSettingsSiteIconGalleryPicked)
        self.showLoadingMessage()
        self.originalMedia = nil
        PHPickerResult.loadImage(for: result) { [weak self] image, error in
            if let image {
                self?.showImageCropViewController(image, presentingViewController: picker)
            } else {
                DDLogError("Failed to load image: \(String(describing: error))")
                self?.showErrorLoadingImageMessage()
            }
        }
    }
}

extension SiteIconPickerPresenter: ImagePickerControllerDelegate {
    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let presentingViewController = picker.presentingViewController else {
            return
        }
        presentingViewController.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.showImageCropViewController(image, presentingViewController: presentingViewController)
            }
        }
    }
}

extension SiteIconPickerPresenter: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        guard let media = selection.first else {
            onCompletion?(nil, nil)
            return
        }

        WPAnalytics.track(.siteSettingsSiteIconGalleryPicked)

        showLoadingMessage()
        originalMedia = media

        Task { [weak self] in
            do {
                let image = try await MediaImageService.shared.image(for: media, size: .original)
                self?.showImageCropViewController(image, presentingViewController: viewController)
            } catch {
                self?.showErrorLoadingImageMessage()
            }
        }
    }
}
