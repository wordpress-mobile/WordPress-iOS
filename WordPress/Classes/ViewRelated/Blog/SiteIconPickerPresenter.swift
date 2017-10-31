import Foundation
import SVProgressHUD
import WPMediaPicker
import WordPressShared


/// Encapsulates the interactions required to capture a new site icon image, crop it and resize it.
///
class SiteIconPickerPresenter: NSObject {

    /// MARK: - Public Properties

    var blog: Blog
    /// Will be invoked with a Media item from the user library or an error
    var onCompletion: ((Media?, Error?) -> Void)?
    var onIconSelection: (() -> Void)?
    var originalMedia: Media?

    /// MARK: - Private Properties

    /// Media Library Data Source
    ///
    fileprivate lazy var mediaLibraryDataSource: WPAndDeviceMediaLibraryDataSource = {
        return WPAndDeviceMediaLibraryDataSource(blog: self.blog)
    }()

    /// Media Picker View Controller
    ///
    fileprivate lazy var mediaPickerViewController: WPNavigationMediaPickerViewController = {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.allowMultipleSelection = false

        let pickerViewController = WPNavigationMediaPickerViewController(options: options)

        pickerViewController.dataSource = self.mediaLibraryDataSource
        pickerViewController.delegate = self
        pickerViewController.modalPresentationStyle = .formSheet

        return pickerViewController
    }()

    /// MARK: - Public methods

    /// Designated Initializer
    ///
    /// - Parameters:
    ///     - blog: The current blog.
    ///
    init(blog: Blog) {
        self.blog = blog
        super.init()
    }

    /// Presents a new WPMediaPickerViewController instance.
    ///
    func presentPickerFrom(_ viewController: UIViewController) {
        viewController.present(mediaPickerViewController, animated: true)
    }

    /// MARK: - Private Methods

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
    fileprivate func showImageCropViewController(_ image: UIImage) {
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            let imageCropViewController = ImageCropViewController(image: image)
            imageCropViewController.maskShape = .square
            imageCropViewController.onCompletion = { [weak self] image, modified in
                self?.onIconSelection?()
                if !modified, let media = self?.originalMedia {
                    self?.onCompletion?(media, nil)
                } else {
                    let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
                    guard let blogId = self?.blog.objectID else {
                        self?.onCompletion?(nil, nil)
                        return
                    }
                    mediaService.createMedia(with: image,
                                             forBlogObjectID: blogId,
                                             thumbnailCallback: nil,
                                             completion: { (media, error) in
                        guard let media = media, error == nil else {
                            self?.onCompletion?(nil, error)
                            return
                        }
                        var uploadProgress: Progress?
                        mediaService.uploadMedia(media,
                                                 progress: &uploadProgress,
                                                 success: {
                            self?.onCompletion?(media, nil)
                        }, failure: { (error) in
                            self?.onCompletion?(nil, error)
                        })
                    })
                }
            }
            self.mediaPickerViewController.show(after: imageCropViewController)
        }
    }
}

extension SiteIconPickerPresenter: WPMediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion?(nil, nil)
    }

    /// Retrieves the chosen image and triggers the ImageCropViewController display.
    ///
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        if assets.isEmpty {
            return
        }

        let asset = assets.first
        switch asset {
        case let phAsset as PHAsset:
            showLoadingMessage()
            originalMedia = nil
            phAsset.exportMaximumSizeImage { [weak self] (image, info) in
                guard let image = image else {
                    self?.showErrorLoadingImageMessage()
                    return
                }
                self?.showImageCropViewController(image)
            }
        case let media as Media:
            showLoadingMessage()
            originalMedia = media
            let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
            mediaService.thumbnailImage(for: media,
                                        preferredSize: CGSize.zero,
                                        completion: { [weak self] (image, error) in
                                            guard let image = image else {
                                                self?.showErrorLoadingImageMessage()
                                                return
                                            }
                                            self?.showImageCropViewController(image)
            })
        default:
            break
        }
    }
}
