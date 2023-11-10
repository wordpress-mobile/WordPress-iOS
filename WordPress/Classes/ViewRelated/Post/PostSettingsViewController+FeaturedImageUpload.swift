import Foundation
import Photos
import PhotosUI
import WordPressFlux
import WPMediaPicker

// MARK: - PostSettingsViewController (Featured Image Menu)

extension PostSettingsViewController: PHPickerViewControllerDelegate, ImagePickerControllerDelegate {
    @objc func makeSetFeaturedImageCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let button = UIButton()
        var configuration = UIButton.Configuration.plain()
        configuration.title = Strings.buttonSetFeaturedImage
        configuration.baseForegroundColor = UIColor.primary
        button.configuration = configuration
        button.menu = makeSetFeaturedImageMenu()
        button.showsMenuAsPrimaryAction = true

        cell.contentView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.pinSubviewToAllEdges(button)

        cell.accessibilityIdentifier = "SetFeaturedImage"
        return cell
    }

    private func makeSetFeaturedImageMenu() -> UIMenu {
        let menu = MediaPickerMenu(viewController: self, filter: .images)
        return UIMenu(children: [
            menu.makePhotosAction(delegate: self),
            menu.makeCameraAction(delegate: self),
            menu.makeSiteMediaAction(blog: self.apost.blog, delegate: self)
        ])
    }

    // MARK: PHPickerViewControllerDelegate

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        self.dismiss(animated: true) {
            if let result = results.first {
                self.setFeaturedImage(with: result.itemProvider)
            }
        }
    }

    func imagePicker(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        self.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.setFeaturedImage(with: image)
            }
        }
    }
}

extension PostSettingsViewController: MediaPickerViewControllerDelegate {
    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        guard !assets.isEmpty else { return }

        WPAnalytics.track(.editorPostFeaturedImageChanged, properties: ["via": "settings", "action": "added"])

        if let media = assets.first as? Media {
            setFeaturedImage(media: media)
        }

        dismiss(animated: true)
        reloadFeaturedImageCell()
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        dismiss(animated: true)
    }
}

extension PostSettingsViewController: SiteMediaPickerViewControllerDelegate {
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media]) {
        dismiss(animated: true)

        guard let media = selection.first else { return }

        WPAnalytics.track(.editorPostFeaturedImageChanged, properties: ["via": "settings", "action": "added"])
        setFeaturedImage(media: media)
        reloadFeaturedImageCell()
    }
}

// MARK: - PostSettingsViewController (Featured Image Upload)

extension PostSettingsViewController {
    func setFeaturedImage(with asset: ExportableAsset) {
        guard let media = MediaCoordinator.shared.addMedia(from: asset, to: apost) else {
            return
        }
        self.apost.featuredImage = media
        self.setupObservingOf(media: media)
    }

    @objc func setFeaturedImage(media: Media) {
        apost.featuredImage = media
        if !media.hasRemote {
            MediaCoordinator.shared.retryMedia(media)
            setupObservingOf(media: media)
        }

        if let mediaIdentifier = apost.featuredImage?.mediaID {
            featuredImageDelegate?.gutenbergDidRequestFeaturedImageId(mediaIdentifier)
        }
    }

    @objc func removeMediaObserver() {
        if let receipt = mediaObserverReceipt {
            MediaCoordinator.shared.removeObserver(withUUID: receipt)
            mediaObserverReceipt = nil
        }
    }

    @objc func setupObservingOf(media: Media) {
        removeMediaObserver()
        isUploadingMedia = true
        mediaObserverReceipt = MediaCoordinator.shared.addObserver({ [weak self](media, state) in
            self?.mediaObserver(media: media, state: state)
        })
        let progress = MediaCoordinator.shared.progress(for: media)
        if let url = media.absoluteThumbnailLocalURL, let data = try? Data(contentsOf: url) {
            progress?.setUserInfoObject(UIImage(data: data), forKey: .WPProgressImageThumbnailKey)
        }
        featuredImageProgress = progress
    }

