import UIKit
import WordPressFlux
import WordPressShared
import SwiftUI
import SVProgressHUD
import Gridicons
import PhotosUI

extension SitePickerViewController {

    func makeSiteIconMenu() -> UIMenu? {
        return UIMenu(children: [
            UIDeferredMenuElement.uncached { [weak self] in
                $0(self?.makeUpdateSiteIconActions() ?? [])
            }
        ])
    }

    func didShowSiteIconMenu() {
        if QuickStartTourGuide.shared.isCurrentElement(.siteIcon) {
            // There is no good way to determine when `UIMenu` is cancelled,
            // so we wait until nothing is presented by the site picker.
            NoticesDispatch.lock()
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if self.presentedViewController == nil {
                    NoticesDispatch.unlock()
                    self.showNoticeAsNeeded()
                    timer.invalidate()
                }
            }
        }
        QuickStartTourGuide.shared.visited(.siteIcon)
    }

    private func makeUpdateSiteIconActions() -> [UIAction] {
        guard siteIconShouldAllowDroppedImages() else {
            return [] // Not eligible to change the icon
        }

        let presenter = makeSiteIconPresenter()
        let mediaMenu = MediaPickerMenu(viewController: self, filter: .images)
        var actions: [UIAction] = []
        if FeatureFlag.nativePhotoPicker.enabled {
            actions += [
                mediaMenu.makePhotosAction(delegate: presenter),
                mediaMenu.makeCameraAction(delegate: presenter),
                mediaMenu.makeMediaAction(blog: blog, delegate: presenter)
            ]
        } else {
            actions.append(UIAction(
                title: SiteIconAlertStrings.Actions.changeSiteIcon,
                image: UIImage(systemName: "photo.on.rectangle"),
                handler: { [weak self] _ in
                    guard let self else { return }
                    presenter.presentPickerFrom(self)
                }
            ))
        }
        if FeatureFlag.siteIconCreator.enabled {
            actions.append(UIAction(
                title: SiteIconAlertStrings.Actions.createWithEmoji,
                image: UIImage(systemName: "face.smiling"),
                handler: { [weak self] _ in self?.showEmojiPicker() }
            ))
        }
        if blog.hasIcon {
            actions.append(UIAction(
                title: SiteIconAlertStrings.Actions.removeSiteIcon,
                image: UIImage(systemName: "trash"),
                attributes: [.destructive],
                handler: { [weak self] _ in self?.removeSiteIcon() }
            ))
        }
        return actions
    }

    private func makeSiteIconPresenter() -> SiteIconPickerPresenter {
        let presenter = SiteIconPickerPresenter(blog: blog)
        presenter.onCompletion = { [ weak self] media, error in
            if error != nil {
                self?.showErrorForSiteIconUpdate()
            } else if let media = media {
                self?.updateBlogIconWithMedia(media)
            } else {
                // If no media and no error the picker was canceled
                self?.dismiss(animated: true)
            }

            self?.siteIconPickerPresenter = nil
            self?.startAlertTimer()
        }
        presenter.onIconSelection = { [weak self] in
            self?.blogDetailHeaderView.updatingIcon = true
            self?.dismiss(animated: true)
        }
        self.siteIconPickerPresenter = presenter
        return presenter
    }

    func showEmojiPicker() {
        var pickerView = SiteIconPickerView()

        pickerView.onCompletion = { [weak self] image in
            self?.dismiss(animated: true, completion: nil)
            self?.blogDetailHeaderView.updatingIcon = true
            self?.uploadDroppedSiteIcon(image, completion: {})
        }

        pickerView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }

        let controller = UIHostingController(rootView: pickerView)
        present(controller, animated: true)
    }

    func removeSiteIcon() {
        blogDetailHeaderView.updatingIcon = true
        blog.settings?.iconMediaID = NSNumber(value: 0)
        updateBlogSettingsAndRefreshIcon()
        WPAnalytics.track(.siteSettingsSiteIconRemoved)
    }

    func showErrorForSiteIconUpdate() {
        SVProgressHUD.showDismissibleError(withStatus: SiteIconAlertStrings.Errors.iconUpdateFailed)
        blogDetailHeaderView.updatingIcon = false
    }

    func updateBlogIconWithMedia(_ media: Media) {
        QuickStartTourGuide.shared.completeSiteIconTour(forBlog: blog)
        blog.settings?.iconMediaID = media.mediaID
        updateBlogSettingsAndRefreshIcon()
    }

    func updateBlogSettingsAndRefreshIcon() {
        blogService.updateSettings(for: blog, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.blogService.syncBlog(self.blog, success: {
                self.blogDetailHeaderView.updatingIcon = false
                self.blogDetailHeaderView.refreshIconImage()
            }, failure: { _ in })

        }, failure: { [weak self] error in
            self?.showErrorForSiteIconUpdate()
        })
    }

    func uploadDroppedSiteIcon(_ image: UIImage, completion: @escaping (() -> Void)) {
        let service = MediaImportService(coreDataStack: ContextManager.shared)
        _ = service.createMedia(
            with: image,
            blog: blog,
            post: nil,
            receiveUpdate: nil,
            thumbnailCallback: nil,
            completion: {  [weak self] media, error in
                guard let media = media, error == nil else {
                    return
                }

                var uploadProgress: Progress?
                self?.mediaService.uploadMedia(
                    media,
                    automatedRetry: false,
                    progress: &uploadProgress,
                    success: {
                        self?.updateBlogIconWithMedia(media)
                        completion()
                    }, failure: { error in
                        self?.showErrorForSiteIconUpdate()
                        completion()
                    })
            })
    }

    func presentCropViewControllerForDroppedSiteIcon(_ image: UIImage?) {
        guard let image = image else {
            return
        }

        let imageCropController = ImageCropViewController(image: image)
        imageCropController.maskShape = .square
        imageCropController.shouldShowCancelButton = true

        imageCropController.onCancel = { [weak self] in
            self?.dismiss(animated: true)
            self?.blogDetailHeaderView.updatingIcon = false
        }

        imageCropController.onCompletion = { [weak self] image, modified in
            self?.dismiss(animated: true)
            self?.uploadDroppedSiteIcon(image, completion: {
                self?.blogDetailHeaderView.blavatarImageView.image = image
                self?.blogDetailHeaderView.updatingIcon = false
            })
        }

        let navigationController = UINavigationController(rootViewController: imageCropController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
}

extension SitePickerViewController {

    private enum SiteIconAlertStrings {

        static let title = NSLocalizedString("Update Site Icon", comment: "Title for sheet displayed allowing user to update their site icon")

        enum Actions {
            static let changeSiteIcon = NSLocalizedString("Change Site Icon", comment: "Change site icon button")
            static let chooseImage = NSLocalizedString("Choose Image From My Device", comment: "Button allowing the user to choose an image from their device to use as their site icon")
            static let createWithEmoji = NSLocalizedString("Create With Emoji", comment: "Button allowing the user to create a site icon by choosing an emoji character")
            static let removeSiteIcon = NSLocalizedString("Remove Site Icon", comment: "Remove site icon button")
            static let cancel = NSLocalizedString("Cancel", comment: "Cancel button")
        }

        enum Errors {
            static let iconUpdateFailed = NSLocalizedString("Icon update failed", comment: "Message to show when site icon update failed")
        }
    }
}