    func mediaObserver(media: Media, state: MediaCoordinator.MediaState) {
        switch state {
        case .processing:
            featuredImageProgress?.localizedDescription = NSLocalizedString("Preparing...", comment: "Label to show while converting and/or resizing media to send to server")
        case .thumbnailReady:
            if let url = media.absoluteThumbnailLocalURL, let data = try? Data(contentsOf: url) {
                featuredImageProgress?.setUserInfoObject(UIImage(data: data), forKey: .WPProgressImageThumbnailKey)
            }
        case .uploading(let progress):
            featuredImageProgress = progress
            featuredImageProgress?.kind = .file
            featuredImageProgress?.setUserInfoObject(Progress.FileOperationKind.copying, forKey: ProgressUserInfoKey.fileOperationKindKey)
            featuredImageProgress?.localizedDescription = NSLocalizedString("Uploading...", comment: "Label to show while uploading media to server")
            progressCell?.setProgress(progress)
            tableView.reloadData()
        case .ended:
            isUploadingMedia = false
            tableView.reloadData()
        case .failed(let error):
            DDLogError("Couldn't upload the featured image: \(error.localizedDescription)")
            isUploadingMedia = false
            tableView.reloadData()
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                apost.featuredImage = nil
                apost.removeMediaObject(media)
                break
            }

            let errorTitle = NSLocalizedString("Couldn't upload the featured image", comment: "The title for an alert that says to the user that the featured image he selected couldn't be uploaded.")
            let notice = Notice(title: errorTitle, message: error.localizedDescription)

            ActionDispatcher.dispatch(NoticeAction.clearWithTag(MediaProgressCoordinatorNoticeViewModel.uploadErrorNoticeTag))
            // The Media coordinator shows its own notice about a failed upload. We have a better, more explanatory message for users here
            // so we want to supress the one coming from the coordinator and show ours.
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        case .progress:
            break
        }
    }

    @objc func showFeaturedImageRemoveOrRetryAction(atIndexPath indexPath: IndexPath) {
        guard let media = apost.featuredImage else {
            return
        }

        let alertController = UIAlertController(title: FeaturedImageActionSheet.title, message: nil, preferredStyle: .actionSheet)
        alertController.addActionWithTitle(FeaturedImageActionSheet.dismissActionTitle,
                                           style: .cancel,
                                           handler: nil)

        alertController.addActionWithTitle(FeaturedImageActionSheet.retryUploadActionTitle,
                                           style: .default,
                                           handler: { (action) in
            self.setFeaturedImage(media: media)
        })

        alertController.addActionWithTitle(FeaturedImageActionSheet.removeActionTitle,
                                           style: .destructive,
                                           handler: { (action) in
            self.apost.featuredImage = nil
            self.apost.removeMediaObject(media)
        })
        if let error = media.error {
            alertController.message = error.localizedDescription
        }
        if let anchorView = self.tableView.cellForRow(at: indexPath) ?? self.view {
            alertController.popoverPresentationController?.sourceView = anchorView
            alertController.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: anchorView.bounds.midX, y: anchorView.bounds.midY), size: CGSize(width: 1, height: 1))
            alertController.popoverPresentationController?.permittedArrowDirections = .any
        }
        present(alertController, animated: true)
    }

    struct FeaturedImageActionSheet {
        static let title = NSLocalizedString(
            "postSettings.featuredImageUploadActionSheet.title",
            value: "Featured Image Options",
            comment: "Title for action sheet with featured media options."
        )
        static let dismissActionTitle = NSLocalizedString(
            "postSettings.featuredImageUploadActionSheet.dismiss",
            value: "Dismiss",
            comment: "User action to dismiss featured media options."
        )
        static let retryUploadActionTitle = NSLocalizedString(
            "postSettings.featuredImageUploadActionSheet.retryUpload",
            value: "Retry",
            comment: "User action to retry featured media upload."
        )
        static let removeActionTitle = NSLocalizedString(
            "postSettings.featuredImageUploadActionSheet.remove",
            value: "Remove",
            comment: "User action to remove featured media."
        )
    }
}

private enum Strings {
    static let buttonSetFeaturedImage = NSLocalizedString("postSettings.setFeaturedImageButton", value: "Set Featured Image", comment: "Button in Post Settings")
}
